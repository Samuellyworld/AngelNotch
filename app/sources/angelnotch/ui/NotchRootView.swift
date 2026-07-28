import SwiftUI

/// The compact and expanded AngelNotch application shell.
struct NotchRootView: View {
  @ObservedObject var model: NotchModel
  @ObservedObject private var settings: AppSettings

  init(model: NotchModel) {
    self.model = model
    settings = model.settings
  }

  var body: some View {
    ZStack(alignment: .top) {
      islandShape

      if model.isExpanded {
        ExpandedFoundationView(model: model)
          .transition(
            .asymmetric(
              insertion: .opacity.combined(
                with: .scale(scale: 0.92, anchor: .top)
              ),
              removal: .opacity
            )
          )
      } else {
        CompactFoundationView(model: model)
          .transition(.opacity)
      }
    }
    .contentShape(Rectangle())
    .onTapGesture {
      if !model.isExpanded {
        model.expand()
      }
    }
    .interactiveCursor()
    .animation(
      settings.enableReducedMotion
        ? .easeOut(duration: 0.12)
        : LoopDesign.Motion.morph,
      value: model.isExpanded
    )
    .preferredColorScheme(.dark)
  }

  private var islandShape: some View {
    RoundedRectangle(
      cornerRadius: model.isExpanded
        ? LoopDesign.Geometry.expandedRadius
        : LoopDesign.Geometry.compactRadius,
      style: .continuous
    )
    .fill(LoopDesign.Palette.canvas)
    .overlay {
      RoundedRectangle(
        cornerRadius: model.isExpanded
          ? LoopDesign.Geometry.expandedRadius
          : LoopDesign.Geometry.compactRadius,
        style: .continuous
      )
      .strokeBorder(
        LoopDesign.Palette.outline.opacity(0.62),
        lineWidth: 0.5
      )
    }
  }
}

private struct CompactFoundationView: View {
  @ObservedObject var model: NotchModel

  var body: some View {
    HStack {
      LoopMiniMark()
      Spacer()
      Button {
        model.expand()
      } label: {
        Image(systemName: "chevron.down")
          .font(.system(size: 9, weight: .semibold))
          .foregroundStyle(LoopDesign.Palette.textSecondary)
          .frame(width: 24, height: 24)
      }
      .buttonStyle(.plain)
      .interactiveCursor()
      .help("Open AngelNotch")
    }
    .padding(.horizontal, 12)
    .frame(maxHeight: .infinity)
  }
}

private struct ExpandedFoundationView: View {
  @ObservedObject var model: NotchModel

  var body: some View {
    VStack(spacing: 14) {
      Color.clear.frame(height: 25)

      HStack(spacing: 10) {
        LoopMiniMark()
          .frame(width: 28, height: 20)

        Text("AngelNotch")
          .font(LoopDesign.TypeStyle.title)
          .foregroundStyle(LoopDesign.Palette.textPrimary)

        Spacer()

        LoopIconButton(
          symbol: model.isPinned ? "pin.fill" : "pin",
          active: model.isPinned,
          help: model.isPinned ? "Unpin island" : "Keep island open",
          action: model.togglePinned
        )
      }

      Spacer()

      AngelNotchMarkShape()
        .stroke(
          LoopDesign.Palette.accent,
          style: StrokeStyle(lineWidth: 4, lineCap: .round)
        )
        .frame(width: 64, height: 42)

      Text("Your Mac, at a glance.")
        .font(LoopDesign.TypeStyle.display)
        .foregroundStyle(LoopDesign.Palette.textPrimary)

      Text("AngelNotch is ready for its first feature.")
        .font(LoopDesign.TypeStyle.label)
        .foregroundStyle(LoopDesign.Palette.textSecondary)

      Spacer()

      Text("⌥ Space")
        .font(LoopDesign.TypeStyle.detail)
        .foregroundStyle(LoopDesign.Palette.textTertiary)
    }
    .padding(.horizontal, 22)
    .padding(.bottom, 18)
  }
}

private struct LoopMiniMark: View {
  @State private var isHovering = false

  var body: some View {
    ZStack {
      AngelNotchMarkShape()
        .stroke(
          LoopDesign.Palette.cream.opacity(0.26),
          style: StrokeStyle(lineWidth: 3.1, lineCap: .round)
        )
      AngelNotchMarkShape()
        .stroke(
          LoopDesign.Palette.accent.opacity(isHovering ? 1 : 0.82),
          style: StrokeStyle(
            lineWidth: 3.1,
            lineCap: .round,
            dash: [7, 34],
            dashPhase: isHovering ? -7 : 0
          )
        )
    }
    .frame(width: 25, height: 16)
    .scaleEffect(isHovering ? 1.07 : 1)
    .onHover { isHovering = $0 }
    .animation(LoopDesign.Motion.hover, value: isHovering)
    .accessibilityLabel("AngelNotch")
  }
}

private struct LoopIconButton: View {
  let symbol: String
  var active = false
  let help: String
  let action: () -> Void
  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      Image(systemName: symbol)
        .font(.system(size: 11, weight: .medium))
        .frame(width: 29, height: 29)
        .background(
          active
            ? LoopDesign.Palette.accent.opacity(0.18)
            : isHovering
              ? LoopDesign.Palette.surfaceRaised
              : LoopDesign.Palette.surfaceQuiet,
          in: RoundedRectangle(cornerRadius: 9)
        )
        .foregroundStyle(
          active
            ? LoopDesign.Palette.accent
            : isHovering
              ? LoopDesign.Palette.textPrimary
              : LoopDesign.Palette.textSecondary
        )
        .scaleEffect(isHovering ? 1.06 : 1)
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
    .animation(LoopDesign.Motion.hover, value: isHovering)
    .help(help)
    .interactiveCursor()
  }
}
