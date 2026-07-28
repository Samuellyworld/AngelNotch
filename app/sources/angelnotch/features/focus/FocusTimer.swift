import AVFoundation
import AppKit
import Foundation

enum FocusPhase: String, Codable, Sendable {
  case idle
  case focus
  case shortBreak
  case longBreak

  var title: String {
    switch self {
    case .idle: "Focus"
    case .focus: "Focus session"
    case .shortBreak: "Short break"
    case .longBreak: "Long break"
    }
  }

  var symbolName: String {
    switch self {
    case .idle: "timer"
    case .focus: "brain.head.profile"
    case .shortBreak, .longBreak: "cup.and.saucer.fill"
    }
  }
}

@MainActor
final class FocusTimer: ObservableObject {
  @Published private(set) var phase: FocusPhase = .idle
  @Published private(set) var remainingSeconds = 25 * 60
  @Published private(set) var isRunning = false
  @Published private(set) var completedSessions = 0

  @Published var focusMinutes: Int {
    didSet {
      defaults.set(focusMinutes, forKey: "focus.minutes")
      if phase == .idle, !isRunning {
        remainingSeconds = focusMinutes * 60
        persistRuntime()
      }
    }
  }
  @Published var shortBreakMinutes: Int {
    didSet { defaults.set(shortBreakMinutes, forKey: "focus.shortBreak") }
  }
  @Published var longBreakMinutes: Int {
    didSet { defaults.set(longBreakMinutes, forKey: "focus.longBreak") }
  }
  @Published var completionSoundEnabled: Bool {
    didSet {
      defaults.set(
        completionSoundEnabled,
        forKey: "focus.completionSoundEnabled"
      )
    }
  }

  private let defaults = UserDefaults.standard
  private var deadline: Date?
  private var tickTask: Task<Void, Never>?
  private var completionSoundTask: Task<Void, Never>?
  private var completionAudioPlayer: AVAudioPlayer?
  private let completionSpeaker = AVSpeechSynthesizer()

  init() {
    let focus = defaults.integer(forKey: "focus.minutes")
    let shortBreak = defaults.integer(forKey: "focus.shortBreak")
    let longBreak = defaults.integer(forKey: "focus.longBreak")
    focusMinutes = focus == 0 ? 25 : focus
    shortBreakMinutes = shortBreak == 0 ? 5 : shortBreak
    longBreakMinutes = longBreak == 0 ? 15 : longBreak
    completionSoundEnabled =
      defaults.object(
        forKey: "focus.completionSoundEnabled"
      ) as? Bool ?? true
    completedSessions = defaults.integer(forKey: "focus.completedSessions")
    restore()
  }

  var formattedRemaining: String {
    let hours = remainingSeconds / 3_600
    let minutes = (remainingSeconds % 3_600) / 60
    let seconds = remainingSeconds % 60
    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    return String(format: "%02d:%02d", minutes, seconds)
  }

  var canEditDuration: Bool {
    phase == .idle && !isRunning
  }

  func setFocusDuration(_ minutes: Int) {
    guard canEditDuration else { return }
    focusMinutes = min(180, max(1, minutes))
  }

  var progress: Double {
    let total = Double(duration(for: phase))
    guard total > 0 else { return 0 }
    return 1 - (Double(remainingSeconds) / total)
  }

  func startFocus() {
    begin(.focus)
  }

  func toggleRunning() {
    if isRunning {
      pause()
    } else if phase == .idle {
      startFocus()
    } else {
      resume()
    }
  }

  func skip() {
    completeCurrentPhase(playSound: false)
  }

  func reset() {
    deadline = nil
    phase = .idle
    isRunning = false
    remainingSeconds = focusMinutes * 60
    tickTask?.cancel()
    persistRuntime()
  }

  private func begin(_ newPhase: FocusPhase) {
    phase = newPhase
    remainingSeconds = duration(for: newPhase)
    isRunning = true
    deadline = Date().addingTimeInterval(TimeInterval(remainingSeconds))
    startTicking()
    persistRuntime()
  }

  private func pause() {
    updateRemaining()
    isRunning = false
    deadline = nil
    tickTask?.cancel()
    persistRuntime()
  }

  private func resume() {
    isRunning = true
    deadline = Date().addingTimeInterval(TimeInterval(remainingSeconds))
    startTicking()
    persistRuntime()
  }

  private func startTicking() {
    tickTask?.cancel()
    tickTask = Task { @MainActor [weak self] in
      while !Task.isCancelled {
        self?.updateRemaining()
        if self?.remainingSeconds == 0 {
          self?.completeCurrentPhase(playSound: true)
          return
        }
        try? await Task.sleep(for: .seconds(1))
      }
    }
  }

  private func updateRemaining() {
    guard isRunning, let deadline else { return }
    remainingSeconds = max(0, Int(ceil(deadline.timeIntervalSinceNow)))
  }

  private func completeCurrentPhase(playSound: Bool) {
    tickTask?.cancel()
    if playSound, completionSoundEnabled {
      playCompletionSound(for: phase)
    }
    if phase == .focus {
      completedSessions += 1
      defaults.set(completedSessions, forKey: "focus.completedSessions")
      begin(completedSessions.isMultiple(of: 4) ? .longBreak : .shortBreak)
    } else {
      begin(.focus)
    }
  }

  private func playCompletionSound(for completedPhase: FocusPhase) {
    completionSoundTask?.cancel()
    completionAudioPlayer?.stop()
    completionAudioPlayer = nil
    completionSpeaker.stopSpeaking(at: .immediate)

    let announcement =
      completedPhase == .focus
      ? "Focus session complete. Great work. It is time to take a break."
      : "Break complete. Your next focus session is ready."
    let audioName =
      completedPhase == .focus
      ? "focus-complete-idera"
      : "break-complete-idera"

    completionSoundTask = Task { @MainActor [weak self] in
      guard let self else { return }

      if NSSound(named: NSSound.Name("Glass"))?.play() != true {
        NSSound.beep()
      }
      try? await Task.sleep(for: .milliseconds(700))
      guard !Task.isCancelled else { return }

      if let audioURL = Bundle.main.url(
        forResource: audioName,
        withExtension: "mp3",
        subdirectory: "media"
      ),
        let player = try? AVAudioPlayer(contentsOf: audioURL)
      {
        completionAudioPlayer = player
        player.volume = 1
        player.prepareToPlay()
        player.play()

        while player.isPlaying {
          if Task.isCancelled {
            player.stop()
            completionAudioPlayer = nil
            return
          }
          try? await Task.sleep(for: .milliseconds(200))
        }
        completionAudioPlayer = nil
      } else {
        speakFallback(announcement)
        while completionSpeaker.isSpeaking {
          if Task.isCancelled {
            completionSpeaker.stopSpeaking(at: .immediate)
            return
          }
          try? await Task.sleep(for: .milliseconds(200))
        }
      }

      guard !Task.isCancelled else { return }
      _ = NSSound(named: NSSound.Name("Ping"))?.play()
    }
  }

  private func speakFallback(_ announcement: String) {
    let utterance = AVSpeechUtterance(string: announcement)
    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
    utterance.volume = 1
    utterance.rate = 0.47
    utterance.preUtteranceDelay = 0.08
    utterance.postUtteranceDelay = 0.18
    completionSpeaker.speak(utterance)
  }

  private func duration(for phase: FocusPhase) -> Int {
    switch phase {
    case .idle, .focus: focusMinutes * 60
    case .shortBreak: shortBreakMinutes * 60
    case .longBreak: longBreakMinutes * 60
    }
  }

  private func restore() {
    guard
      let phaseRaw = defaults.string(forKey: "focus.phase"),
      let restoredPhase = FocusPhase(rawValue: phaseRaw)
    else {
      remainingSeconds = focusMinutes * 60
      return
    }

    phase = restoredPhase
    remainingSeconds = max(
      0,
      defaults.integer(forKey: "focus.remainingSeconds")
    )
    isRunning = defaults.bool(forKey: "focus.running")

    if isRunning,
      let deadlineValue = defaults.object(forKey: "focus.deadline") as? Date
    {
      deadline = deadlineValue
      updateRemaining()
      if remainingSeconds > 0 {
        startTicking()
      } else {
        completeCurrentPhase(playSound: false)
      }
    }
  }

  private func persistRuntime() {
    defaults.set(phase.rawValue, forKey: "focus.phase")
    defaults.set(remainingSeconds, forKey: "focus.remainingSeconds")
    defaults.set(isRunning, forKey: "focus.running")
    defaults.set(deadline, forKey: "focus.deadline")
  }
}
