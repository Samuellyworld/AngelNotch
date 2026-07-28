import AppKit
import Combine
import SwiftUI

/// Owns the floating island window and keeps it aligned with the active display.
@MainActor
final class NotchCoordinator {
  let model = NotchModel()

  private let panel = NotchPanel()
  private let hotKeys = GlobalHotKeyManager()
  private var subscriptions = Set<AnyCancellable>()
  private var screenObserver: NSObjectProtocol?
  private var settingsWindow: NSWindow?

  func start() {
    let hostingView = NotchTrackingHostingView(
      rootView: NotchRootView(model: model)
    )
    hostingView.wantsLayer = true
    hostingView.layer?.backgroundColor = NSColor.clear.cgColor
    hostingView.hoverHandler = { [weak self] hovering in
      guard let self else { return }
      if hovering {
        model.expand()
      } else {
        model.requestCollapse()
      }
    }
    panel.contentView = hostingView
    panel.orderFrontRegardless()
    movePanel(expanded: false)
    configureHotKeys()

    model.$isExpanded
      .removeDuplicates()
      .sink { [weak self] expanded in
        self?.movePanel(expanded: expanded, animated: true)
      }
      .store(in: &subscriptions)

    model.settings.$islandScale
      .combineLatest(model.settings.$animationSpeed)
      .dropFirst()
      .sink { [weak self] _, _ in
        guard let self else { return }
        movePanel(expanded: model.isExpanded, animated: true)
      }
      .store(in: &subscriptions)

    screenObserver = NotificationCenter.default.addObserver(
      forName: NSApplication.didChangeScreenParametersNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated {
        guard let self else { return }
        self.movePanel(expanded: self.model.isExpanded)
      }
    }
  }

  func showAndExpand() {
    panel.orderFrontRegardless()
    model.expand()
  }

  func openSettings() {
    if let settingsWindow {
      settingsWindow.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
      return
    }

    let view = AngelNotchSettingsView(settings: model.settings)
    let controller = NSHostingController(rootView: view)
    let window = NSWindow(contentViewController: controller)
    window.title = "AngelNotch Settings"
    window.appearance = NSAppearance(named: .darkAqua)
    window.styleMask = [.titled, .closable, .miniaturizable]
    window.setContentSize(NSSize(width: 500, height: 480))
    window.center()
    window.isReleasedWhenClosed = false
    window.makeKeyAndOrderFront(nil)
    settingsWindow = window
    NSApp.activate(ignoringOtherApps: true)
  }

  private func configureHotKeys() {
    hotKeys.actionHandler = { [weak self] action in
      guard let self else { return }
      switch action {
      case .toggleIsland:
        panel.orderFrontRegardless()
        model.toggleExpanded()
      }
    }
    hotKeys.registerDefaults()
  }

  private func movePanel(expanded: Bool, animated: Bool = false) {
    let screen = targetScreen()
    let scale = CGFloat(model.settings.islandScale)
    let size =
      expanded
      ? NSSize(
        width: LoopDesign.Geometry.expandedWidth * scale,
        height: LoopDesign.Geometry.expandedHeight * scale
      )
      : NSSize(
        width: compactWidth(for: screen) * scale,
        height: LoopDesign.Geometry.compactHeight * scale
      )

    let origin = NSPoint(
      x: screen.frame.midX - (size.width / 2),
      y: screen.frame.maxY - size.height
    )
    let frame = NSRect(origin: origin, size: size)

    if animated && !model.settings.enableReducedMotion {
      NSAnimationContext.runAnimationGroup { context in
        context.duration =
          LoopDesign.Motion.windowDuration
          / model.settings.animationSpeed
        context.timingFunction = CAMediaTimingFunction(
          name: expanded ? .easeOut : .easeIn
        )
        panel.animator().setFrame(frame, display: true)
      }
    } else {
      panel.setFrame(frame, display: true)
    }
  }

  private func targetScreen() -> NSScreen {
    let mouseLocation = NSEvent.mouseLocation
    return NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) })
      ?? NSScreen.main
      ?? NSScreen.screens[0]
  }

  private func compactWidth(for screen: NSScreen) -> CGFloat {
    guard
      let leftArea = screen.auxiliaryTopLeftArea,
      let rightArea = screen.auxiliaryTopRightArea,
      !leftArea.isEmpty,
      !rightArea.isEmpty
    else {
      return LoopDesign.Geometry.compactMinimumWidth
    }

    let physicalNotchWidth = max(0, rightArea.minX - leftArea.maxX)
    return max(
      LoopDesign.Geometry.compactMinimumWidth,
      physicalNotchWidth + LoopDesign.Geometry.compactNotchPadding
    )
  }
}

/// Tracks only the host-view boundary while the panel is resizing.
@MainActor
final class NotchTrackingHostingView<Content: View>: NSHostingView<Content> {
  var hoverHandler: ((Bool) -> Void)?
  private var boundaryTrackingArea: NSTrackingArea?

  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    if let boundaryTrackingArea {
      removeTrackingArea(boundaryTrackingArea)
    }
    let area = NSTrackingArea(
      rect: .zero,
      options: [
        .mouseEnteredAndExited,
        .activeAlways,
        .inVisibleRect,
      ],
      owner: self,
      userInfo: nil
    )
    addTrackingArea(area)
    boundaryTrackingArea = area
  }

  override func mouseEntered(with event: NSEvent) {
    hoverHandler?(true)
  }

  override func mouseExited(with event: NSEvent) {
    hoverHandler?(false)
  }
}

final class NotchPanel: NSPanel {
  init() {
    super.init(
      contentRect: .zero,
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )

    isOpaque = false
    backgroundColor = .clear
    appearance = NSAppearance(named: .darkAqua)
    hasShadow = false
    level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    isMovable = false
    hidesOnDeactivate = false
    animationBehavior = .utilityWindow
  }

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { false }
}
