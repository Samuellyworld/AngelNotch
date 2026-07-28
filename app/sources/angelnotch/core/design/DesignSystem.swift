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

    static let textPrimary = cream
    static let textSecondary = cream.opacity(0.58)
    static let textTertiary = cream.opacity(0.36)
  }

  enum Geometry {
    static let compactHeight: CGFloat = 40
    static let compactMinimumWidth: CGFloat = 278
    static let compactNotchPadding: CGFloat = 92
    static let expandedWidth: CGFloat = 548
    static let expandedHeight: CGFloat = 380
    static let compactRadius: CGFloat = 20
    static let expandedRadius: CGFloat = 34
  }

  enum TypeStyle {
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
  func interactiveCursor() -> some View {
    modifier(InteractiveCursorModifier())
  }
}
