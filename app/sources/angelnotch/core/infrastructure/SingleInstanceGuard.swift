import AppKit
import Darwin
import Foundation

/// keeps one AngelNotch process alive across app copies and release locations.
@MainActor
final class SingleInstanceGuard {
  private var lockFileDescriptor: Int32 = -1

  func acquire() -> Bool {
    guard lockFileDescriptor == -1 else { return true }

    let lockURL = StoragePaths.root.appending(path: "instance.lock")
    let fileDescriptor = Darwin.open(
      lockURL.path,
      O_CREAT | O_RDWR,
      S_IRUSR | S_IWUSR
    )

    // failing open is safer than making the app unusable because its data
    // directory is temporarily unavailable.
    guard fileDescriptor >= 0 else { return true }

    guard flock(fileDescriptor, LOCK_EX | LOCK_NB) == 0 else {
      Darwin.close(fileDescriptor)
      activateRunningInstance()
      return false
    }

    lockFileDescriptor = fileDescriptor
    return true
  }

  private func activateRunningInstance() {
    guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }

    NSRunningApplication.runningApplications(
      withBundleIdentifier: bundleIdentifier
    )
    .first {
      $0.processIdentifier != ProcessInfo.processInfo.processIdentifier
    }?
    .activate(options: [.activateAllWindows])
  }

  deinit {
    guard lockFileDescriptor >= 0 else { return }
    flock(lockFileDescriptor, LOCK_UN)
    Darwin.close(lockFileDescriptor)
  }
}
