import Carbon.HIToolbox
import Foundation

enum GlobalHotKeyAction: UInt32 {
  case toggleIsland = 1
  case showClipboard = 2
}

@MainActor
final class GlobalHotKeyManager {
  var actionHandler: ((GlobalHotKeyAction) -> Void)?

  private var eventHandler: EventHandlerRef?
  private var hotKeyReferences: [EventHotKeyRef] = []

  func registerDefaults() {
    installHandlerIfNeeded()
    register(.toggleIsland, keyCode: UInt32(kVK_Space), modifiers: UInt32(optionKey))
    register(
      .showClipboard,
      keyCode: UInt32(kVK_ANSI_V),
      modifiers: UInt32(controlKey | optionKey)
    )
  }

  private func installHandlerIfNeeded() {
    guard eventHandler == nil else { return }
    var eventType = EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard),
      eventKind: UInt32(kEventHotKeyPressed)
    )
    let userData = Unmanaged.passUnretained(self).toOpaque()
    InstallEventHandler(
      GetApplicationEventTarget(),
      { _, event, userData -> OSStatus in
        guard let event, let userData else { return noErr }
        var hotKeyID = EventHotKeyID(signature: 0, id: 0)
        let status = GetEventParameter(
          event,
          EventParamName(kEventParamDirectObject),
          EventParamType(typeEventHotKeyID),
          nil,
          MemoryLayout<EventHotKeyID>.size,
          nil,
          &hotKeyID
        )
        guard
          status == noErr,
          let action = GlobalHotKeyAction(rawValue: hotKeyID.id)
        else {
          return status
        }
        let manager = Unmanaged<GlobalHotKeyManager>
          .fromOpaque(userData)
          .takeUnretainedValue()
        Task { @MainActor in
          manager.actionHandler?(action)
        }
        return noErr
      },
      1,
      &eventType,
      userData,
      &eventHandler
    )
  }

  private func register(
    _ action: GlobalHotKeyAction,
    keyCode: UInt32,
    modifiers: UInt32
  ) {
    var reference: EventHotKeyRef?
    let signature = OSType(
      UInt32(ascii: "N") << 24
        | UInt32(ascii: "L") << 16
        | UInt32(ascii: "O") << 8
        | UInt32(ascii: "P")
    )
    let id = EventHotKeyID(signature: signature, id: action.rawValue)
    if RegisterEventHotKey(
      keyCode,
      modifiers,
      id,
      GetApplicationEventTarget(),
      0,
      &reference
    ) == noErr, let reference {
      hotKeyReferences.append(reference)
    }
  }
}

extension UInt32 {
  fileprivate init(ascii character: Character) {
    self = character.asciiValue.map(UInt32.init) ?? 0
  }
}
