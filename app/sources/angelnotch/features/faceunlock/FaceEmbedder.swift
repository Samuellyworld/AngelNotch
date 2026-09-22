import CoreGraphics
import Vision

protocol FaceEmbedder: Sendable {
  nonisolated var name: String { get }
  nonisolated var modelIdentifier: String { get }
  nonisolated var embeddingDimension: Int { get }
  nonisolated var requiresAlignment: Bool { get }
  nonisolated func embedding(for face: CGImage) throws -> [Float]
}

enum FaceEmbedderError: LocalizedError {
  case noObservation
  case unsupportedElementType

  var errorDescription: String? {
    switch self {
    case .noObservation:
      return "Vision did not produce a feature print for this image."
    case .unsupportedElementType:
      return "Feature print used an unexpected element type."
    }
  }
}

struct VisionFeaturePrintEmbedder: FaceEmbedder {
  nonisolated let name = "Vision Feature Print"
  nonisolated let modelIdentifier = "vision-feature-print-v1"
  nonisolated let embeddingDimension = 2048
  nonisolated let requiresAlignment = false

  nonisolated func embedding(for face: CGImage) throws -> [Float] {
    let request = VNGenerateImageFeaturePrintRequest()
    let handler = VNImageRequestHandler(cgImage: face, options: [:])
    try handler.perform([request])

    guard let observation = request.results?.first as? VNFeaturePrintObservation else {
      throw FaceEmbedderError.noObservation
    }
    return try Self.floatVector(from: observation)
  }

  nonisolated private static func floatVector(from observation: VNFeaturePrintObservation) throws
    -> [Float]
  {
    let count = observation.elementCount
    switch observation.elementType {
    case .float:
      var result = [Float](repeating: 0, count: count)
      observation.data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
        let buffer = raw.bindMemory(to: Float.self)
        for i in 0..<count { result[i] = buffer[i] }
      }
      return result
    case .double:
      var result = [Float](repeating: 0, count: count)
      observation.data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
        let buffer = raw.bindMemory(to: Double.self)
        for i in 0..<count { result[i] = Float(buffer[i]) }
      }
      return result
    default:
      throw FaceEmbedderError.unsupportedElementType
    }
  }
}

nonisolated enum FaceEmbedding {
  static func l2Normalized(_ vector: [Float]) -> [Float] {
    let norm = sqrt(vector.reduce(Float(0)) { $0 + $1 * $1 })
    guard norm > 0 else { return vector }
    return vector.map { $0 / norm }
  }

  static func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
    guard a.count == b.count, !a.isEmpty else { return 0 }
    var dot: Float = 0
    var normA: Float = 0
    var normB: Float = 0
    for i in 0..<a.count {
      dot += a[i] * b[i]
      normA += a[i] * a[i]
      normB += b[i] * b[i]
    }
    guard normA > 0, normB > 0 else { return 0 }
    return dot / (normA.squareRoot() * normB.squareRoot())
  }

  static func similarityPercent(_ a: [Float], _ b: [Float]) -> Double {
    let similarity = cosineSimilarity(a, b)
    return Double((similarity + 1) / 2) * 100
  }

  static func average(_ vectors: [[Float]]) -> [Float]? {
    guard let first = vectors.first, !first.isEmpty else { return nil }
    let count = Float(vectors.count)
    var sum = [Float](repeating: 0, count: first.count)
    for vector in vectors where vector.count == first.count {
      let normalized = l2Normalized(vector)
      for i in 0..<normalized.count { sum[i] += normalized[i] }
    }
    let mean = sum.map { $0 / count }
    return l2Normalized(mean)
  }
}
