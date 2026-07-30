import AngelNotchServiceBridge
import AppKit
import SwiftUI

enum AccentChoice: String, CaseIterable, Identifiable {
  case spectrum
  case cyan
  case coral
  case violet
  case mint

  var id: String { rawValue }

  var title: String {
    switch self {
    case .spectrum: "Clay"
    case .cyan: "Mist"
    case .coral: "Rose"
    case .violet: "Dusk"
    case .mint: "Sage"
    }
  }

  var color: Color {
    switch self {
    case .spectrum: LoopDesign.Palette.accent
    case .cyan: LoopDesign.Palette.cyan
    case .coral: LoopDesign.Palette.coral
    case .violet: LoopDesign.Palette.violet
    case .mint: LoopDesign.Palette.mint
    }
  }
}

@MainActor
final class AppSettings: ObservableObject {
  @Published var islandScale: Double {
    didSet { defaults.set(islandScale, forKey: "appearance.islandScale") }
  }
  @Published var animationSpeed: Double {
    didSet { defaults.set(animationSpeed, forKey: "appearance.animationSpeed") }
  }
  @Published var accent: AccentChoice {
    didSet { defaults.set(accent.rawValue, forKey: "appearance.accent") }
  }
  @Published var autoExpandMedia: Bool {
    didSet { defaults.set(autoExpandMedia, forKey: "features.autoExpandMedia") }
  }
  @Published var enableClipboard: Bool {
    didSet { defaults.set(enableClipboard, forKey: "features.clipboard") }
  }
  @Published var enableSystemHUDs: Bool {
    didSet { defaults.set(enableSystemHUDs, forKey: "features.systemHUDs") }
  }
  @Published var enableCalendar: Bool {
    didSet { defaults.set(enableCalendar, forKey: "features.calendar") }
  }
  @Published var enableContextModes: Bool {
    didSet { defaults.set(enableContextModes, forKey: "features.contextModes") }
  }
  @Published var enableReducedMotion: Bool {
    didSet { defaults.set(enableReducedMotion, forKey: "appearance.reducedMotion") }
  }
  @Published private(set) var launchAtLogin = false
  @Published private(set) var launchAtLoginError: String?

  private let defaults = UserDefaults.standard

  init() {
    let scale = defaults.double(forKey: "appearance.islandScale")
    islandScale = scale == 0 ? 1 : scale
    let speed = defaults.double(forKey: "appearance.animationSpeed")
    animationSpeed = speed == 0 ? 1 : speed
    accent =
      AccentChoice(
        rawValue: defaults.string(forKey: "appearance.accent") ?? ""
      ) ?? .spectrum

    autoExpandMedia =
      defaults.object(forKey: "features.autoExpandMedia") as? Bool
      ?? false
    enableClipboard =
      defaults.object(forKey: "features.clipboard") as? Bool
      ?? true
    enableSystemHUDs =
      defaults.object(forKey: "features.systemHUDs") as? Bool
      ?? true
    enableCalendar =
      defaults.object(forKey: "features.calendar") as? Bool
      ?? true
    enableContextModes =
      defaults.object(forKey: "features.contextModes") as? Bool
      ?? true
    enableReducedMotion =
      defaults.object(
        forKey: "appearance.reducedMotion"
      ) as? Bool ?? false
    launchAtLogin = ANLaunchAtLoginIsEnabled()
  }

  func setLaunchAtLogin(_ enabled: Bool) {
    if ANSetLaunchAtLoginEnabled(enabled) {
      launchAtLoginError = nil
      if ANLaunchAtLoginRequiresApproval() {
        launchAtLoginError = "Approve AngelNotch in System Settings → General → Login Items."
      }
    } else if let message = ANLaunchAtLoginLastError() {
      launchAtLoginError = String(cString: message)
    }
    launchAtLogin = ANLaunchAtLoginIsEnabled()
  }

  func openDataFolder() {
    NSWorkspace.shared.open(StoragePaths.root)
  }

  var versionLabel: String {
    let version =
      Bundle.main.object(
        forInfoDictionaryKey: "CFBundleShortVersionString"
      ) as? String ?? "Development"
    let build =
      Bundle.main.object(
        forInfoDictionaryKey: "CFBundleVersion"
      ) as? String
    return build.map { "\(version) (\($0))" } ?? version
  }
}

struct AngelNotchSettingsView: View {
  @ObservedObject var settings: AppSettings
  @ObservedObject var focus: FocusTimer
  @ObservedObject var files: FileShelfStore

  var body: some View {
    Form {
      Section("AngelNotch") {
        Toggle(
          "Launch at login",
          isOn: Binding(
            get: { settings.launchAtLogin },
            set: { enabled in
              settings.setLaunchAtLogin(enabled)
            }
          )
        )
        if let error = settings.launchAtLoginError {
          Text(error)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        LabeledContent("Version", value: settings.versionLabel)
        Button("Open local data folder", systemImage: "folder") {
          settings.openDataFolder()
        }
      }

      Section("Appearance") {
        Slider(
          value: $settings.islandScale,
          in: 0.85...1.25,
          step: 0.05
        ) {
          Text("Island size")
        }
        LabeledContent("Island size") {
          Text("\(Int(settings.islandScale * 100))%")
        }

        Slider(
          value: $settings.animationSpeed,
          in: 0.65...1.5,
          step: 0.05
        ) {
          Text("Animation speed")
        }

        Picker("Accent", selection: $settings.accent) {
          ForEach(AccentChoice.allCases) { accent in
            Label(accent.title, systemImage: "circle.fill")
              .foregroundStyle(accent.color)
              .tag(accent)
          }
        }
        Toggle("Reduce motion", isOn: $settings.enableReducedMotion)
      }

      Section("Widgets") {
        Toggle("Clipboard history", isOn: $settings.enableClipboard)
        Toggle("System HUDs", isOn: $settings.enableSystemHUDs)
        Toggle("Calendar", isOn: $settings.enableCalendar)
        Toggle("Context modes", isOn: $settings.enableContextModes)
        Toggle("Expand for track changes", isOn: $settings.autoExpandMedia)
      }

      Section("Focus timer") {
        Toggle(
          "Announce with the Idera voice",
          isOn: $focus.completionSoundEnabled
        )
        Stepper(
          "Focus: \(focus.focusMinutes) minutes",
          value: $focus.focusMinutes,
          in: 5...90,
          step: 5
        )
        Stepper(
          "Short break: \(focus.shortBreakMinutes) minutes",
          value: $focus.shortBreakMinutes,
          in: 1...30
        )
        Stepper(
          "Long break: \(focus.longBreakMinutes) minutes",
          value: $focus.longBreakMinutes,
          in: 5...45,
          step: 5
        )
      }

      Section("File shelf") {
        Picker("Automatic cleanup", selection: $files.cleanupAfterDays) {
          Text("After 1 day").tag(1)
          Text("After 7 days").tag(7)
          Text("After 14 days").tag(14)
          Text("After 30 days").tag(30)
          Text("After 90 days").tag(90)
        }
      }

      Section("Global shortcuts") {
        LabeledContent("Open AngelNotch", value: "⌥ Space")
        LabeledContent("Clipboard history", value: "⌃⌥ V")
        LabeledContent("Screenshot", value: "⌃⌥ S")
      }
    }
    .formStyle(.grouped)
    .padding()
    .frame(width: 500, height: 680)
    .preferredColorScheme(.dark)
  }
}
