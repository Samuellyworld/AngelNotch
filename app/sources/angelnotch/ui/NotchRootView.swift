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
        ExpandedFeaturesView(model: model)
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
  @ObservedObject var focus: FocusTimer
  @ObservedObject var calendar: CalendarMonitor

  init(model: NotchModel) {
    self.model = model
    focus = model.focus
    calendar = model.calendar
  }

  var body: some View {
    HStack {
      if focus.isRunning {
        CompactStateIcon(
          symbol: focus.phase == .focus
            ? "timer"
            : "cup.and.saucer.fill",
          color: LoopDesign.Palette.accent,
          help: focus.phase == .focus ? "Focus session" : "Break"
        )
      } else if let event = calendar.nextEvent {
        HStack(spacing: 6) {
          CompactStateLabel(
            text: event.isInProgress ? "NOW" : "NEXT",
            color: LoopDesign.Palette.coral
          )
          Text(event.countdownLabel)
            .font(LoopDesign.TypeStyle.label)
            .foregroundStyle(LoopDesign.Palette.textSecondary)
        }
      } else {
        LoopMiniMark()
      }

      Spacer()

      if focus.isRunning {
        CompactProgressButton(
          progress: focus.progress,
          isRunning: focus.isRunning,
          color: LoopDesign.Palette.accent,
          help: "Pause focus timer",
          action: focus.toggleRunning
        )
      } else if let event = calendar.nextEvent {
        CompactIconButton(
          symbol: event.joinURL == nil ? "calendar" : "video.fill",
          color: LoopDesign.Palette.coral,
          help: event.joinURL == nil ? "Open calendar" : "Join meeting",
          action: {
            if event.joinURL == nil {
              model.expand(tab: .calendar)
            } else {
              calendar.joinNextEvent()
            }
          }
        )
      } else {
        CompactIconButton(
          symbol: "chevron.down",
          color: LoopDesign.Palette.textSecondary,
          help: "Open AngelNotch",
          action: { model.expand() }
        )
      }
    }
    .padding(.horizontal, 12)
    .frame(maxHeight: .infinity)
  }
}

private struct ExpandedFeaturesView: View {
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
    case .files:
      FileShelfPanel(store: model.files)
    case .focus:
      FocusPanel(timer: model.focus)
    case .calendar:
      CalendarPanel(monitor: model.calendar)
    }
  }

  private var visibleTabs: [IslandTab] {
    IslandTab.allCases.filter {
      if $0 == .clipboard { return settings.enableClipboard }
      if $0 == .calendar { return settings.enableCalendar }
      return true
    }
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

      Text("Clipboard, file shelf, and focus timer are ready.")
        .font(LoopDesign.TypeStyle.label)
        .foregroundStyle(LoopDesign.Palette.textSecondary)

      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

private struct CompactStateIcon: View {
  let symbol: String
  let color: Color
  let help: String

  var body: some View {
    Image(systemName: symbol)
      .font(.system(size: 11, weight: .semibold))
      .symbolRenderingMode(.monochrome)
      .foregroundStyle(color)
      .frame(width: 18, height: 24, alignment: .leading)
      .accessibilityLabel(help)
      .help(help)
  }
}

private struct CompactStateLabel: View {
  let text: String
  let color: Color

  var body: some View {
    Text(text)
      .font(.system(size: 8, weight: .semibold))
      .tracking(0.75)
      .foregroundStyle(color)
      .lineLimit(1)
      .fixedSize(horizontal: true, vertical: false)
  }
}

private struct CompactIconButton: View {
  let symbol: String
  let color: Color
  let help: String
  let action: () -> Void

  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      Image(systemName: symbol)
        .font(.system(size: 9, weight: .semibold))
        .symbolRenderingMode(.monochrome)
        .foregroundStyle(color)
        .frame(width: 24, height: 24)
        .background(
          LoopDesign.Palette.surface.opacity(isHovering ? 1 : 0),
          in: Circle()
        )
        .scaleEffect(isHovering ? 1.04 : 1)
    }
    .buttonStyle(.plain)
    .interactiveCursor()
    .onHover { isHovering = $0 }
    .animation(LoopDesign.Motion.hover, value: isHovering)
    .help(help)
  }
}

private struct CompactProgressButton: View {
  let progress: Double
  let isRunning: Bool
  let color: Color
  let help: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      ZStack {
        CircularProgress(value: progress, color: color)
          .frame(width: 21, height: 21)
        Image(systemName: isRunning ? "pause.fill" : "play.fill")
          .font(.system(size: 6, weight: .bold))
          .foregroundStyle(color)
          .offset(x: isRunning ? 0 : 0.4)
      }
      .frame(width: 24, height: 24)
    }
    .buttonStyle(.plain)
    .interactiveCursor()
    .help(help)
  }
}

struct CircularProgress: View {
  let value: Double
  let color: Color

  var body: some View {
    ZStack {
      Circle()
        .stroke(LoopDesign.Palette.surface, lineWidth: 3)
      Circle()
        .trim(from: 0, to: max(0.002, min(1, value)))
        .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        .rotationEffect(.degrees(-90))
    }
    .animation(.easeOut(duration: 0.2), value: value)
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

struct LoopCapsuleButtonStyle: ButtonStyle {
  var color: Color = LoopDesign.Palette.textSecondary

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(LoopDesign.TypeStyle.label)
      .padding(.horizontal, 13)
      .frame(height: 32)
      .background(
        color.opacity(configuration.isPressed ? 0.34 : 0.18),
        in: Capsule()
      )
      .foregroundStyle(color)
      .interactiveCursor()
  }
}

struct FileAction: View {
  let symbol: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: symbol)
        .font(.system(size: 10, weight: .semibold))
        .frame(width: 25, height: 25)
        .background(LoopDesign.Palette.surface, in: Circle())
    }
    .buttonStyle(.plain)
    .foregroundStyle(LoopDesign.Palette.textSecondary)
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
