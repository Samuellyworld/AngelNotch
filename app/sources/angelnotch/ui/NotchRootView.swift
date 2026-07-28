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
        ExpandedClipboardView(model: model)
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

private struct ExpandedClipboardView: View {
  @ObservedObject var model: NotchModel
  @ObservedObject var settings: AppSettings

  init(model: NotchModel) {
    self.model = model
    settings = model.settings
  }

  var body: some View {
    VStack(spacing: 10) {
      Color.clear.frame(height: 25)
      header
      tabs
      content
        .padding(.horizontal, 8)
        .padding(.top, 3)
    }
    .padding(.horizontal, 14)
    .padding(.bottom, 14)
  }

  private var header: some View {
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
  }

  private var tabs: some View {
    HStack(spacing: 7) {
      ForEach(visibleTabs) { tab in
        NavigationTabButton(
          tab: tab,
          isSelected: model.selectedTab == tab,
          accent: settings.accent.color
        ) {
          model.selectedTab = tab
        }
      }
    }
    .frame(maxWidth: .infinity)
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(LoopDesign.Palette.cream.opacity(0.07))
        .frame(height: 0.5)
    }
  }

  @ViewBuilder
  private var content: some View {
    switch model.selectedTab {
    case .home:
      FoundationHomePanel()
    case .clipboard:
      ClipboardPanel(store: model.clipboard)
    }
  }

  private var visibleTabs: [IslandTab] {
    settings.enableClipboard ? IslandTab.allCases : [.home]
  }
}

private struct FoundationHomePanel: View {
  var body: some View {
    VStack(spacing: 14) {
      Spacer(minLength: 0)
      AngelNotchMarkShape()
        .stroke(
          LoopDesign.Palette.accent,
          style: StrokeStyle(lineWidth: 4, lineCap: .round)
        )
        .frame(width: 64, height: 42)

      Text("Your Mac, at a glance.")
        .font(LoopDesign.TypeStyle.display)
        .foregroundStyle(LoopDesign.Palette.textPrimary)

      Text("Clipboard history is ready.")
        .font(LoopDesign.TypeStyle.label)
        .foregroundStyle(LoopDesign.Palette.textSecondary)

      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
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

struct LoopIconButton: View {
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

struct LoopHoverSurface: ViewModifier {
  let cornerRadius: CGFloat
  let isSelected: Bool
  @State private var isHovering = false

  func body(content: Content) -> some View {
    content
      .background(
        isSelected
          ? LoopDesign.Palette.surfaceRaised
          : isHovering
            ? LoopDesign.Palette.surface
            : LoopDesign.Palette.surfaceQuiet,
        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
      )
      .overlay {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .stroke(
            isSelected
              ? LoopDesign.Palette.accent.opacity(0.35)
              : isHovering
                ? LoopDesign.Palette.outline
                : .clear,
            lineWidth: 0.7
          )
      }
      .scaleEffect(isHovering ? 1.008 : 1)
      .offset(y: isHovering ? -0.5 : 0)
      .onHover { isHovering = $0 }
      .animation(LoopDesign.Motion.hover, value: isHovering)
      .animation(LoopDesign.Motion.hover, value: isSelected)
  }
}

private struct NavigationTabButton: View {
  let tab: IslandTab
  let isSelected: Bool
  let accent: Color
  let action: () -> Void
  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      Text(tab.title)
        .font(LoopDesign.TypeStyle.detail)
        .lineLimit(1)
        .foregroundStyle(
          isSelected
            ? LoopDesign.Palette.textPrimary
            : isHovering
              ? LoopDesign.Palette.textSecondary
              : LoopDesign.Palette.textTertiary
        )
        .padding(.horizontal, 7)
        .frame(height: 34)
        .overlay(alignment: .bottom) {
          Capsule()
            .fill(isSelected ? accent : .clear)
            .frame(width: 14, height: 2)
        }
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
    .animation(LoopDesign.Motion.hover, value: isHovering)
    .animation(LoopDesign.Motion.hover, value: isSelected)
    .help(tab.title)
    .interactiveCursor()
  }
}

struct LoopPrimaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(LoopDesign.TypeStyle.label)
      .padding(.horizontal, 12)
      .frame(height: 29)
      .background(
        configuration.isPressed
          ? LoopDesign.Palette.cream.opacity(0.78)
          : LoopDesign.Palette.cream,
        in: RoundedRectangle(cornerRadius: 9)
      )
      .foregroundStyle(LoopDesign.Palette.canvas)
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .animation(LoopDesign.Motion.hover, value: configuration.isPressed)
      .interactiveCursor()
  }
}

struct LoopTextButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(LoopDesign.TypeStyle.label)
      .padding(.horizontal, 10)
      .frame(height: 32)
      .background(
        LoopDesign.Palette.accent.opacity(configuration.isPressed ? 0.22 : 0.12),
        in: RoundedRectangle(cornerRadius: 9)
      )
      .foregroundStyle(LoopDesign.Palette.accent)
      .scaleEffect(configuration.isPressed ? 0.98 : 1)
      .interactiveCursor()
  }
}

struct EmptyPanel: View {
  let symbol: String
  let title: String
  let detail: String

  var body: some View {
    VStack(spacing: 7) {
      Image(systemName: symbol)
        .font(.system(size: 28, weight: .medium))
        .foregroundStyle(LoopDesign.Palette.textTertiary)
      Text(title)
        .font(LoopDesign.TypeStyle.title)
      Text(detail)
        .font(LoopDesign.TypeStyle.detail)
        .foregroundStyle(LoopDesign.Palette.textSecondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
