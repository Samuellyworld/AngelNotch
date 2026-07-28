import AppKit
import CryptoKit
import Foundation

enum ClipboardContentKind: String, Codable, Sendable {
  case text
  case image
}

struct ClipboardHistoryItem: Identifiable, Codable, Equatable, Sendable {
  let id: UUID
  let kind: ClipboardContentKind
  var text: String?
  var imageFilename: String?
  let createdAt: Date
  var isPinned: Bool
  let fingerprint: String
}

@MainActor
final class ClipboardHistoryStore: ObservableObject {
  @Published private(set) var items: [ClipboardHistoryItem]
  @Published var searchQuery = ""
  @Published private(set) var recentlyCopiedID: UUID?

  private var monitorTask: Task<Void, Never>?
  private var copyFeedbackTask: Task<Void, Never>?
  private var observedChangeCount = NSPasteboard.general.changeCount
  private let maximumItems = 100

  init() {
    items =
      StoragePaths.load(
        [ClipboardHistoryItem].self,
        from: "clipboard-history.json"
      ) ?? []
    removeMissingImages()
  }

  var filteredItems: [ClipboardHistoryItem] {
    let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else { return items }
    return items.filter {
      $0.text?.localizedCaseInsensitiveContains(query) == true
    }
  }

  func start() {
    guard monitorTask == nil else { return }
    monitorTask = Task { @MainActor [weak self] in
      while !Task.isCancelled {
        self?.capturePasteboardIfNeeded()
        try? await Task.sleep(for: .milliseconds(700))
      }
    }
  }

  func stop() {
    monitorTask?.cancel()
    monitorTask = nil
  }

  func copy(_ item: ClipboardHistoryItem) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()

    switch item.kind {
    case .text:
      if let text = item.text {
        pasteboard.setString(text, forType: .string)
      }
    case .image:
      if let url = imageURL(for: item),
        let image = NSImage(contentsOf: url)
      {
        pasteboard.writeObjects([image])
      }
    }

    observedChangeCount = pasteboard.changeCount
    recentlyCopiedID = item.id
    copyFeedbackTask?.cancel()
    copyFeedbackTask = Task { @MainActor [weak self] in
      try? await Task.sleep(for: .seconds(1.4))
      guard !Task.isCancelled else { return }
      self?.recentlyCopiedID = nil
    }
  }

  func togglePinned(_ item: ClipboardHistoryItem) {
    guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
    items[index].isPinned.toggle()
    sortAndPersist()
  }

  func delete(_ item: ClipboardHistoryItem) {
    if let url = imageURL(for: item) {
      try? FileManager.default.removeItem(at: url)
    }
    items.removeAll { $0.id == item.id }
    persist()
  }

  func clearUnpinned() {
    for item in items where !item.isPinned {
      if let url = imageURL(for: item) {
        try? FileManager.default.removeItem(at: url)
      }
    }
    items.removeAll { !$0.isPinned }
    persist()
  }

  func imageURL(for item: ClipboardHistoryItem) -> URL? {
    guard let filename = item.imageFilename else { return nil }
    return StoragePaths.clipboardImages.appending(path: filename)
  }

  private func capturePasteboardIfNeeded() {
    let pasteboard = NSPasteboard.general
    guard pasteboard.changeCount != observedChangeCount else { return }
    observedChangeCount = pasteboard.changeCount

    let types = Set(pasteboard.types ?? [])
    guard !containsSensitiveOrTransientType(types) else { return }

    if let image = NSImage(pasteboard: pasteboard), capture(image: image) {
      return
    }

    guard
      let rawText = pasteboard.string(forType: .string),
      !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      return
    }

    let text = String(rawText.prefix(20_000))
    let fingerprint = digest(Data(text.utf8))
    insert(
      ClipboardHistoryItem(
        id: UUID(),
        kind: .text,
        text: text,
        imageFilename: nil,
        createdAt: .now,
        isPinned: false,
        fingerprint: fingerprint
      )
    )
  }

  @discardableResult
  private func capture(image: NSImage) -> Bool {
    guard
      let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:])
    else {
      return false
    }

    let fingerprint = digest(png)
    guard items.first?.fingerprint != fingerprint else { return true }

    let id = UUID()
    let filename = "\(id.uuidString).png"
    let url = StoragePaths.clipboardImages.appending(path: filename)
    do {
      try png.write(to: url, options: .atomic)
    } catch {
      return false
    }

    insert(
      ClipboardHistoryItem(
        id: id,
        kind: .image,
        text: nil,
        imageFilename: filename,
        createdAt: .now,
        isPinned: false,
        fingerprint: fingerprint
      )
    )
    return true
  }

  private func insert(_ item: ClipboardHistoryItem) {
    if let existing = items.firstIndex(where: { $0.fingerprint == item.fingerprint }) {
      let previous = items.remove(at: existing)
      var refreshed = item
      refreshed.isPinned = previous.isPinned
      items.insert(refreshed, at: 0)
    } else {
      items.insert(item, at: 0)
    }

    trimHistory()
    sortAndPersist()
  }

  private func trimHistory() {
    guard items.count > maximumItems else { return }
    let pinned = items.filter(\.isPinned)
    let recent = Array(
      items.filter { !$0.isPinned }
        .prefix(max(0, maximumItems - pinned.count))
    )
    let retainedIDs = Set((pinned + recent).map(\.id))

    for item in items where !retainedIDs.contains(item.id) {
      if let url = imageURL(for: item) {
        try? FileManager.default.removeItem(at: url)
      }
    }
    items = items.filter { retainedIDs.contains($0.id) }
  }

  private func sortAndPersist() {
    items.sort {
      if $0.isPinned != $1.isPinned { return $0.isPinned }
      return $0.createdAt > $1.createdAt
    }
    persist()
  }

  private func persist() {
    StoragePaths.save(items, to: "clipboard-history.json")
  }

  private func removeMissingImages() {
    items.removeAll {
      $0.kind == .image
        && imageURL(for: $0).map {
          !FileManager.default.fileExists(atPath: $0.path)
        } == true
    }
  }

  private func containsSensitiveOrTransientType(
    _ types: Set<NSPasteboard.PasteboardType>
  ) -> Bool {
    let excludedFragments = [
      "concealed",
      "transient",
      "autogenerated",
      "password",
      "onepassword",
      "keepass",
      "bitwarden",
      "lastpass",
    ]

    return types.contains { type in
      let value = type.rawValue.lowercased()
      return excludedFragments.contains { value.contains($0) }
    }
  }

  private func digest(_ data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  }
}
