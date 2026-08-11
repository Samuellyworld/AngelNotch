import AppKit
import SwiftUI

/// Shared visual tokens for every AngelNotch surface.
enum LoopDesign {
  enum Palette {
    static let canvas = Color(red: 0.035, green: 0.035, blue: 0.032)
    static let surface = Color(red: 0.95, green: 0.93, blue: 0.89).opacity(0.085)
    static let surfaceQuiet = Color(red: 0.95, green: 0.93, blue: 0.89).opacity(0.050)
    static let surfaceRaised = Color(red: 0.95, green: 0.93, blue: 0.89).opacity(0.12)
    static let outline = Color(red: 0.95, green: 0.93, blue: 0.89).opacity(0.11)

    static let accent = Color(red: 0.91, green: 0.52, blue: 0.38)
    static let cream = Color(red: 0.95, green: 0.93, blue: 0.89)
    static let cyan = Color(red: 0.52, green: 0.70, blue: 0.70)
    static let blue = Color(red: 0.48, green: 0.60, blue: 0.76)
    static let mint = Color(red: 0.58, green: 0.70, blue: 0.62)
    static let coral = accent
    static let sun = Color(red: 0.82, green: 0.67, blue: 0.42)
    static let violet = Color(red: 0.64, green: 0.58, blue: 0.73)
    static let spotify = Color(red: 0.12, green: 0.84, blue: 0.38)
    static let appleMusic = Color(red: 1.00, green: 0.24, blue: 0.48)
    static let call = Color(red: 0.22, green: 0.84, blue: 0.42)

    static let textPrimary = cream
    static let textSecondary = cream.opacity(0.58)
    static let textTertiary = cream.opacity(0.36)

    static let brandGradient = LinearGradient(
      colors: [accent, Color(red: 0.76, green: 0.39, blue: 0.30)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )

  }

  enum Geometry {
    static let compactHeight: CGFloat = 40
    // Leaves comfortable optical space around compact state icons.
    static let compactMinimumWidth: CGFloat = 324
    static let compactNotchPadding: CGFloat = 92
    static let expandedWidth: CGFloat = 548
    static let expandedHeight: CGFloat = 380
    static let mediaExpandedHeight: CGFloat = 306

    static let compactRadius: CGFloat = 20
    static let expandedRadius: CGFloat = 34
    static let capsuleControlHeight: CGFloat = 50
    static let largeControl: CGFloat = 40
    static let standardControl: CGFloat = 32
    static let minimumTarget: CGFloat = 28
  }

  enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 20
    static let panelInset: CGFloat = 8
  }

  enum TypeStyle {
    static let eyebrow = Font.system(size: 10, weight: .medium)
    static let title = Font.system(size: 14, weight: .medium)
    static let label = Font.system(size: 11, weight: .regular)
    static let detail = Font.system(size: 10, weight: .regular)
    static let display = Font.system(size: 22, weight: .medium)
  }

  enum Motion {
    static let morph = Animation.spring(response: 0.28, dampingFraction: 0.88)
    static let hover = Animation.spring(response: 0.18, dampingFraction: 0.84)
    static let windowDuration = 0.15
    static let hoverCollapseDelay = Duration.milliseconds(420)
    static let mediaPresentationDuration = Duration.seconds(3)
  }
}

private struct InteractiveCursorModifier: ViewModifier {
  func body(content: Content) -> some View {
    content.onContinuousHover { phase in
      switch phase {
      case .active:
        NSCursor.pointingHand.set()
      case .ended:
        NSCursor.arrow.set()
      }
    }
  }
}

extension View {
  /// Gives controls the familiar web-style pointer when they become actionable.
  func interactiveCursor() -> some View {
    modifier(InteractiveCursorModifier())
  }
}

enum LoopBatteryStyle {
  static func symbol(level: Double) -> String {
    switch max(0, min(1, level)) {
    case 0.875...: "battery.100"
    case 0.625...: "battery.75"
    case 0.375...: "battery.50"
    case 0.125...: "battery.25"
    default: "battery.0"
    }
  }

  static func color(
    level: Double,
    charging: Bool,
    lowPowerMode: Bool
  ) -> Color {
    if charging {
      return LoopDesign.Palette.mint
    }
    if lowPowerMode {
      return LoopDesign.Palette.sun
    }
    if level <= 0.20 {
      return LoopDesign.Palette.coral
    }
    return LoopDesign.Palette.textSecondary
  }

  static func detail(
    charging: Bool,
    powerConnected: Bool,
    lowPowerMode: Bool,
    minutesRemaining: Int?
  ) -> String? {
    if charging {
      if let minutesRemaining {
        return "\(duration(minutesRemaining)) to full"
      }
      return "Charging"
    }
    if lowPowerMode {
      return "Low Power"
    }
    if powerConnected {
      return "Power connected"
    }
    if let minutesRemaining {
      return "\(duration(minutesRemaining)) remaining"
    }
    return nil
  }

  private static func duration(_ minutes: Int) -> String {
    let hours = minutes / 60
    let remainder = minutes % 60
    if hours == 0 {
      return "\(remainder)m"
    }
    return remainder == 0 ? "\(hours)h" : "\(hours)h \(remainder)m"
  }
}
