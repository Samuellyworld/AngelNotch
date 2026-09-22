import ApplicationServices
import CoreGraphics
import Foundation

enum KeystrokeError: LocalizedError {
  case accessibilityNotGranted
  case eventCreationFailed

  var errorDescription: String? {
    switch self {
    case .accessibilityNotGranted:
      return
        "Accessibility permission required. Open System Settings → Privacy & Security → Accessibility and enable AngelNotch."
    case .eventCreationFailed:
      return "Couldn't create CGEvent for keystroke."
    }
  }
}

enum KeystrokeInjector {
  nonisolated static func isAccessibilityTrusted() -> Bool {
    return AXIsProcessTrusted()
  }

  @discardableResult
  nonisolated static func promptForAccessibility() -> Bool {
    let promptKey = "AXTrustedCheckOptionPrompt" as CFString
    let options = [promptKey: true] as CFDictionary
    return AXIsProcessTrustedWithOptions(options)
  }

  nonisolated static func typeAndReturn(_ passwordBytes: Data) throws {
    guard isAccessibilityTrusted() else {
      throw KeystrokeError.accessibilityNotGranted
    }
    guard let text = String(data: passwordBytes, encoding: .utf8) else {
      throw KeystrokeError.eventCreationFailed
    }
    let source = CGEventSource(stateID: .hidSystemState)
    try clearFocusedField(source: source)
    for char in text {
      try postUnicode(String(char), source: source)
    }
    try postReturn(source: source)
  }

  private nonisolated static func clearFocusedField(source: CGEventSource?) throws {
    let rightArrow: CGKeyCode = 0x7C
    let delete: CGKeyCode = 0x33
    try postKey(rightArrow, flags: .maskCommand, source: source)
    try postKey(delete, flags: .maskCommand, source: source)
  }

  private nonisolated static func postKey(
    _ keyCode: CGKeyCode, flags: CGEventFlags = [], source: CGEventSource?
  ) throws {
    let command: CGKeyCode = 0x37
    let usesCommand = flags.contains(.maskCommand)
    if usesCommand {
      guard
        let commandDown = CGEvent(keyboardEventSource: source, virtualKey: command, keyDown: true)
      else {
        throw KeystrokeError.eventCreationFailed
      }
      commandDown.flags = .maskCommand
      commandDown.post(tap: .cghidEventTap)
      Thread.sleep(forTimeInterval: 0.012)
    }
    guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
      let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
    else {
      throw KeystrokeError.eventCreationFailed
    }
    keyDown.flags = flags
    keyUp.flags = flags
    keyDown.post(tap: .cghidEventTap)
    Thread.sleep(forTimeInterval: 0.012)
    keyUp.post(tap: .cghidEventTap)
    Thread.sleep(forTimeInterval: 0.012)
    if usesCommand {
      guard
        let commandUp = CGEvent(keyboardEventSource: source, virtualKey: command, keyDown: false)
      else {
        throw KeystrokeError.eventCreationFailed
      }
      commandUp.flags = []
      commandUp.post(tap: .cghidEventTap)
      Thread.sleep(forTimeInterval: 0.012)
    }
  }

  private nonisolated static func postUnicode(_ unicode: String, source: CGEventSource?) throws {
    let utf16 = Array(unicode.utf16)
    guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
      let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
    else {
      throw KeystrokeError.eventCreationFailed
    }
    utf16.withUnsafeBufferPointer { buf in
      if let base = buf.baseAddress {
        keyDown.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: base)
        keyUp.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: base)
      }
    }
    keyDown.post(tap: .cghidEventTap)
    Thread.sleep(forTimeInterval: 0.012)
    keyUp.post(tap: .cghidEventTap)
    Thread.sleep(forTimeInterval: 0.012)
  }

  private nonisolated static func postReturn(source: CGEventSource?) throws {
    let returnKey: CGKeyCode = 0x24
    guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: returnKey, keyDown: true),
      let keyUp = CGEvent(keyboardEventSource: source, virtualKey: returnKey, keyDown: false)
    else {
      throw KeystrokeError.eventCreationFailed
    }
    keyDown.post(tap: .cghidEventTap)
    Thread.sleep(forTimeInterval: 0.012)
    keyUp.post(tap: .cghidEventTap)
  }
}
