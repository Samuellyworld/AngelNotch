import SwiftUI

struct FocusPanel: View {
  @ObservedObject var timer: FocusTimer

  private let presets = [15, 25, 50, 90]

  var body: some View {
    HStack(spacing: 28) {
      ZStack {
        FocusProgressRing(value: timer.progress)
          .frame(width: 128, height: 128)
        VStack(spacing: 4) {
          Text(timer.formattedRemaining)
            .font(.system(size: timer.formattedRemaining.count > 5 ? 24 : 28, weight: .medium))
            .monospacedDigit()
            .contentTransition(.numericText())
          Text(timer.phase.title)
            .font(LoopDesign.TypeStyle.detail)
            .foregroundStyle(LoopDesign.Palette.textSecondary)
        }
      }

      VStack(alignment: .leading, spacing: 12) {
        durationEditor

        Text("\(timer.completedSessions) focus sessions completed")
          .font(LoopDesign.TypeStyle.label)
          .foregroundStyle(LoopDesign.Palette.textSecondary)

        HStack(spacing: 8) {
          Button(action: timer.toggleRunning) {
            Label(
              timer.isRunning ? "Pause" : "Start",
              systemImage: timer.isRunning ? "pause.fill" : "play.fill"
            )
          }
          .buttonStyle(FocusPrimaryButtonStyle())

          Button("Skip", action: timer.skip)
            .buttonStyle(FocusSecondaryButtonStyle())
          Button("Reset", action: timer.reset)
            .buttonStyle(FocusSecondaryButtonStyle())
        }
      }
      .frame(maxWidth: 300, alignment: .leading)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var durationEditor: some View {
    VStack(alignment: .leading, spacing: 7) {
      HStack {
        Text("Session length")
          .font(LoopDesign.TypeStyle.detail)
          .foregroundStyle(LoopDesign.Palette.textTertiary)
        Spacer()
        Text("\(timer.focusMinutes) min")
          .font(.system(size: 11, weight: .medium))
          .monospacedDigit()
          .foregroundStyle(LoopDesign.Palette.textPrimary)
      }

      HStack(spacing: 6) {
        ForEach(presets, id: \.self) { minutes in
          Button("\(minutes)") {
            timer.setFocusDuration(minutes)
          }
          .buttonStyle(
            FocusPresetButtonStyle(
              selected: timer.focusMinutes == minutes
            )
          )
          .disabled(!timer.canEditDuration)
        }

        Stepper(
          "",
          value: Binding(
            get: { timer.focusMinutes },
            set: { newValue in
              timer.setFocusDuration(newValue)
            }
          ),
          in: 1...180
        )
        .labelsHidden()
        .controlSize(.small)
        .disabled(!timer.canEditDuration)
        .help("Set a custom focus duration")
      }

      if !timer.canEditDuration {
        Text("Reset the current session to change its length.")
          .font(LoopDesign.TypeStyle.detail)
          .foregroundStyle(LoopDesign.Palette.textTertiary)
      }
    }
  }
}

private struct FocusProgressRing: View {
  let value: Double

  var body: some View {
    ZStack {
      Circle()
        .stroke(LoopDesign.Palette.surface, lineWidth: 4)
      Circle()
        .trim(from: 0, to: max(0.002, min(1, value)))
        .stroke(
          LoopDesign.Palette.sun,
          style: StrokeStyle(lineWidth: 4, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
    }
    .animation(.easeOut(duration: 0.2), value: value)
  }
}

private struct FocusPresetButtonStyle: ButtonStyle {
  let selected: Bool

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 10, weight: .medium))
      .frame(width: 34, height: 26)
      .background(
        selected
          ? LoopDesign.Palette.sun.opacity(0.20)
          : LoopDesign.Palette.surfaceQuiet,
        in: RoundedRectangle(cornerRadius: 8)
      )
      .foregroundStyle(
        selected
          ? LoopDesign.Palette.sun
          : LoopDesign.Palette.textSecondary
      )
      .scaleEffect(configuration.isPressed ? 0.96 : 1)
      .interactiveCursor()
  }
}

private struct FocusPrimaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(LoopDesign.TypeStyle.label)
      .padding(.horizontal, 13)
      .frame(height: 30)
      .background(LoopDesign.Palette.sun.opacity(0.20), in: Capsule())
      .foregroundStyle(LoopDesign.Palette.sun)
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .interactiveCursor()
  }
}

private struct FocusSecondaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(LoopDesign.TypeStyle.label)
      .padding(.horizontal, 12)
      .frame(height: 30)
      .background(LoopDesign.Palette.surfaceQuiet, in: Capsule())
      .foregroundStyle(LoopDesign.Palette.textSecondary)
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .interactiveCursor()
  }
}
