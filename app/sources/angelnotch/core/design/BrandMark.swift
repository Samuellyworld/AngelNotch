import AppKit
import SwiftUI

/// the single continuous loop used by the app icon, island, and menu-bar item.
struct AngelNotchMarkShape: Shape {
  func path(in rect: CGRect) -> Path {
    let x = rect.minX
    let y = rect.minY
    let w = rect.width
    let h = rect.height

    var path = Path()
    path.move(to: CGPoint(x: x + w * 0.50, y: y + h * 0.50))
    path.addCurve(
      to: CGPoint(x: x + w * 0.24, y: y + h * 0.78),
      control1: CGPoint(x: x + w * 0.40, y: y + h * 0.24),
      control2: CGPoint(x: x + w * 0.31, y: y + h * 0.13)
    )
    path.addCurve(
      to: CGPoint(x: x + w * 0.50, y: y + h * 0.50),
      control1: CGPoint(x: x + w * 0.07, y: y + h * 0.78),
      control2: CGPoint(x: x + w * 0.10, y: y + h * 0.25)
    )
    path.addCurve(
      to: CGPoint(x: x + w * 0.76, y: y + h * 0.22),
      control1: CGPoint(x: x + w * 0.60, y: y + h * 0.76),
      control2: CGPoint(x: x + w * 0.69, y: y + h * 0.87)
    )
    path.addCurve(
      to: CGPoint(x: x + w * 0.50, y: y + h * 0.50),
      control1: CGPoint(x: x + w * 0.93, y: y + h * 0.22),
      control2: CGPoint(x: x + w * 0.90, y: y + h * 0.75)
    )
    return path
  }
}

enum AngelNotchBrand {
  static func statusItemImage() -> NSImage {
    let size = NSSize(width: 19, height: 16)
    let image = NSImage(size: size, flipped: false) { rect in
      NSColor.black.setStroke()

      let path = NSBezierPath()
      path.move(to: CGPoint(x: rect.width * 0.50, y: rect.height * 0.50))
      path.curve(
        to: CGPoint(x: rect.width * 0.24, y: rect.height * 0.22),
        controlPoint1: CGPoint(x: rect.width * 0.40, y: rect.height * 0.76),
        controlPoint2: CGPoint(x: rect.width * 0.31, y: rect.height * 0.87)
      )
      path.curve(
        to: CGPoint(x: rect.width * 0.50, y: rect.height * 0.50),
        controlPoint1: CGPoint(x: rect.width * 0.07, y: rect.height * 0.22),
        controlPoint2: CGPoint(x: rect.width * 0.10, y: rect.height * 0.75)
      )
      path.curve(
        to: CGPoint(x: rect.width * 0.76, y: rect.height * 0.78),
        controlPoint1: CGPoint(x: rect.width * 0.60, y: rect.height * 0.24),
        controlPoint2: CGPoint(x: rect.width * 0.69, y: rect.height * 0.13)
      )
      path.curve(
        to: CGPoint(x: rect.width * 0.50, y: rect.height * 0.50),
        controlPoint1: CGPoint(x: rect.width * 0.93, y: rect.height * 0.78),
        controlPoint2: CGPoint(x: rect.width * 0.90, y: rect.height * 0.25)
      )
      path.lineWidth = 1.8
      path.lineCapStyle = .round
      path.lineJoinStyle = .round
      path.stroke()
      return true
    }
    image.isTemplate = true
    image.accessibilityDescription = "AngelNotch"
    return image
  }
}
