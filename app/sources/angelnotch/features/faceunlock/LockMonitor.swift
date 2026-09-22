import AppKit
import Combine
import CoreGraphics
import Foundation
import OSLog

enum LockEventKind: String {
  case screenLocked
  case screenUnlocked
  case willSleep
  case wake
}

final class LockMonitor: ObservableObject, @unchecked Sendable {
  private static let logger = Logger(subsystem: "com.angelnotch.mac", category: "FaceUnlock")

  @Published private(set) var isScreenLocked: Bool = false

  @Published private(set) var wakeEventCount: Int = 0

  @Published private(set) var isSleeping: Bool = false

  @Published private(set) var lastEvent: LockEventKind?
  @Published private(set) var eventCount: Int = 0

  private var distributedObservers: [NSObjectProtocol] = []
  private var workspaceObservers: [NSObjectProtocol] = []

  init() {
    startMonitoring()
  }

  deinit {
    let distributed = DistributedNotificationCenter.default()
    for observer in distributedObservers {
      distributed.removeObserver(observer)
    }
    let workspace = NSWorkspace.shared.notificationCenter
    for observer in workspaceObservers {
      workspace.removeObserver(observer)
    }
  }

  private func startMonitoring() {
    let distributed = DistributedNotificationCenter.default()
    distributedObservers.append(
      distributed.addObserver(
        forName: Notification.Name("com.apple.screenIsLocked"),
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.isScreenLocked = true
        self?.record(.screenLocked)
      })
    distributedObservers.append(
      distributed.addObserver(
        forName: Notification.Name("com.apple.screenIsUnlocked"),
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.isScreenLocked = false
        self?.record(.screenUnlocked)
      })
    distributedObservers.append(
      distributed.addObserver(
        forName: Notification.Name("com.apple.screensaver.didstop"),
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.record(.wake)
      })

    let workspace = NSWorkspace.shared.notificationCenter
    workspaceObservers.append(
      workspace.addObserver(
        forName: NSWorkspace.willSleepNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.isSleeping = true
        self?.record(.willSleep)
      })
    workspaceObservers.append(
      workspace.addObserver(
        forName: NSWorkspace.screensDidWakeNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.recordWake()
      })
    workspaceObservers.append(
      workspace.addObserver(
        forName: NSWorkspace.didWakeNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.recordWake()
      })
  }

  private func recordWake() {
    isSleeping = false
    wakeEventCount += 1
    record(.wake)
  }

  private func record(_ kind: LockEventKind) {
    lastEvent = kind
    eventCount += 1
    Self.logger.info(
      "lock event=\(kind.rawValue, privacy: .public) locked=\(Self.isScreenActuallyLocked()) sleeping=\(self.isSleeping)"
    )
  }

  nonisolated static func isScreenActuallyLocked() -> Bool {
    guard let dict = CGSessionCopyCurrentDictionary() as? [String: Any] else {
      return false
    }
    return (dict["CGSSessionScreenIsLocked"] as? Bool) ?? false
  }
}
