import CoreGraphics
import Vision

nonisolated enum LivenessFeatureExtractor {
  static func extract(
    from result: FaceRecognitionResult, frame: CGImage, faceCrop: CGImage? = nil,
    timestamp: Date = Date()
  ) -> LivenessFrame {
    let face = result.face
    let deviceOverlap = DeviceBezelDetector.detect(in: frame, faceBoundingBox: face.boundingBox)
      .faceOverlapFraction
    let glare = faceCrop.flatMap { GlareCueExtractor.extract(faceCrop: $0) }

    guard let landmarks = face.landmarks else {
      return LivenessFrame(
        timestamp: timestamp, landmarks: [], interocularDistance: nil,
        yaw: face.yaw,
        leftEyeAspectRatio: nil, rightEyeAspectRatio: nil,
        noseOffsetRatio: nil,
        hasReliableLandmarks: false,
        deviceOverlapFraction: deviceOverlap,
        glare: glare
      )
    }

    let imageSize = face.imageSize
    let points = LandmarkGeometry.allPoints(from: landmarks, imageSize: imageSize)
    let interocular = LandmarkGeometry.interocularDistance(from: landmarks, imageSize: imageSize)
    let leftEAR = landmarks.leftEye.flatMap {
      LandmarkGeometry.eyeAspectRatio(of: $0, imageSize: imageSize)
    }
    let rightEAR = landmarks.rightEye.flatMap {
      LandmarkGeometry.eyeAspectRatio(of: $0, imageSize: imageSize)
    }

    let eyeLeft = LandmarkGeometry.eyeCenter(
      pupil: landmarks.leftPupil, eye: landmarks.leftEye, imageSize: imageSize)
    let eyeRight = LandmarkGeometry.eyeCenter(
      pupil: landmarks.rightPupil, eye: landmarks.rightEye, imageSize: imageSize)

    var noseOffsetRatio: CGFloat?
    if let interocular, interocular > 0, let eyeLeft, let eyeRight,
      let nose = landmarks.nose,
      let noseCenter = LandmarkGeometry.centroid(of: nose, imageSize: imageSize)
    {
      let eyeMidX = (eyeLeft.x + eyeRight.x) / 2
      noseOffsetRatio = (noseCenter.x - eyeMidX) / interocular
    }

    return LivenessFrame(
      timestamp: timestamp,
      landmarks: points,
      interocularDistance: interocular,
      yaw: face.yaw,
      leftEyeAspectRatio: leftEAR, rightEyeAspectRatio: rightEAR,
      noseOffsetRatio: noseOffsetRatio,
      hasReliableLandmarks: result.alignmentTier == .fivePoint,
      deviceOverlapFraction: deviceOverlap,
      glare: glare
    )
  }
}
