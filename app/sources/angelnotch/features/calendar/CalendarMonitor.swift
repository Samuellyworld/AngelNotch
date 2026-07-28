import AppKit
import EventKit
import Foundation

struct UpcomingEvent: Identifiable, Equatable, Sendable {
  let id: String
  let title: String
  let startDate: Date
  let endDate: Date
  let calendarTitle: String
  let joinURL: URL?

  var isInProgress: Bool {
    startDate <= .now && endDate > .now
  }

  var countdownLabel: String {
    if isInProgress { return "Now" }
    let seconds = max(0, Int(startDate.timeIntervalSinceNow))
    if seconds < 60 { return "<1m" }
    if seconds < 3_600 { return "\(seconds / 60)m" }
    if seconds < 86_400 { return "\(seconds / 3_600)h" }
    return startDate.formatted(.dateTime.weekday(.abbreviated))
  }
}

@MainActor
final class CalendarMonitor: ObservableObject {
  @Published private(set) var nextEvent: UpcomingEvent?
  @Published private(set) var authorizationStatus: EKAuthorizationStatus
  @Published private(set) var isRequestingAccess = false
  @Published private(set) var accessError: String?

  private let store = EKEventStore()
  private var monitorTask: Task<Void, Never>?
  private var settingsRefreshTask: Task<Void, Never>?

  init() {
    authorizationStatus = EKEventStore.authorizationStatus(for: .event)
  }

  var canReadEvents: Bool {
    authorizationStatus == .fullAccess
  }

  func start() {
    guard monitorTask == nil else { return }
    refresh()
    monitorTask = Task { @MainActor [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(60))
        self?.refresh()
      }
    }
  }

  func stop() {
    monitorTask?.cancel()
    monitorTask = nil
    settingsRefreshTask?.cancel()
    settingsRefreshTask = nil
  }

  func requestAccess() {
    authorizationStatus = EKEventStore.authorizationStatus(for: .event)

    switch authorizationStatus {
    case .notDetermined:
      guard !isRequestingAccess else { return }
      isRequestingAccess = true
      accessError = nil

      // AngelNotch uses a non-activating panel. Bring the accessory app
      // forward so macOS can present its Calendar consent sheet visibly.
      NSApp.activate(ignoringOtherApps: true)
      store.requestFullAccessToEvents { [weak self] granted, error in
        Task { @MainActor [weak self] in
          guard let self else { return }
          self.isRequestingAccess = false
          self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
          self.refresh()

          if !granted, self.authorizationStatus == .notDetermined {
            self.accessError =
              error?.localizedDescription
              ?? "Calendar access could not be requested."
          }
        }
      }
    case .denied, .writeOnly:
      openCalendarSettings()
    case .restricted:
      accessError = "Calendar access is restricted on this Mac."
    case .fullAccess:
      accessError = nil
      refresh()
    @unknown default:
      openCalendarSettings()
    }
  }

  func refresh() {
    authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    guard canReadEvents else {
      nextEvent = nil
      return
    }

    accessError = nil
    let start = Date().addingTimeInterval(-2 * 60 * 60)
    let end = Date().addingTimeInterval(7 * 24 * 60 * 60)
    let predicate = store.predicateForEvents(
      withStart: start,
      end: end,
      calendars: nil
    )

    let event = store.events(matching: predicate)
      .filter { !$0.isAllDay && $0.endDate > .now }
      .sorted { $0.startDate < $1.startDate }
      .first

    guard let event else {
      nextEvent = nil
      return
    }

    nextEvent = UpcomingEvent(
      id: event.eventIdentifier ?? UUID().uuidString,
      title: event.title ?? "Untitled event",
      startDate: event.startDate,
      endDate: event.endDate,
      calendarTitle: event.calendar.title,
      joinURL: meetingURL(for: event)
    )
  }

  func joinNextEvent() {
    guard let url = nextEvent?.joinURL else { return }
    NSWorkspace.shared.open(url)
  }

  private func openCalendarSettings() {
    guard
      let url = URL(
        string:
          "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
      ),
      NSWorkspace.shared.open(url)
    else {
      accessError = "Open System Settings and allow AngelNotch under Calendars."
      return
    }

    accessError = nil
    settingsRefreshTask?.cancel()
    settingsRefreshTask = Task { @MainActor [weak self] in
      // System Settings changes do not invoke EventKit's request callback.
      // Poll briefly so the panel updates as soon as the user grants access.
      for _ in 0..<120 {
        try? await Task.sleep(for: .seconds(1))
        guard !Task.isCancelled, let self else { return }
        self.refresh()
        if self.canReadEvents { return }
      }
    }
  }

  private func meetingURL(for event: EKEvent) -> URL? {
    if let url = event.url, isMeetingURL(url) {
      return url
    }

    let candidates = [event.location, event.notes]
      .compactMap { $0 }
      .joined(separator: "\n")

    guard
      let detector = try? NSDataDetector(
        types: NSTextCheckingResult.CheckingType.link.rawValue
      )
    else {
      return nil
    }

    let range = NSRange(candidates.startIndex..., in: candidates)
    return detector.matches(in: candidates, options: [], range: range)
      .compactMap(\.url)
      .first(where: isMeetingURL)
  }

  private func isMeetingURL(_ url: URL) -> Bool {
    let host = url.host?.lowercased() ?? ""
    return [
      "zoom.us",
      "meet.google.com",
      "teams.microsoft.com",
      "webex.com",
      "whereby.com",
    ].contains { host.contains($0) }
  }
}
