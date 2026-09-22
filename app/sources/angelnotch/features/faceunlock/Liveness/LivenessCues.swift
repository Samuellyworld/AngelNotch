import CoreGraphics

struct CueReading: Equatable {
  let level: Float
  let confidence: Float

  nonisolated static let none = CueReading(level: 0, confidence: 0)
}

enum LivenessCueRole: Equatable {
  case deny
  case confirm
}

enum LivenessCue: String, CaseIterable, Hashable, Identifiable {
  case glossGlare
  case deviceDetected
  case flatVs3D
  case depthPose
  case blink

  var id: String { rawValue }

  nonisolated var title: String {
    switch self {
    case .glossGlare: return "Gloss/glare"
    case .deviceDetected: return "Device detected"
    case .flatVs3D: return "Flat vs 3D"
    case .depthPose: return "Depth/pose"
    case .blink: return "Blink"
    }
  }

  nonisolated var role: LivenessCueRole {
    switch self {
    case .glossGlare, .deviceDetected: return .deny
    case .flatVs3D, .depthPose, .blink: return .confirm
    }
  }

  nonisolated var explanation: String {
    switch self {
    case .glossGlare:
      return
        "Large flat specular highlight — glass/screen glare rather than skin's small scattered shine."
    case .deviceDetected:
      return "A device-shaped rectangle overlaps the face — a phone or tablet held up."
    case .flatVs3D: return "Held-out nose points miss the plane fit — the face has real depth."
    case .depthPose:
      return "Nose offset tracks head yaw — the nose sits off the eye plane, so this isn't flat."
    case .blink: return "Eye aspect ratio dipped and recovered — a photo cannot blink."
    }
  }
}

enum LivenessMode: String, CaseIterable, Identifiable, Sendable {
  case light
  case heavy

  var id: String { rawValue }

  var title: String {
    switch self {
    case .light: return "Light"
    case .heavy: return "Heavy"
    }
  }

  var summary: String {
    switch self {
    case .light: return "Only rejects obvious spoofs."
    case .heavy: return "Also requires proof of a real face."
    }
  }
}

struct LivenessTuning: Equatable {
  var glossLevel: Float = 0.04
  var glossFrames: Int = 3

  var deviceLevel: Float = 0.8
  var deviceFrames: Int = 2

  var flatVs3DLevel: Float = 0.25
  var flatVs3DFrames: Int = 2

  var depthPoseLevel: Float = 0.8
  var depthPoseFrames: Int = 2

  var blinkFrames: Int = 1

  var lightModeMinimumFrames: Int = 3

  nonisolated static let `default` = LivenessTuning()

  nonisolated func level(for cue: LivenessCue) -> Float {
    switch cue {
    case .glossGlare: return glossLevel
    case .deviceDetected: return deviceLevel
    case .flatVs3D: return flatVs3DLevel
    case .depthPose: return depthPoseLevel
    case .blink: return 0.5
    }
  }

  nonisolated func frames(for cue: LivenessCue) -> Int {
    switch cue {
    case .glossGlare: return glossFrames
    case .deviceDetected: return deviceFrames
    case .flatVs3D: return flatVs3DFrames
    case .depthPose: return depthPoseFrames
    case .blink: return blinkFrames
    }
  }
}

enum LivenessDecision: Equatable {
  case pending
  case confirmed(by: LivenessCue?)
  case denied(by: LivenessCue)

  var isConfirmed: Bool {
    if case .confirmed = self { return true }
    return false
  }
  var isDenied: Bool {
    if case .denied = self { return true }
    return false
  }

  var denialReason: String? {
    guard case .denied(let cue) = self else { return nil }
    switch cue {
    case .glossGlare: return "Screen glare detected — this looks like a photo on a display."
    case .deviceDetected:
      return
        "A device-shaped rectangle was detected around the face — this looks like a photo or screen."
    default: return "Liveness check failed."
    }
  }
}

struct LivenessCueState: Equatable {
  var reading: CueReading = .none
  var framesCounted: Int = 0
  var hasFired: Bool = false

  func progress(threshold: Int) -> Float {
    guard threshold > 0 else { return hasFired ? 1 : 0 }
    return min(1, Float(framesCounted) / Float(threshold))
  }
}

struct LivenessSnapshot: Equatable {
  let decision: LivenessDecision
  let mode: LivenessMode
  let cueStates: [LivenessCue: LivenessCueState]
  let frameCount: Int

  nonisolated static let empty = LivenessSnapshot(
    decision: .pending, mode: .light, cueStates: [:], frameCount: 0
  )

  func state(for cue: LivenessCue) -> LivenessCueState {
    cueStates[cue] ?? LivenessCueState()
  }
}

struct LivenessEvaluator {
  var mode: LivenessMode
  var tuning: LivenessTuning
  var enabledCues: Set<LivenessCue>

  private(set) var states: [LivenessCue: LivenessCueState] = [:]
  private(set) var framesObserved: Int = 0

  init(
    mode: LivenessMode = .light,
    tuning: LivenessTuning = .default,
    enabledCues: Set<LivenessCue> = Set(LivenessCue.allCases)
  ) {
    self.mode = mode
    self.tuning = tuning
    self.enabledCues = enabledCues
  }

  mutating func reset() {
    states = [:]
    framesObserved = 0
  }

  mutating func observe(_ readings: [LivenessCue: CueReading]) -> LivenessSnapshot {
    framesObserved += 1

    for cue in LivenessCue.allCases {
      var state = states[cue] ?? LivenessCueState()
      let reading = readings[cue] ?? .none
      state.reading = reading
      if reading.confidence > 0, reading.level >= tuning.level(for: cue) {
        state.framesCounted += 1
        if state.framesCounted >= tuning.frames(for: cue) {
          state.hasFired = true
        }
      }
      states[cue] = state
    }

    return LivenessSnapshot(
      decision: currentDecision(), mode: mode, cueStates: states, frameCount: framesObserved
    )
  }

  private func currentDecision() -> LivenessDecision {
    for cue in LivenessCue.allCases
    where cue.role == .deny && enabledCues.contains(cue) && (states[cue]?.hasFired ?? false) {
      return .denied(by: cue)
    }

    if mode == .light {
      return framesObserved >= tuning.lightModeMinimumFrames ? .confirmed(by: nil) : .pending
    }

    for cue in LivenessCue.allCases
    where cue.role == .confirm && enabledCues.contains(cue) && (states[cue]?.hasFired ?? false) {
      return .confirmed(by: cue)
    }

    return .pending
  }
}

nonisolated enum LivenessCues {
  nonisolated static func readings(
    window: [LivenessFrame], geometry: GeometryLivenessResult
  ) -> [LivenessCue: CueReading] {
    [
      .glossGlare: glossGlare(window.last),
      .deviceDetected: deviceDetected(window.last),
      .flatVs3D: geometry.planarReading,
      .depthPose: LivenessScoring.poseDepthConsistency(window),
      .blink: LivenessScoring.blinkDynamics(window),
    ]
  }

  nonisolated static func glossGlare(_ frame: LivenessFrame?) -> CueReading {
    guard let glare = frame?.glare else { return .none }
    let fractionScore = ramp(glare.specularFraction, floor: 0.01, ceiling: 0.08)
    let clusterFactor = ramp(glare.specularClusterRatio, floor: 0.3, ceiling: 1.0)
    let level = fractionScore * (0.3 + 0.7 * clusterFactor)
    let confidence = ramp(Float(glare.cropPixelWidth), floor: 50, ceiling: 130)
    return CueReading(level: level, confidence: confidence)
  }

  nonisolated static func deviceDetected(_ frame: LivenessFrame?) -> CueReading {
    guard let overlap = frame?.deviceOverlapFraction else { return .none }
    return CueReading(level: Float(min(max(overlap, 0), 1)), confidence: 1)
  }

  nonisolated static func ramp(_ value: Float, floor: Float, ceiling: Float) -> Float {
    min(max((value - floor) / max(ceiling - floor, 0.0001), 0), 1)
  }
}
