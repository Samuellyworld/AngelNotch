import AppKit
import Foundation
import UniformTypeIdentifiers

enum LoopActivityKind: String, Codable, Sendable {
  case download
  case delivery
  case sport
  case task
}

struct LoopActivity: Identifiable, Codable, Equatable, Sendable {
  let id: String
  let kind: LoopActivityKind
  let title: String
  let detail: String
  let progress: Double?
  let updatedAt: Date
  let isComplete: Bool
}

@MainActor
final class LiveActivityCenter: ObservableObject {
  @Published private(set) var activities: [LoopActivity] = []

  private var monitorTask: Task<Void, Never>?

  func start() {
    guard monitorTask == nil else { return }
    monitorTask = Task { @MainActor [weak self] in
      while !Task.isCancelled {
        self?.loadLocalSources()
        try? await Task.sleep(for: .seconds(1))
      }
    }
  }

  func upsert(_ activity: LoopActivity) {
    if let index = activities.firstIndex(where: { $0.id == activity.id }) {
      activities[index] = activity
    } else {
      activities.insert(activity, at: 0)
    }
    prune()
  }

  func end(_ id: String) {
    activities.removeAll { $0.id == id }
  }

  /// Allows integrations to publish a local activity without a cloud account.
  func importActivityJSON(_ url: URL) {
    guard
      let data = try? Data(contentsOf: url),
      let activity = try? JSONDecoder.iso8601.decode(
        LoopActivity.self,
        from: data
      )
    else {
      return
    }
    upsert(
      LoopActivity(
        id: activity.id,
        kind: activity.kind,
        title: activity.title,
        detail: activity.detail,
        progress: activity.progress,
        updatedAt: .now,
        isComplete: activity.isComplete
      )
    )
  }

  func chooseActivityFile() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.json]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.message = "Choose an AngelNotch live activity JSON file."
    if panel.runModal() == .OK, let url = panel.url {
      importActivityJSON(url)
    }
  }

  private func loadLocalSources() {
    let url = StoragePaths.root.appending(path: "download-activity.json")
    guard
      let data = try? Data(contentsOf: url),
      let activity = try? JSONDecoder.iso8601.decode(
        LoopActivity.self,
        from: data
      )
    else {
      return
    }

    if activity.isComplete {
      end(activity.id)
      try? FileManager.default.removeItem(at: url)
    } else {
      upsert(activity)
    }
  }

  private func prune() {
    let cutoff = Date().addingTimeInterval(-24 * 60 * 60)
    activities.removeAll { $0.updatedAt < cutoff || $0.isComplete }
    activities = Array(activities.prefix(5))
  }
}

extension JSONDecoder {
  fileprivate static var iso8601: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }
}
