import Foundation

/// User-facing state shared by the compact and expanded island.
@MainActor
final class NotchModel: ObservableObject {
  @Published var isExpanded = false
  @Published var isPinned = false

  let settings = AppSettings()

  private var collapseTask: Task<Void, Never>?

  func expand() {
    collapseTask?.cancel()
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
