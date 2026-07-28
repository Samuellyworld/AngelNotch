import SwiftUI

struct CalendarPanel: View {
  @ObservedObject var monitor: CalendarMonitor

  var body: some View {
    Group {
      if !monitor.canReadEvents {
        VStack(spacing: 12) {
          EmptyPanel(
            symbol: "calendar.badge.plus",
            title: "Calendar access is off",
            detail: "Allow access to show your next meeting."
          )
          Button("Enable Calendar", action: monitor.requestAccess)
            .buttonStyle(
              LoopCapsuleButtonStyle(color: LoopDesign.Palette.coral)
            )
        }
      } else if let event = monitor.nextEvent {
        VStack(spacing: 12) {
          HStack {
            VStack(alignment: .leading, spacing: 5) {
              Text(event.isInProgress ? "IN PROGRESS" : "UP NEXT")
                .font(LoopDesign.TypeStyle.eyebrow)
                .foregroundStyle(LoopDesign.Palette.coral)
              Text(event.title)
                .font(.system(size: 20, weight: .medium))
                .lineLimit(2)
              Text(
                "\(event.startDate.formatted(date: .omitted, time: .shortened)) · \(event.calendarTitle)"
              )
              .font(LoopDesign.TypeStyle.label)
              .foregroundStyle(LoopDesign.Palette.textSecondary)
            }
            Spacer()
            Text(event.countdownLabel)
              .font(.system(size: 24, weight: .medium))
              .monospacedDigit()
              .foregroundStyle(LoopDesign.Palette.coral)
          }
          if event.joinURL != nil {
            Button(action: monitor.joinNextEvent) {
              Label("Join meeting", systemImage: "video.fill")
            }
            .buttonStyle(
              LoopCapsuleButtonStyle(color: LoopDesign.Palette.coral)
            )
          }
        }
        .padding(18)
        .background(
          LoopDesign.Palette.surfaceQuiet,
          in: RoundedRectangle(cornerRadius: 18)
        )
      } else {
        EmptyPanel(
          symbol: "calendar",
          title: "No upcoming events",
          detail: "Your next seven days are clear."
        )
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
