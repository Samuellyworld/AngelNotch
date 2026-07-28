import SwiftUI

struct CalendarPanel: View {
  @ObservedObject var monitor: CalendarMonitor

  var body: some View {
    Group {
      if !monitor.canReadEvents {
        VStack(spacing: 12) {
          EmptyPanel(
            symbol: accessSymbol,
            title: accessTitle,
            detail: accessDetail
          )
          if let accessButtonTitle {
            Button(action: monitor.requestAccess) {
              if monitor.isRequestingAccess {
                ProgressView()
                  .controlSize(.small)
              } else {
                Text(accessButtonTitle)
              }
            }
            .buttonStyle(
              LoopCapsuleButtonStyle(color: LoopDesign.Palette.coral)
            )
            .disabled(monitor.isRequestingAccess)
          }
          if let error = monitor.accessError {
            Text(error)
              .font(LoopDesign.TypeStyle.detail)
              .foregroundStyle(LoopDesign.Palette.coral)
              .multilineTextAlignment(.center)
              .lineLimit(2)
          }
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
    .onAppear(perform: monitor.refresh)
  }

  private var accessSymbol: String {
    switch monitor.authorizationStatus {
    case .notDetermined:
      "calendar.badge.plus"
    case .denied, .restricted, .writeOnly:
      "calendar.badge.exclamationmark"
    case .fullAccess:
      "calendar"
    @unknown default:
      "calendar.badge.exclamationmark"
    }
  }

  private var accessTitle: String {
    switch monitor.authorizationStatus {
    case .notDetermined:
      "Calendar access is off"
    case .denied:
      "Calendar access was denied"
    case .restricted:
      "Calendar access is restricted"
    case .writeOnly:
      "Full Calendar access is needed"
    case .fullAccess:
      "Calendar access is on"
    @unknown default:
      "Calendar access is unavailable"
    }
  }

  private var accessDetail: String {
    switch monitor.authorizationStatus {
    case .notDetermined:
      "Allow access to show your next meeting."
    case .denied:
      "Allow AngelNotch in System Settings to show your next meeting."
    case .restricted:
      "A system restriction prevents AngelNotch from reading events."
    case .writeOnly:
      "Change AngelNotch to Full Access in System Settings."
    case .fullAccess:
      "AngelNotch can show your next meeting."
    @unknown default:
      "Review AngelNotch's Calendar permission in System Settings."
    }
  }

  private var accessButtonTitle: String? {
    switch monitor.authorizationStatus {
    case .notDetermined:
      "Enable Calendar"
    case .denied, .writeOnly:
      "Open Calendar Settings"
    case .restricted, .fullAccess:
      nil
    @unknown default:
      "Open Calendar Settings"
    }
  }
}
