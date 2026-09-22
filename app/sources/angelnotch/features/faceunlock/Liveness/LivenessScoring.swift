import CoreGraphics
import Foundation

struct LivenessFrame {
  let timestamp: Date
  let landmarks: [LandmarkPoint]
  let interocularDistance: CGFloat?
  let yaw: Float?
  let leftEyeAspectRatio: CGFloat?
  let rightEyeAspectRatio: CGFloat?
  let noseOffsetRatio: CGFloat?
  let hasReliableLandmarks: Bool
  let deviceOverlapFraction: CGFloat?
  let glare: GlareSample?

  init(
    timestamp: Date,
    landmarks: [LandmarkPoint],
    interocularDistance: CGFloat?,
    yaw: Float?,
    leftEyeAspectRatio: CGFloat?,
    rightEyeAspectRatio: CGFloat?,
    noseOffsetRatio: CGFloat?,
    hasReliableLandmarks: Bool,
    deviceOverlapFraction: CGFloat?,
    glare: GlareSample? = nil
  ) {
    self.timestamp = timestamp
    self.landmarks = landmarks
    self.interocularDistance = interocularDistance
    self.yaw = yaw
    self.leftEyeAspectRatio = leftEyeAspectRatio
    self.rightEyeAspectRatio = rightEyeAspectRatio
    self.noseOffsetRatio = noseOffsetRatio
    self.hasReliableLandmarks = hasReliableLandmarks
    self.deviceOverlapFraction = deviceOverlapFraction
    self.glare = glare
  }
}

nonisolated enum LivenessScoring {

  static func poseDepthConsistency(_ window: [LivenessFrame]) -> CueReading {
    let pairs = window.compactMap { frame -> (CGFloat, CGFloat)? in
      guard let offset = frame.noseOffsetRatio, let yaw = frame.yaw, frame.hasReliableLandmarks
      else { return nil }
      return (offset, CGFloat(tan(yaw)))
    }
    guard pairs.count >= 4 else { return .none }

    let yaws = pairs.map(\.1)
    guard let minYaw = yaws.min(), let maxYaw = yaws.max() else { return .none }
    let yawRange = abs(atan(maxYaw) - atan(minYaw))
    let minMeasurableRange: CGFloat = 12 * .pi / 180
    guard yawRange > minMeasurableRange else { return .none }

    guard let correlation = pearsonCorrelation(pairs.map(\.0), pairs.map(\.1)) else { return .none }
    let level = Float(clamp((correlation + 1) / 2, 0, 1))
    let confidence = Float(clamp((yawRange - minMeasurableRange) / (15 * .pi / 180), 0, 1))
    return CueReading(level: level, confidence: confidence)
  }

  private static func pearsonCorrelation(_ xs: [CGFloat], _ ys: [CGFloat]) -> CGFloat? {
    guard xs.count == ys.count, xs.count >= 2 else { return nil }
    let n = CGFloat(xs.count)
    let meanX = xs.reduce(0, +) / n
    let meanY = ys.reduce(0, +) / n
    var covariance: CGFloat = 0
    var varX: CGFloat = 0
    var varY: CGFloat = 0
    for i in 0..<xs.count {
      let dx = xs[i] - meanX
      let dy = ys[i] - meanY
      covariance += dx * dy
      varX += dx * dx
      varY += dy * dy
    }
    guard varX > 0, varY > 0 else { return nil }
    return covariance / (varX.squareRoot() * varY.squareRoot())
  }

  static func blinkDynamics(_ window: [LivenessFrame]) -> CueReading {
    let ears = window.compactMap { frame -> CGFloat? in
      guard let l = frame.leftEyeAspectRatio, let r = frame.rightEyeAspectRatio else { return nil }
      return (l + r) / 2
    }
    guard ears.count >= 4 else { return .none }

    let baseline = ears.max() ?? 0
    guard baseline > 0 else { return .none }
    guard let minEAR = ears.min(), let minIndex = ears.firstIndex(of: minEAR) else { return .none }

    let dipRatio = minEAR / baseline
    let recoveryRadius = 3
    let openBefore = ears[..<minIndex].suffix(recoveryRadius).contains { $0 / baseline > 0.7 }
    let openAfter = ears[(minIndex + 1)...].prefix(recoveryRadius).contains { $0 / baseline > 0.7 }
    let hasNeighborRecovery = minIndex > 0 && minIndex < ears.count - 1 && openBefore && openAfter

    guard dipRatio < 0.65, hasNeighborRecovery else { return .none }
    return CueReading(level: 1, confidence: 1)
  }

  private static func clamp<T: Comparable>(_ value: T, _ lower: T, _ upper: T) -> T {
    min(max(value, lower), upper)
  }
}
