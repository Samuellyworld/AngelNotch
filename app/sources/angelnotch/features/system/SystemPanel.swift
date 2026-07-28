import SwiftUI

struct SystemPanel: View {
  @ObservedObject var monitor: SystemMonitor

  var body: some View {
    VStack(spacing: 9) {
      HStack(spacing: 9) {
        SystemControlSlider(
          title: "Volume",
          detail: nil,
          symbol: monitor.snapshot.isMuted
            ? "speaker.slash.fill"
            : "speaker.wave.2.fill",
          value: monitor.snapshot.volume,
          color: LoopDesign.Palette.cyan,
          isEnabled: true,
          onChange: monitor.setVolume
        )
        SystemControlSlider(
          title: "Brightness",
          detail: monitor.snapshot.isBrightnessAvailable
            ? nil
            : "Display unavailable",
          symbol: "sun.max.fill",
          value: monitor.snapshot.brightness,
          color: LoopDesign.Palette.sun,
          isEnabled: monitor.snapshot.isBrightnessAvailable,
          onChange: monitor.setBrightness
        )
      }

      HStack(spacing: 0) {
        SystemStatusItem(
          title: "Microphone",
          detail: monitor.snapshot.isMicrophoneMuted ? "Muted" : "Ready",
          symbol: monitor.snapshot.isMicrophoneMuted
            ? "mic.slash.fill"
            : "mic.fill",
          color: monitor.snapshot.isMicrophoneMuted
            ? LoopDesign.Palette.coral
            : LoopDesign.Palette.mint,
          help: monitor.snapshot.isMicrophoneMuted
            ? "Unmute microphone"
            : "Mute microphone",
          action: monitor.toggleMicrophoneMute
        )

        SystemStatusDivider()

        SystemStatusItem(
          title: "Camera",
          detail: monitor.snapshot.isCameraInUse ? "In use" : "Not in use",
          symbol: monitor.snapshot.isCameraInUse ? "video.fill" : "video.slash",
          color: monitor.snapshot.isCameraInUse
            ? LoopDesign.Palette.mint
            : LoopDesign.Palette.textTertiary,
          help: "Open Camera privacy settings",
          action: monitor.openCameraPrivacySettings
        )

        SystemStatusDivider()

        SystemStatusItem(
          title: "Battery",
          detail: batteryDetail,
          symbol: LoopBatteryStyle.symbol(
            level: monitor.snapshot.batteryLevel
          ),
          color: LoopBatteryStyle.color(
            level: monitor.snapshot.batteryLevel,
            charging: monitor.snapshot.isCharging,
            lowPowerMode: monitor.snapshot.isLowPowerModeEnabled
          )
        )
      }
      .frame(height: 48)
      .background(
        LoopDesign.Palette.surfaceQuiet,
        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
      )

      HStack(spacing: 8) {
        Image(systemName: "hifispeaker.fill")
          .foregroundStyle(LoopDesign.Palette.textTertiary)
        Text(monitor.snapshot.outputDeviceName)
          .font(LoopDesign.TypeStyle.label)
          .lineLimit(1)
        Spacer()
        Menu {
          ForEach(monitor.outputDevices) { device in
            Button(device.name) { monitor.selectOutput(device) }
          }
        } label: {
          HStack(spacing: 4) {
            Text("Change output")
            Image(systemName: "chevron.down")
              .font(.system(size: 8, weight: .semibold))
          }
          .font(LoopDesign.TypeStyle.label)
          .foregroundStyle(LoopDesign.Palette.textSecondary)
        }
        .menuStyle(.borderlessButton)
        .interactiveCursor()
      }
      .padding(.horizontal, 12)
      .frame(height: 38)
      .background(
        LoopDesign.Palette.surfaceQuiet,
        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
      )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }

  private var batteryDetail: String {
    let percentage = "\(Int(monitor.snapshot.batteryLevel * 100))%"
    guard
      let detail = LoopBatteryStyle.detail(
        charging: monitor.snapshot.isCharging,
        powerConnected: monitor.snapshot.isPowerAdapterConnected,
        lowPowerMode: monitor.snapshot.isLowPowerModeEnabled,
        minutesRemaining: monitor.snapshot.batteryMinutesRemaining
      )
    else {
      return percentage
    }
    return "\(percentage) · \(detail)"
  }
}

private struct SystemControlSlider: View {
  let title: String
  let detail: String?
  let symbol: String
  let value: Double
  let color: Color
  let isEnabled: Bool
  let onChange: (Double) -> Void

  @State private var localValue = 0.0

  var body: some View {
    VStack(alignment: .leading, spacing: 7) {
      HStack(spacing: 5) {
        Image(systemName: symbol)
          .font(.system(size: 10, weight: .semibold))
        Text(title)
          .font(LoopDesign.TypeStyle.label)
        Spacer()
        if let detail {
          Text(detail)
            .font(.system(size: 8))
            .foregroundStyle(LoopDesign.Palette.textTertiary)
        }
      }
      .foregroundStyle(isEnabled ? color : LoopDesign.Palette.textTertiary)

      Slider(
        value: Binding(
          get: { localValue },
          set: { newValue in
            localValue = newValue
            if isEnabled {
              onChange(newValue)
            }
          }
        ),
        in: 0...1
      ) {
        Text(title)
      }
      .tint(color)
      .disabled(!isEnabled)
    }
    .padding(11)
    .frame(maxWidth: .infinity)
    .background(
      LoopDesign.Palette.surfaceQuiet,
      in: RoundedRectangle(cornerRadius: 14, style: .continuous)
    )
    .opacity(isEnabled ? 1 : 0.56)
    .onAppear { localValue = value }
    .onChange(of: value) { _, newValue in
      localValue = newValue
    }
  }
}

private struct SystemStatusItem: View {
  let title: String
  let detail: String
  let symbol: String
  let color: Color
  var help: String?
  var action: (() -> Void)?

  @ViewBuilder
  var body: some View {
    if let action {
      Button(action: action) {
        content
      }
      .buttonStyle(.plain)
      .help(help ?? title)
      .interactiveCursor()
    } else {
      content
    }
  }

  private var content: some View {
    HStack(spacing: 8) {
      Image(systemName: symbol)
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(color)
        .frame(width: 18)

      VStack(alignment: .leading, spacing: 1) {
        Text(title)
          .font(LoopDesign.TypeStyle.detail)
          .foregroundStyle(LoopDesign.Palette.textSecondary)
        Text(detail)
          .font(.system(size: 9, weight: .medium))
          .foregroundStyle(LoopDesign.Palette.textPrimary)
          .lineLimit(1)
      }
    }
    .padding(.horizontal, 10)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .contentShape(Rectangle())
  }
}

private struct SystemStatusDivider: View {
  var body: some View {
    Rectangle()
      .fill(LoopDesign.Palette.outline)
      .frame(width: 0.5, height: 25)
  }
}
