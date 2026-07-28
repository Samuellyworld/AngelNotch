import AppKit
import Foundation
@preconcurrency import Quartz

struct ShelfFile: Identifiable, Codable, Equatable, Sendable {
  let id: UUID
  var bookmark: Data?
  let fallbackPath: String
  let addedAt: Date
  var lastOpenedAt: Date?
  var isPinned: Bool

  var displayName: String {
    URL(fileURLWithPath: fallbackPath).lastPathComponent
  }
}

@MainActor
final class FileShelfStore: NSObject, ObservableObject {
  @Published private(set) var items: [ShelfFile]
  @Published var cleanupAfterDays: Int {
    didSet {
      UserDefaults.standard.set(cleanupAfterDays, forKey: "fileShelf.cleanupDays")
      cleanupExpired()
    }
  }

  private let previewController = FilePreviewController()
  private var sharingPicker: NSSharingServicePicker?

  override init() {
    let storedDays = UserDefaults.standard.integer(forKey: "fileShelf.cleanupDays")
    cleanupAfterDays = storedDays == 0 ? 14 : storedDays
    items = StoragePaths.load([ShelfFile].self, from: "file-shelf.json") ?? []
    super.init()
    cleanupExpired()
  }

  func add(_ urls: [URL]) {
    for url in urls where url.isFileURL {
      guard !items.contains(where: { resolvedURL(for: $0) == url }) else { continue }
      let bookmark = try? url.bookmarkData(
        options: [.withSecurityScope],
        includingResourceValuesForKeys: [.nameKey, .isDirectoryKey],
        relativeTo: nil
      )
      items.insert(
        ShelfFile(
          id: UUID(),
          bookmark: bookmark,
          fallbackPath: url.path,
          addedAt: .now,
          lastOpenedAt: nil,
          isPinned: false
        ),
        at: 0
      )
    }
    persist()
  }

  func remove(_ item: ShelfFile) {
    items.removeAll { $0.id == item.id }
    persist()
  }

  func togglePinned(_ item: ShelfFile) {
    guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
    items[index].isPinned.toggle()
    persist()
  }

  func open(_ item: ShelfFile) {
    guard let url = resolvedURL(for: item) else { return }
    NSWorkspace.shared.open(url)
    markOpened(item)
  }

  func quickLook(_ item: ShelfFile) {
    guard let url = resolvedURL(for: item) else { return }
    previewController.present(url)
    markOpened(item)
  }

  func airDrop(_ item: ShelfFile) {
    guard let url = resolvedURL(for: item) else { return }
    NSSharingService(named: .sendViaAirDrop)?.perform(withItems: [url])
  }

  func share(_ item: ShelfFile, from view: NSView?) {
    guard let url = resolvedURL(for: item), let view else { return }
    let picker = NSSharingServicePicker(items: [url])
    sharingPicker = picker
    picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
  }

  func resolvedURL(for item: ShelfFile) -> URL? {
    if let bookmark = item.bookmark {
      var stale = false
      if let url = try? URL(
        resolvingBookmarkData: bookmark,
        options: [.withSecurityScope],
        relativeTo: nil,
        bookmarkDataIsStale: &stale
      ) {
        return url
      }
    }

    let fallback = URL(fileURLWithPath: item.fallbackPath)
    return FileManager.default.fileExists(atPath: fallback.path) ? fallback : nil
  }

  func cleanupExpired() {
    let cutoff =
      Calendar.current.date(
        byAdding: .day,
        value: -cleanupAfterDays,
        to: .now
      ) ?? .distantPast
    items.removeAll {
      !$0.isPinned && ($0.lastOpenedAt ?? $0.addedAt) < cutoff
    }
    items.removeAll { resolvedURL(for: $0) == nil }
    persist()
  }

  private func markOpened(_ item: ShelfFile) {
    guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
    items[index].lastOpenedAt = .now
    persist()
  }

  private func persist() {
    StoragePaths.save(items, to: "file-shelf.json")
  }
}

@MainActor
private final class FilePreviewController: NSObject, QLPreviewPanelDataSource {
  private var previewURL: URL?

  func present(_ url: URL) {
    previewURL = url
    guard let panel = QLPreviewPanel.shared() else { return }
    panel.dataSource = self
    panel.reloadData()
    panel.makeKeyAndOrderFront(nil)
  }

  nonisolated func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
    MainActor.assumeIsolated {
      previewURL == nil ? 0 : 1
    }
  }

  nonisolated func previewPanel(
    _ panel: QLPreviewPanel!,
    previewItemAt index: Int
  ) -> (any QLPreviewItem)! {
    MainActor.assumeIsolated {
      previewURL as NSURL?
    }
  }
}
