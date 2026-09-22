import CoreGraphics
import Foundation

nonisolated struct FaceRecognitionResult {
  let embedding: [Float]
  let alignedImage: CGImage
  let alignmentTier: AlignmentTier
  let quality: Float?
  let face: DetectedFace
}

nonisolated enum FaceRecognitionPipelineError: LocalizedError {
  case noFaceDetected
  case alignmentFailed

  var errorDescription: String? {
    switch self {
    case .noFaceDetected: return "No face detected in frame."
    case .alignmentFailed: return "Could not align the detected face."
    }
  }
}

@MainActor
final class FaceRecognitionPipeline {
  nonisolated let embedder: FaceEmbedder

  private(set) var usingFallbackEmbedder: Bool
  private(set) var fallbackReason: String?

  init() {
    do {
      embedder = try ArcFaceEmbedder()
      usingFallbackEmbedder = false
      fallbackReason = nil
    } catch {
      embedder = VisionFeaturePrintEmbedder()
      usingFallbackEmbedder = true
      fallbackReason = error.localizedDescription
    }
  }

  nonisolated func recognize(in frame: CGImage, preferNear previousBoundingBox: CGRect? = nil)
    throws -> FaceRecognitionResult
  {
    let faces = try FaceDetector.detectFaces(in: frame)
    guard let face = Self.selectDominantFace(in: faces, preferNear: previousBoundingBox) else {
      throw FaceRecognitionPipelineError.noFaceDetected
    }
    return try recognize(face, in: frame)
  }

  nonisolated func recognize(_ face: DetectedFace, in frame: CGImage) throws
    -> FaceRecognitionResult
  {
    let inputImage: CGImage
    let tier: AlignmentTier
    if embedder.requiresAlignment {
      guard let aligned = FaceAligner.align(face, from: frame) else {
        throw FaceRecognitionPipelineError.alignmentFailed
      }
      inputImage = aligned.image
      tier = aligned.tier
    } else {
      guard let cropped = FaceDetector.crop(face, from: frame) else {
        throw FaceRecognitionPipelineError.alignmentFailed
      }
      inputImage = cropped
      tier = .paddedCrop
    }

    let embedding = try embedder.embedding(for: inputImage)
    return FaceRecognitionResult(
      embedding: embedding, alignedImage: inputImage, alignmentTier: tier, quality: face.quality,
      face: face)
  }

  nonisolated static func largestFace(in faces: [DetectedFace]) -> DetectedFace? {
    faces.max {
      $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height
    }
  }

  nonisolated(unsafe) static var minimumProminentFaceWidth: Float = 0.18

  nonisolated private static let continuityDistanceTolerance: CGFloat = 0.3

  nonisolated static func selectDominantFace(
    in faces: [DetectedFace], preferNear previousBoundingBox: CGRect? = nil
  ) -> DetectedFace? {
    let candidates = faces.filter {
      $0.normalizedBoundingBox.width >= CGFloat(minimumProminentFaceWidth)
    }
    guard !candidates.isEmpty else { return nil }

    if let previous = previousBoundingBox {
      let previousCenter = CGPoint(x: previous.midX, y: previous.midY)
      if let nearest = candidates.min(by: {
        distance(from: $0, to: previousCenter) < distance(from: $1, to: previousCenter)
      }),
        distance(from: nearest, to: previousCenter) < continuityDistanceTolerance
      {
        return nearest
      }
    }

    return candidates.max {
      $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height
    }
  }

  nonisolated private static func distance(from face: DetectedFace, to point: CGPoint) -> CGFloat {
    let center = CGPoint(x: face.normalizedBoundingBox.midX, y: face.normalizedBoundingBox.midY)
    return hypot(center.x - point.x, center.y - point.y)
  }
}

nonisolated struct ScoredIdentity {
  let identity: FaceIdentity
  let centroidSimilarity: Float
  let maxSampleSimilarity: Float
}

extension FaceRecognitionPipeline {
  nonisolated func score(_ embedding: [Float], against identities: [FaceIdentity])
    -> [ScoredIdentity]
  {
    identities.compactMap { identity in
      guard let template = identity.template, !identity.samples.isEmpty else { return nil }
      let centroidSim = FaceEmbedding.cosineSimilarity(embedding, template)
      let maxSim =
        identity.samples
        .map { FaceEmbedding.cosineSimilarity(embedding, $0.embedding) }
        .max() ?? centroidSim
      return ScoredIdentity(
        identity: identity, centroidSimilarity: centroidSim, maxSampleSimilarity: maxSim)
    }.sorted { $0.centroidSimilarity > $1.centroidSimilarity }
  }

  nonisolated func bestMatch(in scored: [ScoredIdentity], threshold: Float) -> ScoredIdentity? {
    guard let first = scored.first, !first.identity.isStale(comparedTo: embedder) else {
      return nil
    }
    guard first.centroidSimilarity >= threshold, first.maxSampleSimilarity >= threshold else {
      return nil
    }
    return first
  }
}
