import Combine
import Foundation

struct FaceSample: Codable, Equatable {
  let embedding: [Float]
  let pose: String?
  let capturedAt: Date
  let quality: Float?
}

extension FaceSample {
  enum QualityTier {
    case unrated
    case poor
    case fair
    case good
  }

  var qualityTier: QualityTier {
    guard let quality else { return .unrated }
    if quality < 0.4 { return .poor }
    if quality < 0.5 { return .fair }
    return .good
  }
}

struct FaceIdentity: Codable, Identifiable, Equatable {
  let id: UUID
  var name: String
  var samples: [FaceSample]
  var modelIdentifier: String
  var embeddingDimension: Int
  var createdAt: Date
  var isEnabled: Bool

  init(
    id: UUID,
    name: String,
    samples: [FaceSample],
    modelIdentifier: String,
    embeddingDimension: Int,
    createdAt: Date,
    isEnabled: Bool = true
  ) {
    self.id = id
    self.name = name
    self.samples = samples
    self.modelIdentifier = modelIdentifier
    self.embeddingDimension = embeddingDimension
    self.createdAt = createdAt
    self.isEnabled = isEnabled
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(UUID.self, forKey: .id)
    name = try container.decode(String.self, forKey: .name)
    samples = try container.decode([FaceSample].self, forKey: .samples)
    modelIdentifier = try container.decode(String.self, forKey: .modelIdentifier)
    embeddingDimension = try container.decode(Int.self, forKey: .embeddingDimension)
    createdAt = try container.decode(Date.self, forKey: .createdAt)
    isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
  }

  nonisolated var template: [Float]? {
    FaceEmbedding.average(samples.map(\.embedding))
  }

  nonisolated func isStale(comparedTo embedder: FaceEmbedder) -> Bool {
    modelIdentifier != embedder.modelIdentifier
  }
}

enum FaceEnrollmentStoreError: LocalizedError {
  case storeUnreadable

  var errorDescription: String? {
    switch self {
    case .storeUnreadable:
      return
        "Your enrolled faces couldn't be read, so nothing was saved — writing now would overwrite them."
    }
  }
}

@MainActor
final class FaceEnrollmentStore: ObservableObject {
  static let shared = FaceEnrollmentStore()

  @Published private(set) var identities: [FaceIdentity] = []
  @Published private(set) var isLocked = true

  @Published private(set) var loadFailure: String?

  private var hasLoadedSuccessfully = false

  var activeIdentities: [FaceIdentity] {
    identities.filter(\.isEnabled)
  }

  private init() {
    reloadIfUnlocked()
    NotificationCenter.default.addObserver(
      forName: .secureCredentialSessionDidChange,
      object: nil,
      queue: nil
    ) { [weak self] _ in
      Task { @MainActor [weak self] in
        self?.reloadIfUnlocked()
      }
    }
  }

  func reloadIfUnlocked() {
    guard SecureCredentialManager.isSessionUnlocked else {
      isLocked = true
      return
    }
    do {
      identities = try SecureFaceStore.load()
      hasLoadedSuccessfully = true
      loadFailure = nil
    } catch {
      identities = []
      loadFailure = error.localizedDescription
    }
    isLocked = false
  }

  @discardableResult
  func addSample(
    name: String, embedding: [Float], embedder: FaceEmbedder, pose: String? = nil,
    quality: Float? = nil
  ) throws -> Bool {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return false }

    let sample = FaceSample(embedding: embedding, pose: pose, capturedAt: Date(), quality: quality)

    if let index = identities.firstIndex(where: { $0.name == trimmed }) {
      if identities[index].modelIdentifier != embedder.modelIdentifier {
        identities[index].samples = [sample]
      } else {
        identities[index].samples.append(sample)
      }
      identities[index].modelIdentifier = embedder.modelIdentifier
      identities[index].embeddingDimension = embedder.embeddingDimension
    } else {
      identities.append(
        FaceIdentity(
          id: UUID(),
          name: trimmed,
          samples: [sample],
          modelIdentifier: embedder.modelIdentifier,
          embeddingDimension: embedder.embeddingDimension,
          createdAt: Date()
        ))
    }
    try persist()
    return true
  }

  @discardableResult
  func commitEnrollment(
    replacing existingID: UUID?,
    name: String,
    samples: [FaceSample],
    embedder: FaceEmbedder
  ) throws -> FaceIdentity? {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, !samples.isEmpty else { return nil }

    var updated = identities
    let committed: FaceIdentity
    if let existingID, let index = updated.firstIndex(where: { $0.id == existingID }) {
      updated[index].name = trimmed
      updated[index].samples = samples
      updated[index].modelIdentifier = embedder.modelIdentifier
      updated[index].embeddingDimension = embedder.embeddingDimension
      committed = updated[index]
    } else {
      committed = FaceIdentity(
        id: UUID(),
        name: trimmed,
        samples: samples,
        modelIdentifier: embedder.modelIdentifier,
        embeddingDimension: embedder.embeddingDimension,
        createdAt: Date()
      )
      updated.append(committed)
    }
    try SecureFaceStore.save(updated)
    identities = updated
    return committed
  }

  func nameIsTaken(_ name: String, excluding id: UUID? = nil) -> Bool {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return false }
    return identities.contains {
      $0.id != id
        && $0.name.compare(trimmed, options: [.caseInsensitive, .diacriticInsensitive])
          == .orderedSame
    }
  }

  func setEnabled(_ isEnabled: Bool, for identityID: UUID) throws {
    guard let index = identities.firstIndex(where: { $0.id == identityID }) else { return }
    let previous = identities[index].isEnabled
    guard previous != isEnabled else { return }
    identities[index].isEnabled = isEnabled
    do {
      try persist()
    } catch {
      identities[index].isEnabled = previous
      throw error
    }
  }

  func delete(_ identity: FaceIdentity) throws {
    identities.removeAll { $0.id == identity.id }
    try persist()
  }

  func deleteAll() {
    identities.removeAll()
    SecureFaceStore.deleteAll()
    loadFailure = nil
    hasLoadedSuccessfully = true
  }

  private func persist() throws {
    guard hasLoadedSuccessfully else {
      throw FaceEnrollmentStoreError.storeUnreadable
    }
    try SecureFaceStore.save(identities)
  }
}
