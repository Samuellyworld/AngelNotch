import Foundation

@MainActor
final class LivenessAnalyzer {
  private let windowDuration: TimeInterval

  var modeProvider: () -> LivenessMode = { .light }
  var tuningProvider: () -> LivenessTuning = { .default }
  var enabledCuesProvider: () -> Set<LivenessCue> = { Set(LivenessCue.allCases) }

  private var frames: [LivenessFrame] = []
  private var evaluator = LivenessEvaluator()
  private(set) var lastSnapshot = LivenessSnapshot.empty
  private(set) var lastGeometry = GeometryLivenessResult.empty

  init(windowDuration: TimeInterval = 2.0) {
    self.windowDuration = windowDuration
  }

  func reset() {
    frames.removeAll()
    evaluator.reset()
    lastSnapshot = .empty
    lastGeometry = .empty
  }

  @discardableResult
  func observe(_ frame: LivenessFrame) -> LivenessSnapshot {
    frames.append(frame)
    frames.removeAll { frame.timestamp.timeIntervalSince($0.timestamp) > windowDuration }

    evaluator.mode = modeProvider()
    evaluator.tuning = tuningProvider()
    evaluator.enabledCues = enabledCuesProvider()

    let geometry = GeometryLiveness.evaluate(frames)
    lastGeometry = geometry

    let readings = LivenessCues.readings(window: frames, geometry: geometry)
    let snapshot = evaluator.observe(readings)
    lastSnapshot = snapshot
    return snapshot
  }
}
