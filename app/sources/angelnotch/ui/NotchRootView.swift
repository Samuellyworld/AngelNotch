import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// The morphing compact/expanded AngelNotch surface and feature composition root.
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
        ExpandedIslandView(model: model)
          .transition(
            .asymmetric(
              insertion: .opacity.combined(
                with: .scale(scale: 0.92, anchor: .top)
              ),
              removal: .opacity
            )
          )
      } else {
        CompactIslandView(model: model)
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

private struct CompactIslandView: View {
  @ObservedObject var model: NotchModel
  @ObservedObject var media: MediaMonitor
  @ObservedObject var focus: FocusTimer
  @ObservedObject var calendar: CalendarMonitor
  @ObservedObject var activities: LiveActivityCenter
  @ObservedObject var system: SystemMonitor

  init(model: NotchModel) {
    self.model = model
    media = model.media
    focus = model.focus
    calendar = model.calendar
    activities = model.activities
    system = model.system
  }

  var body: some View {
    HStack {
      if let hud = model.visibleHUD {
        HUDCompactLeading(event: hud)
      } else if system.snapshot.isCallActive {
        CompactStateIcon(
          symbol: "phone.fill",
          color: LoopDesign.Palette.call,
          help: "Call in progress"
        )
        .layoutPriority(2)
      } else if focus.isRunning {
        CompactStateIcon(
          symbol: focus.phase == .focus
            ? "timer"
            : "cup.and.saucer.fill",
          color: LoopDesign.Palette.accent,
          help: focus.phase == .focus ? "Focus session" : "Break"
        )
        .layoutPriority(2)
      } else if let item = media.snapshot {
        MediaArtwork(
          snapshot: item,
          size: 25,
          animated: item.isPlaying && !model.settings.enableReducedMotion,
          tint: LoopDesign.Palette.accent
        )
      } else if let activity = activities.activities.first {
        HStack(spacing: 6) {
          Circle()
            .fill(LoopDesign.Palette.accent)
            .frame(width: 5, height: 5)
          Text(activity.title)
            .font(LoopDesign.TypeStyle.detail)
            .foregroundStyle(LoopDesign.Palette.textSecondary)
            .lineLimit(1)
        }
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

      if let hud = model.visibleHUD {
        HUDCompactTrailing(event: hud, model: model)
      } else if system.snapshot.isCallActive {
        CompactCallActivityButton(
          color: LoopDesign.Palette.coral,
          reducedMotion: model.settings.enableReducedMotion,
          action: { model.expand(tab: .system) }
        )
      } else if focus.isRunning {
        CompactProgressButton(
          progress: focus.progress,
          isRunning: focus.isRunning,
          color: LoopDesign.Palette.accent,
          help: focus.isRunning ? "Pause focus timer" : "Resume focus timer",
          action: focus.toggleRunning
        )
      } else if let item = media.snapshot {
        CompactPlaybackButton(
          isPlaying: item.isPlaying,
          color: item.source == .spotify
            ? (item.isPlaying ? LoopDesign.Palette.spotify : LoopDesign.Palette.mint)
            : LoopDesign.Palette.accent,
          reducedMotion: model.settings.enableReducedMotion,
          action: { media.send(.playPause) }
        )
      } else if let activity = activities.activities.first {
        CompactActivityButton(
          progress: activity.progress,
          action: { model.expand(tab: .activities) }
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

private struct ExpandedIslandView: View {
  @ObservedObject var model: NotchModel
  @ObservedObject var settings: AppSettings
  @ObservedObject var context: ContextMonitor

  init(model: NotchModel) {
    self.model = model
    settings = model.settings
    context = model.context
  }

  var body: some View {
    VStack(spacing: 10) {
      Color.clear.frame(height: 25)
      header
      tabs
      content
        .padding(.horizontal, LoopDesign.Spacing.panelInset)
        .padding(.top, 3)
    }
    .padding(.horizontal, 14)
    .padding(.bottom, 14)
  }

  private var header: some View {
    HStack(spacing: 10) {
      LoopMiniMark()
        .frame(width: 28, height: 20)

      VStack(alignment: .leading, spacing: 1) {
        Text("AngelNotch")
          .font(LoopDesign.TypeStyle.title)
          .foregroundStyle(LoopDesign.Palette.textPrimary)
        Text(context.activeApplicationName)
          .font(LoopDesign.TypeStyle.detail)
          .foregroundStyle(LoopDesign.Palette.textTertiary)
          .lineLimit(1)
      }

      Spacer()

      if model.settings.enableContextModes {
        Text(context.mode.title)
          .font(LoopDesign.TypeStyle.detail)
          .foregroundStyle(LoopDesign.Palette.textTertiary)
      }

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
          accent: accentColor
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
      HomePanel(model: model)
    case .clipboard:
      ClipboardPanel(store: model.clipboard)
    case .files:
      FileShelfPanel(store: model.files)
    case .focus:
      FocusPanel(timer: model.focus)
    case .calendar:
      CalendarPanel(monitor: model.calendar)
    case .system:
      SystemPanel(monitor: model.system)
    case .activities:
      ActivitiesPanel(center: model.activities)
    }
  }

  private var visibleTabs: [IslandTab] {
    IslandTab.allCases.filter {
      if $0 == .clipboard { return settings.enableClipboard }
      if $0 == .calendar { return settings.enableCalendar }
      return true
    }
  }

  private var accentColor: Color {
    settings.accent.color
  }
}

private struct HomePanel: View {
  @ObservedObject var model: NotchModel
  @ObservedObject var media: MediaMonitor
  @ObservedObject var context: ContextMonitor
  @ObservedObject var system: SystemMonitor

  init(model: NotchModel) {
    self.model = model
    media = model.media
    context = model.context
    system = model.system
  }

  var body: some View {
    Group {
      if let snapshot = media.snapshot {
        MediaPanel(
          snapshot: snapshot,
          media: media,
          system: model.system,
          reducedMotion: model.settings.enableReducedMotion
        )
      } else {
        contextHome
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var contextHome: some View {
    VStack(spacing: 12) {
      Spacer(minLength: 0)
      ZStack {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(LoopDesign.Palette.surfaceQuiet)
          .frame(width: 58, height: 52)
          .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .stroke(LoopDesign.Palette.outline, lineWidth: 0.6)
          }
        LoopMiniMark()
          .scaleEffect(1.35)
      }

      Text(model.context.mode.title)
        .font(LoopDesign.TypeStyle.title)
        .foregroundStyle(LoopDesign.Palette.textPrimary)

      Button(action: model.performPrimaryContextAction) {
        Label(contextActionTitle, systemImage: contextActionSymbol)
          .font(LoopDesign.TypeStyle.label)
          .padding(.horizontal, 16)
          .frame(height: 34)
          .background(LoopDesign.Palette.surface, in: Capsule())
      }
      .buttonStyle(.plain)
      .foregroundStyle(LoopDesign.Palette.textPrimary)
      .interactiveCursor()

      HStack(spacing: 8) {
        QuickTile(title: "Clipboard", symbol: "doc.on.clipboard") {
          model.selectedTab = .clipboard
        }
        QuickTile(title: "Files", symbol: "tray.full") {
          model.selectedTab = .files
        }
        QuickTile(title: "Focus", symbol: "timer") {
          model.selectedTab = .focus
        }
        QuickTile(title: "System", symbol: "slider.horizontal.3") {
          model.selectedTab = .system
        }
      }
      Spacer(minLength: 0)
    }
    .overlay(alignment: .topTrailing) {
      HomeBatteryBadge(snapshot: system.snapshot)
    }
  }

  private var contextActionTitle: String {
    switch model.context.mode {
    case .browser: "Search the web"
    case .development: "Open Downloads"
    case .communication: "Open next meeting"
    case .media: "Play or pause"
    case .design: "Capture screen"
    case .general: "Open clipboard"
    }
  }

  private var contextActionSymbol: String {
    switch model.context.mode {
    case .browser: "magnifyingglass"
    case .development: "arrow.down.circle"
    case .communication: "video"
    case .media: "playpause.fill"
    case .design: "viewfinder"
    case .general: "doc.on.clipboard"
    }
  }
}

struct AnimatedWaveform: View {
  let color: Color
  let isPlaying: Bool
  let reducedMotion: Bool

  private var cadence: AnimationTimelineSchedule {
    .animation(
      minimumInterval: reducedMotion ? 1 : 0.11,
      paused: !isPlaying || reducedMotion
    )
  }

  var body: some View {
    TimelineView(cadence) { context in
      waveform(at: context.date.timeIntervalSinceReferenceDate)
    }
    .frame(width: 24, height: 20)
    .accessibilityLabel(isPlaying ? "Playing" : "Paused")
  }

  private func waveform(at time: TimeInterval) -> some View {
    HStack(spacing: 2) {
      ForEach(0..<5, id: \.self) { index in
        Capsule()
          .fill(color)
          .frame(width: 2.5, height: barHeight(for: index, at: time))
      }
    }
    .animation(.linear(duration: 0.10), value: time)
  }

  private func barHeight(for index: Int, at time: TimeInterval) -> CGFloat {
    guard !reducedMotion else { return 10 }
    let phase = time * (2.5 + Double(index) * 0.31) + Double(index) * 0.9
    return CGFloat(5 + abs(sin(phase)) * 13)
  }
}

struct MediaArtwork: View {
  let snapshot: MediaSnapshot
  let size: CGFloat
  let animated: Bool
  var tint: Color? = nil

  private var accent: Color {
    tint ?? mediaColor(snapshot.source)
  }

  var body: some View {
    TimelineView(.animation(minimumInterval: 1 / 30, paused: !animated)) { context in
      let pulse =
        animated
        ? 1 + sin(context.date.timeIntervalSinceReferenceDate * 2.2) * 0.025
        : 1
      artwork
        .scaleEffect(pulse)
        .overlay {
          RoundedRectangle(cornerRadius: size * 0.24)
            .stroke(accent.opacity(animated ? 0.5 : 0), lineWidth: 1)
        }
    }
    .frame(width: size, height: size)
  }

  @ViewBuilder
  private var artwork: some View {
    if let url = snapshot.artworkURL {
      AsyncImage(url: url) { image in
        image.resizable().scaledToFill()
      } placeholder: {
        fallback
      }
      .frame(width: size, height: size)
      .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
    } else {
      fallback
    }
  }

  private var fallback: some View {
    ZStack {
      RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
        .fill(accent.opacity(0.18))
      Image(systemName: snapshot.source.symbolName)
        .font(.system(size: size * 0.36, weight: .bold))
        .foregroundStyle(accent)
    }
    .frame(width: size, height: size)
  }
}

private struct HUDCompactLeading: View {
  let event: SystemHUDEvent

  @ViewBuilder
  var body: some View {
    switch event.kind {
    case .volume(let value, let muted):
      CompactStateIcon(
        symbol: volumeSymbol(value: value, muted: muted),
        color: color,
        help: muted ? "Muted" : "Volume"
      )
    case .brightness:
      CompactStateIcon(
        symbol: "sun.max.fill",
        color: color,
        help: "Display brightness"
      )
    case .airPodsConnected(let airPods):
      CompactAirPodsIcon(
        symbolName: airPods.model.symbolName,
        help: airPods.accessibilitySummary
      )
    default:
      CompactStateLabel(text: label, color: color)
    }
  }

  private var label: String {
    switch event.kind {
    case .volume(_, let muted): muted ? "MUTED" : "VOLUME"
    case .brightness: "DISPLAY"
    case .battery: "POWER"
    case .microphone(let muted): muted ? "MIC OFF" : "MIC ON"
    case .camera(let active): active ? "CAMERA" : "CAM OFF"
    case .audioOutput: "OUTPUT"
    case .airPodsConnected: "CONNECTED"
    }
  }

  private func volumeSymbol(value: Double, muted: Bool) -> String {
    if muted || value < 0.01 {
      return "speaker.slash.fill"
    }
    switch value {
    case ..<0.34: return "speaker.wave.1.fill"
    case ..<0.67: return "speaker.wave.2.fill"
    default: return "speaker.wave.3.fill"
    }
  }

  private var color: Color {
    switch event.kind {
    case .brightness:
      LoopDesign.Palette.accent
    case .battery(let level, let charging, _, let lowPowerMode):
      LoopBatteryStyle.color(
        level: level,
        charging: charging,
        lowPowerMode: lowPowerMode
      )
    case .microphone(let muted): muted ? LoopDesign.Palette.coral : LoopDesign.Palette.accent
    case .camera(let active): active ? LoopDesign.Palette.accent : LoopDesign.Palette.textSecondary
    case .airPodsConnected: LoopDesign.Palette.call
    default: LoopDesign.Palette.accent
    }
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

private struct CompactCallActivityButton: View {
  let color: Color
  let reducedMotion: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      AnimatedWaveform(
        color: color,
        isPlaying: true,
        reducedMotion: reducedMotion
      )
      .frame(width: 28, height: 20)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .interactiveCursor()
    .accessibilityLabel("Call in progress")
    .help("Call in progress")
  }
}

extension ConnectedAirPods {
  fileprivate var accessibilitySummary: String {
    guard let batteryLevel else {
      return "\(name) connected; battery unavailable"
    }
    return "\(name) connected; \(Int((batteryLevel * 100).rounded()))% battery"
  }
}

private struct CompactAirPodsIcon: View {
  let symbolName: String
  let help: String

  var body: some View {
    Image(systemName: symbolName)
      .font(.system(size: 13, weight: .medium))
      .symbolRenderingMode(.monochrome)
      .foregroundStyle(LoopDesign.Palette.textPrimary)
      .frame(width: 22, height: 24, alignment: .leading)
      .accessibilityLabel(help)
      .help(help)
  }
}

private struct CompactAirPodsRingButton: View {
  let batteryLevel: Double?
  let help: String
  let action: () -> Void

  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      ZStack {
        Circle()
          .strokeBorder(
            LoopDesign.Palette.textSecondary.opacity(0.30),
            lineWidth: 2.2
          )
        if let batteryLevel {
          Circle()
            .trim(from: 0, to: min(1, max(0, batteryLevel)))
            .stroke(
              batteryColor(for: batteryLevel),
              style: StrokeStyle(
                lineWidth: 2.4,
                lineCap: .round
              )
            )
            .rotationEffect(.degrees(-90))
        } else {
          Circle()
            .fill(LoopDesign.Palette.call)
            .frame(width: 4, height: 4)
        }
      }
      .frame(width: 20, height: 20)
      .frame(width: 24, height: 24)
      .scaleEffect(isHovered ? 1.05 : 1)
    }
    .buttonStyle(.plain)
    .interactiveCursor()
    .onHover { hovering in
      withAnimation(.easeOut(duration: 0.14)) {
        isHovered = hovering
      }
    }
    .accessibilityLabel(help)
    .help(help)
  }

  private func batteryColor(for level: Double) -> Color {
    switch level {
    case ..<0.15: LoopDesign.Palette.coral
    case ..<0.30: LoopDesign.Palette.accent
    default: LoopDesign.Palette.call
    }
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
  var emphasized = false
  var opticalOffsetX: CGFloat = 0
  let action: () -> Void

  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      Image(systemName: symbol)
        .font(.system(size: emphasized ? 10 : 9, weight: .semibold))
        .symbolRenderingMode(.monochrome)
        .foregroundStyle(emphasized ? Color.black.opacity(0.86) : color)
        .frame(width: 24, height: 24)
        .background(
          Circle()
            .fill(
              emphasized
                ? color
                : LoopDesign.Palette.surface.opacity(isHovered ? 1 : 0)
            )
        )
        .overlay {
          if !emphasized {
            Circle()
              .strokeBorder(
                LoopDesign.Palette.outline.opacity(isHovered ? 0.8 : 0),
                lineWidth: 0.5
              )
          }
        }
        .scaleEffect(isHovered ? 1.04 : 1)
        .offset(x: opticalOffsetX)
    }
    .buttonStyle(.plain)
    .interactiveCursor()
    .onHover { hovering in
      withAnimation(.easeOut(duration: 0.14)) {
        isHovered = hovering
      }
    }
    .help(help)
  }
}

private struct CompactPlaybackButton: View {
  let isPlaying: Bool
  let color: Color
  let reducedMotion: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Group {
        if isPlaying {
          AnimatedWaveform(
            color: color,
            isPlaying: true,
            reducedMotion: reducedMotion
          )
          .frame(width: 24, height: 18)
          .contentShape(Rectangle())
        } else {
          Image(systemName: "play.fill")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(Color.black.opacity(0.86))
            .offset(x: 0.6)
            .frame(width: 24, height: 24)
            .background(color, in: Circle())
        }
      }
    }
    .buttonStyle(.plain)
    .interactiveCursor()
    .help(isPlaying ? "Pause" : "Play")
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

private struct CompactActivityButton: View {
  let progress: Double?
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Group {
        if let progress {
          ZStack {
            CircularProgress(
              value: progress,
              color: LoopDesign.Palette.accent
            )
            Image(systemName: "arrow.down")
              .font(.system(size: 6, weight: .bold))
              .foregroundStyle(LoopDesign.Palette.accent)
          }
        } else {
          Image(systemName: "ellipsis")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(LoopDesign.Palette.accent)
        }
      }
      .frame(width: 24, height: 24)
    }
    .buttonStyle(.plain)
    .interactiveCursor()
    .help("Open live activities")
  }
}

private struct HomeBatteryBadge: View {
  let snapshot: SystemSnapshot

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: LoopBatteryStyle.symbol(level: snapshot.batteryLevel))
        .font(.system(size: 11, weight: .medium))
      Text("\(Int(snapshot.batteryLevel * 100))%")
        .font(.system(size: 10, weight: .medium))
        .monospacedDigit()
      if let detail = LoopBatteryStyle.detail(
        charging: snapshot.isCharging,
        powerConnected: snapshot.isPowerAdapterConnected,
        lowPowerMode: snapshot.isLowPowerModeEnabled,
        minutesRemaining: snapshot.batteryMinutesRemaining
      ) {
        Text(detail)
          .font(LoopDesign.TypeStyle.detail)
      }
    }
    .foregroundStyle(
      LoopBatteryStyle.color(
        level: snapshot.batteryLevel,
        charging: snapshot.isCharging,
        lowPowerMode: snapshot.isLowPowerModeEnabled
      )
    )
    .padding(.horizontal, 9)
    .frame(height: 27)
    .background(LoopDesign.Palette.surfaceQuiet, in: Capsule())
    .help(snapshot.isCharging ? "Battery is charging" : "Battery status")
  }
}

private struct HUDCompactTrailing: View {
  let event: SystemHUDEvent
  @ObservedObject var model: NotchModel

  var body: some View {
    Group {
      switch event.kind {
      case .volume(let value, let muted):
        HUDBar(value: muted ? 0 : value, color: LoopDesign.Palette.accent)
      case .brightness(let value):
        HUDBar(value: value, color: LoopDesign.Palette.accent)
      case .battery(
        let value,
        let charging,
        let powerConnected,
        let lowPowerMode
      ):
        CompactIconButton(
          symbol: charging
            ? "battery.100.bolt"
            : LoopBatteryStyle.symbol(level: value),
          color: LoopBatteryStyle.color(
            level: value,
            charging: charging,
            lowPowerMode: lowPowerMode
          ),
          help: powerConnected ? "Open power status" : "Open battery status",
          opticalOffsetX: 2,
          action: { model.expand(tab: .system) }
        )
      case .microphone(let muted):
        CompactIconButton(
          symbol: muted ? "mic.slash.fill" : "mic.fill",
          color: muted ? LoopDesign.Palette.coral : LoopDesign.Palette.accent,
          help: muted ? "Unmute microphone" : "Mute microphone",
          action: model.system.toggleMicrophoneMute
        )
      case .camera(let active):
        CompactIconButton(
          symbol: active ? "video.fill" : "video.slash.fill",
          color: active ? LoopDesign.Palette.call : LoopDesign.Palette.textSecondary,
          help: "Open camera status",
          action: { model.expand(tab: .system) }
        )
      case .audioOutput:
        CompactIconButton(
          symbol: "speaker.wave.2.fill",
          color: LoopDesign.Palette.accent,
          help: "Open audio output",
          action: { model.expand(tab: .system) }
        )
      case .airPodsConnected(let airPods):
        CompactAirPodsRingButton(
          batteryLevel: airPods.batteryLevel,
          help: airPods.accessibilitySummary,
          action: { model.expand(tab: .system) }
        )
      }
    }
    .frame(maxWidth: 70, alignment: .trailing)
  }
}

private struct HUDBar: View {
  let value: Double
  let color: Color

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Capsule().fill(LoopDesign.Palette.surface)
        Capsule()
          .fill(color)
          .frame(width: geometry.size.width * max(0, min(1, value)))
      }
    }
    .frame(width: 54, height: 5)
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

struct MediaControlButton: View {
  let systemImage: String
  let size: CGFloat
  var emphasized = false
  var color: Color = LoopDesign.Palette.cream
  let action: () -> Void
  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      Image(systemName: systemImage)
        .font(.system(size: emphasized ? 15 : 11, weight: .bold))
        .frame(width: size, height: size)
        .background(
          emphasized
            ? color.opacity(isHovering ? 1 : 0.92)
            : (isHovering
              ? LoopDesign.Palette.surfaceRaised
              : LoopDesign.Palette.surface),
          in: Circle()
        )
        .foregroundStyle(
          emphasized ? .black : LoopDesign.Palette.textPrimary
        )
        .scaleEffect(isHovering ? 1.04 : 1)
        .shadow(
          color: emphasized ? color.opacity(0.16) : .clear,
          radius: 10,
          y: 3
        )
    }
    .buttonStyle(.plain)
    .onHover { hovering in
      isHovering = hovering
    }
    .animation(LoopDesign.Motion.hover, value: isHovering)
    .interactiveCursor()
  }
}

private struct QuickTile: View {
  let title: String
  let symbol: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 6) {
        Image(systemName: symbol)
          .font(.system(size: 15, weight: .semibold))
        Text(title)
          .font(LoopDesign.TypeStyle.detail)
      }
      .foregroundStyle(LoopDesign.Palette.textSecondary)
      .frame(maxWidth: .infinity)
      .frame(height: 58)
    }
    .buttonStyle(.plain)
    .modifier(LoopHoverSurface(cornerRadius: 14, isSelected: false))
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

struct LoopCapsuleButtonStyle: ButtonStyle {
  var color: Color = LoopDesign.Palette.textSecondary

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(LoopDesign.TypeStyle.label)
      .padding(.horizontal, 13)
      .frame(height: 32)
      .background(color.opacity(configuration.isPressed ? 0.34 : 0.18), in: Capsule())
      .foregroundStyle(color)
      .interactiveCursor()
  }
}

func mediaColor(_ source: MediaSource) -> Color {
  switch source {
  case .spotify: LoopDesign.Palette.spotify
  case .appleMusic: LoopDesign.Palette.appleMusic
  case .youtube: LoopDesign.Palette.coral
  }
}
