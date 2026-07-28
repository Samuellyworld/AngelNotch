import AppKit
import Foundation

enum IslandTab: String, CaseIterable, Identifiable {
  case home
  case clipboard
  case files
  case focus
  case calendar
  case system
  case activities

  var id: String { rawValue }

  var title: String {
    switch self {
    case .home: "Home"
    case .clipboard: "Clipboard"
    case .files: "Files"
    case .focus: "Focus"
    case .calendar: "Calendar"
    case .system: "System"
    case .activities: "Live"
    }
  }

  var symbolName: String {
    switch self {
    case .home: "sparkles"
    case .clipboard: "doc.on.clipboard"
    case .files: "tray.full"
    case .focus: "timer"
    case .calendar: "calendar"
    case .system: "slider.horizontal.3"
    case .activities: "dot.radiowaves.left.and.right"
    }
  }
}

/// User-facing state and utility actions shared by the compact and expanded island.
@MainActor
final class NotchModel: ObservableObject {
  @Published var isExpanded = false
  @Published var isPinned = false
  @Published var selectedTab: IslandTab = .home
  @Published private(set) var visibleHUD: SystemHUDEvent?

  let settings = AppSettings()
  let media = MediaMonitor()
  let clipboard = ClipboardHistoryStore()
  let files = FileShelfStore()
  let focus = FocusTimer()
  let calendar = CalendarMonitor()
  let system = SystemMonitor()
  let context = ContextMonitor()
  let activities = LiveActivityCenter()

  private var collapseTask: Task<Void, Never>?
  private var hudTask: Task<Void, Never>?

  func startServices() {
    media.start()
    if settings.enableClipboard {
      clipboard.start()
    }
    if settings.enableCalendar {
      calendar.start()
    }
    system.start()
    if settings.enableContextModes {
      context.start()
    }
    activities.start()
  }

  func expand(tab: IslandTab? = nil) {
    collapseTask?.cancel()
    if let tab, selectedTab != tab {
      selectedTab = tab
    }
    guard !isExpanded else { return }
    isExpanded = true
  }

  func toggleExpanded() {
    isExpanded ? requestCollapse(immediately: true) : expand()
  }

  func requestCollapse(immediately: Bool = false) {
    guard !isPinned else { return }
    collapseTask?.cancel()

    if immediately {
      isExpanded = false
      return
    }

    collapseTask = Task { @MainActor [weak self] in
      try? await Task.sleep(for: LoopDesign.Motion.hoverCollapseDelay)
      guard !Task.isCancelled, self?.isPinned == false else { return }
      self?.isExpanded = false
    }
  }

  func presentMediaTemporarily() {
    guard settings.autoExpandMedia else { return }
    collapseTask?.cancel()
    selectedTab = .home
    isExpanded = true

    collapseTask = Task { @MainActor [weak self] in
      try? await Task.sleep(for: LoopDesign.Motion.mediaPresentationDuration)
      guard !Task.isCancelled, self?.isPinned == false else { return }
      self?.isExpanded = false
    }
  }

  func presentHUD(_ event: SystemHUDEvent) {
    guard settings.enableSystemHUDs else { return }
    visibleHUD = event
    hudTask?.cancel()
    let presentationDuration: Duration =
      if case .airPodsConnected = event.kind {
        .seconds(2.4)
      } else {
        .seconds(1.7)
      }
    hudTask = Task { @MainActor [weak self] in
      try? await Task.sleep(for: presentationDuration)
      guard !Task.isCancelled else { return }
      self?.visibleHUD = nil
    }
  }

  func togglePinned() {
    isPinned.toggle()
    if isPinned {
      expand()
    }
  }

  func openDownloads() {
    NSWorkspace.shared.open(
      FileManager.default.homeDirectoryForCurrentUser.appending(path: "Downloads")
    )
  }

  func takeScreenshot() {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    process.arguments = ["-i"]
    try? process.run()
  }

  func performPrimaryContextAction() {
    switch context.mode {
    case .browser:
      NSWorkspace.shared.open(URL(string: "https://www.google.com")!)
    case .development:
      openDownloads()
    case .communication:
      if let event = calendar.nextEvent, event.joinURL != nil {
        calendar.joinNextEvent()
      } else {
        expand(tab: .calendar)
      }
    case .media:
      media.send(.playPause)
    case .design:
      takeScreenshot()
    case .general:
      expand(tab: .clipboard)
    }
  }
}
