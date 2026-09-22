import CoreGraphics
@preconcurrency import Vision

struct DetectedFace: @unchecked Sendable {
  let boundingBox: CGRect
  let normalizedBoundingBox: CGRect
  let quality: Float?
  let yaw: Float?
  let roll: Float?
  let pitch: Float?
  let landmarks: VNFaceLandmarks2D?
  let imageSize: CGSize
}

nonisolated enum FaceDetector {
  static func detectFaces(in image: CGImage) throws -> [DetectedFace] {
    let handler = VNImageRequestHandler(cgImage: image, options: [:])

    let rectanglesRequest = VNDetectFaceRectanglesRequest()
    try handler.perform([rectanglesRequest])
    let faceObservations = rectanglesRequest.results ?? []
    guard !faceObservations.isEmpty else { return [] }

    let qualityRequest = VNDetectFaceCaptureQualityRequest()
    let landmarksRequest = VNDetectFaceLandmarksRequest()
    qualityRequest.inputFaceObservations = faceObservations
    landmarksRequest.inputFaceObservations = faceObservations
    try handler.perform([qualityRequest, landmarksRequest])

    let qualityResults = qualityRequest.results ?? []
    let landmarkResults = landmarksRequest.results ?? []
    let imageSize = CGSize(width: image.width, height: image.height)

    return faceObservations.enumerated().map { index, observation in
      let pixelRect = convertToImageSpace(observation.boundingBox, imageSize: imageSize)
      return DetectedFace(
        boundingBox: pixelRect,
        normalizedBoundingBox: observation.boundingBox,
        quality: qualityResults.indices.contains(index)
          ? qualityResults[index].faceCaptureQuality : nil,
        yaw: observation.yaw?.floatValue,
        roll: observation.roll?.floatValue,
        pitch: observation.pitch?.floatValue,
        landmarks: landmarkResults.indices.contains(index) ? landmarkResults[index].landmarks : nil,
        imageSize: imageSize
      )
    }
  }

  static func convertToImageSpace(_ normalizedRect: CGRect, imageSize: CGSize) -> CGRect {
    let x = normalizedRect.origin.x * imageSize.width
    let width = normalizedRect.width * imageSize.width
    let height = normalizedRect.height * imageSize.height
    let y = (1 - normalizedRect.origin.y) * imageSize.height - height
    return CGRect(x: x, y: y, width: width, height: height)
  }

  static func crop(_ face: DetectedFace, from image: CGImage, paddingFraction: CGFloat = 0.2)
    -> CGImage?
  {
    let imageBounds = CGRect(x: 0, y: 0, width: image.width, height: image.height)
    let padX = face.boundingBox.width * paddingFraction
    let padY = face.boundingBox.height * paddingFraction
    let padded = face.boundingBox.insetBy(dx: -padX, dy: -padY).intersection(imageBounds)
    guard !padded.isEmpty else { return nil }
    return image.cropping(to: padded)
  }
}
