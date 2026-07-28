import AppKit
import Foundation

enum ContextMode: String, Sendable {
  case browser
  case development
  case communication
  case media
  case design
  case general

  var title: String {
    switch self {
    case .browser: "Browse"
    case .development: "Build"
    case .communication: "Connect"
    case .media: "Listen"
    case .design: "Create"
    case .general: "Quick access"
    }
  }

  var symbolName: String {
    switch self {
    case .browser: "globe"
    case .development: "chevron.left.forwardslash.chevron.right"
    case .communication: "bubble.left.and.bubble.right.fill"
    case .media: "waveform"
    case .design: "paintbrush.fill"
    case .general: "sparkles"
    }
  }
}

@MainActor
final class ContextMonitor: ObservableObject {
  @Published private(set) var activeApplicationName = "Mac"
  @Published private(set) var activeBundleIdentifier: String?
  @Published private(set) var mode: ContextMode = .general

  private var observer: NSObjectProtocol?

  func start() {
    guard observer == nil else { return }
    update(with: NSWorkspace.shared.frontmostApplication)
    observer = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didActivateApplicationNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      let app =
        notification.userInfo?[
          NSWorkspace.applicationUserInfoKey
        ] as? NSRunningApplication
      MainActor.assumeIsolated {
        self?.update(with: app)
      }
    }
  }

  func stop() {
    guard let observer else { return }
    NSWorkspace.shared.notificationCenter.removeObserver(observer)
    self.observer = nil
  }

  private func update(with app: NSRunningApplication?) {
    activeApplicationName = app?.localizedName ?? "Mac"
    activeBundleIdentifier = app?.bundleIdentifier
    mode = Self.mode(
      for: app?.bundleIdentifier,
      name: app?.localizedName
    )
  }

  private static func mode(for bundleID: String?, name: String?) -> ContextMode {
    let value = "\(bundleID ?? "") \(name ?? "")".lowercased()

    if [
      "chrome", "safari", "firefox", "arc", "browser", "brave",
    ].contains(where: value.contains) {
      return .browser
    }
    if [
      "xcode", "visual studio code", "vscode", "terminal", "iterm",
      "warp", "cursor", "zed",
    ].contains(where: value.contains) {
      return .development
    }
    if [
      "slack", "teams", "zoom", "discord", "messages", "mail",
    ].contains(where: value.contains) {
      return .communication
    }
    if [
      "spotify", "music", "podcast", "vlc",
    ].contains(where: value.contains) {
      return .media
    }
    if [
      "figma", "sketch", "photoshop", "illustrator", "affinity",
    ].contains(where: value.contains) {
      return .design
    }
    return .general
  }
}
