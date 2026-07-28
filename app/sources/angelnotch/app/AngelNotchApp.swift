import AppKit
import SwiftUI

@main
struct AngelNotchApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    Settings {
      EmptyView()
    }
  }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private let singleInstanceGuard = SingleInstanceGuard()
  private var coordinator: NotchCoordinator?
  private var statusItem: NSStatusItem?

  func applicationDidFinishLaunching(_ notification: Notification) {
    guard singleInstanceGuard.acquire() else {
      NSApp.terminate(nil)
      return
    }

    NSApp.setActivationPolicy(.accessory)

    let coordinator = NotchCoordinator()
    coordinator.start()
    self.coordinator = coordinator

    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    item.button?.image = AngelNotchBrand.statusItemImage()

    let menu = NSMenu()
    let showItem = NSMenuItem(
      title: "Show AngelNotch",
      action: #selector(showAngelNotch),
      keyEquivalent: ""
    )
    showItem.target = self
    menu.addItem(showItem)

    let clipboardItem = NSMenuItem(
      title: "Clipboard History",
      action: #selector(showClipboard),
      keyEquivalent: ""
    )
    clipboardItem.target = self
    menu.addItem(clipboardItem)

    let settingsItem = NSMenuItem(
      title: "Settings…",
      action: #selector(showSettings),
      keyEquivalent: ","
    )
    settingsItem.target = self
    menu.addItem(settingsItem)
    menu.addItem(.separator())

    let quitItem = NSMenuItem(
      title: "Quit AngelNotch",
      action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q"
    )
    quitItem.target = NSApp
    menu.addItem(quitItem)

    item.menu = menu
    statusItem = item
  }

  @objc private func showAngelNotch() {
    coordinator?.showAndExpand()
  }

  @objc private func showClipboard() {
    coordinator?.showAndExpand(tab: .clipboard)
  }

  @objc private func showSettings() {
    coordinator?.openSettings()
  }
}
