import Foundation

enum IslandTab: String, CaseIterable, Identifiable {
  case home
  case clipboard
  case files
  case focus
  case calendar

  var id: String { rawValue }

  var title: String {
    switch self {
    case .home: "Home"
    case .clipboard: "Clipboard"
    case .files: "Files"
    case .focus: "Focus"
    case .calendar: "Calendar"
    }
  }
}

/// User-facing state shared by the compact and expanded island.
@MainActor
final class NotchModel: ObservableObject {
  @Published var isExpanded = false
  @Published var isPinned = false
  @Published var selectedTab: IslandTab = .home

  let settings = AppSettings()
  let clipboard = ClipboardHistoryStore()
  let files = FileShelfStore()
  let focus = FocusTimer()
  let calendar = CalendarMonitor()

  private var collapseTask: Task<Void, Never>?

  func startServices() {
    if settings.enableClipboard {
      clipboard.start()
    }
    if settings.enableCalendar {
      calendar.start()
    }
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

  func togglePinned() {
    isPinned.toggle()
    if isPinned {
      expand()
    }
  }
}
