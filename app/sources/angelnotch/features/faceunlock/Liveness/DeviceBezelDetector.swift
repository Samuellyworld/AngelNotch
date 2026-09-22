import CoreGraphics
import Vision

struct DeviceBezelObservation {
  let rectangle: CGRect?
  let faceOverlapFraction: CGFloat?

  nonisolated static let none = DeviceBezelObservation(rectangle: nil, faceOverlapFraction: nil)
}

nonisolated enum DeviceBezelDetector {
  private static func makeRequest() -> VNDetectRectanglesRequest {
    let request = VNDetectRectanglesRequest()
    request.minimumConfidence = 0.6
    request.minimumSize = 0.15
    request.maximumObservations = 3
    request.minimumAspectRatio = 0.35
    request.maximumAspectRatio = 1.0
    request.quadratureTolerance = 30

    return request
  }

  static func detect(in image: CGImage, faceBoundingBox: CGRect) -> DeviceBezelObservation {
    let request = makeRequest()
    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    guard (try? handler.perform([request])) != nil,
      let results = request.results, !results.isEmpty
    else { return .none }

    let imageSize = CGSize(width: image.width, height: image.height)
    let candidates = results.map {
      FaceDetector.convertToImageSpace($0.boundingBox, imageSize: imageSize)
    }
    guard let largest = candidates.max(by: { $0.width * $0.height < $1.width * $1.height }) else {
      return .none
    }

    let faceArea = faceBoundingBox.width * faceBoundingBox.height
    guard faceArea > 0 else {
      return DeviceBezelObservation(rectangle: largest, faceOverlapFraction: nil)
    }
    let intersection = largest.intersection(faceBoundingBox)
    let overlap = (intersection.width * intersection.height) / faceArea
    return DeviceBezelObservation(rectangle: largest, faceOverlapFraction: overlap)
  }
}
