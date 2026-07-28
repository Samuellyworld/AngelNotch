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

  private let store = EKEventStore()
  private var monitorTask: Task<Void, Never>?

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
  }

  func requestAccess() {
    store.requestFullAccessToEvents { [weak self] _, _ in
      Task { @MainActor [weak self] in
        guard let self else { return }
        self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        self.refresh()
      }
    }
  }

  func refresh() {
    authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    guard canReadEvents else {
      nextEvent = nil
      return
    }

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
