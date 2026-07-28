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
    case .cyan: Color(red: 0.52, green: 0.70, blue: 0.70)
    case .coral: LoopDesign.Palette.accent
    case .violet: Color(red: 0.64, green: 0.58, blue: 0.73)
    case .mint: Color(red: 0.58, green: 0.70, blue: 0.62)
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
  @Published var enableClipboard: Bool {
    didSet { defaults.set(enableClipboard, forKey: "features.clipboard") }
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

    enableClipboard =
      defaults.object(forKey: "features.clipboard") as? Bool
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
      }

      Section("Global shortcuts") {
        LabeledContent("Open AngelNotch", value: "⌥ Space")
        LabeledContent("Clipboard history", value: "⌃⌥ V")
      }
    }
    .formStyle(.grouped)
    .padding()
    .frame(width: 500, height: 480)
    .preferredColorScheme(.dark)
  }
}
