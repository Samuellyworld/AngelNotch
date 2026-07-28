import AppKit
import Foundation

enum MediaSource: String, Codable, Sendable {
  case spotify
  case appleMusic
  case youtube

  var displayName: String {
    switch self {
    case .spotify: "Spotify"
    case .appleMusic: "Apple Music"
    case .youtube: "YouTube"
    }
  }

  var symbolName: String {
    switch self {
    case .spotify: "music.note"
    case .appleMusic: "apple.logo"
    case .youtube: "play.rectangle.fill"
    }
  }
}

enum MediaRepeatMode: String, Codable, Sendable {
  case off
  case all
  case one
}

struct MediaSnapshot: Equatable, Codable, Sendable {
  let source: MediaSource
  let title: String
  let artist: String
  let album: String
  let isPlaying: Bool
  let artworkURL: URL?
  let duration: Double
  let position: Double
  let volume: Double
  let lyrics: String?
  let isShuffling: Bool?
  let repeatMode: MediaRepeatMode?
  let trackURL: URL?
  let updatedAt: Date

  var trackID: String {
    "\(source.rawValue)|\(artist)|\(title)|\(album)"
  }

  var progress: Double {
    guard duration > 0 else { return 0 }
    return min(1, max(0, position / duration))
  }
}

enum MediaCommand: Sendable {
  case previous
  case playPause
  case next
  case seek(Double)
  case setVolume(Double)
  case toggleShuffle
  case setRepeat(MediaRepeatMode)
}

/// Polls supported media apps without retaining listening history.
@MainActor
final class MediaMonitor: ObservableObject {
  @Published private(set) var snapshot: MediaSnapshot?

  private var monitorTask: Task<Void, Never>?

  func start() {
    guard monitorTask == nil else { return }

    monitorTask = Task { @MainActor [weak self] in
      while !Task.isCancelled {
        let latest = await Task.detached(priority: .utility) {
          Self.fetchSnapshot()
        }.value

        self?.snapshot = latest

        try? await Task.sleep(
          for: .milliseconds(latest?.isPlaying == true ? 500 : 1_250)
        )
      }
    }
  }

  func send(_ command: MediaCommand) {
    guard let source = snapshot?.source else { return }

    if source == .youtube {
      Self.queueYouTubeCommand(command)
    } else {
      Task.detached(priority: .userInitiated) {
        Self.runCommand(command, for: source)
      }
    }
  }

  func seek(to position: Double) {
    send(.seek(position))
  }

  func setVolume(_ volume: Double) {
    send(.setVolume(volume))
  }

  func openCurrentTrack() {
    guard let snapshot else { return }
    if let trackURL = snapshot.trackURL {
      NSWorkspace.shared.open(trackURL)
      return
    }

    let bundleIdentifier: String
    switch snapshot.source {
    case .spotify:
      bundleIdentifier = "com.spotify.client"
    case .appleMusic:
      bundleIdentifier = "com.apple.Music"
    case .youtube:
      bundleIdentifier = "com.google.Chrome"
    }

    guard
      let appURL = NSWorkspace.shared.urlForApplication(
        withBundleIdentifier: bundleIdentifier
      )
    else { return }
    NSWorkspace.shared.open(appURL)
  }

  func copyCurrentTrack() {
    guard let snapshot else { return }
    var text = "\(snapshot.title) — \(snapshot.artist)"
    if let trackURL = snapshot.trackURL {
      text += "\n\(trackURL.absoluteString)"
    }
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
  }

  private nonisolated static func fetchSnapshot() -> MediaSnapshot? {
    if let native = fetchNativeAppSnapshot() {
      return native
    }
    return fetchYouTubeSnapshot()
  }

  private nonisolated static func fetchNativeAppSnapshot() -> MediaSnapshot? {
    guard let output = runAppleScript(mediaQueryScript), !output.isEmpty else {
      return nil
    }

    let fields = output.components(separatedBy: "|||")
    guard fields.count >= 12, let source = MediaSource(rawValue: fields[0]) else {
      return nil
    }

    let lyrics =
      fields.count > 12
      ? fields[12...].joined(separator: "|||").trimmingCharacters(
        in: .whitespacesAndNewlines
      )
      : ""

    return MediaSnapshot(
      source: source,
      title: fields[2],
      artist: fields[3],
      album: fields[4],
      isPlaying: fields[1] == "playing",
      artworkURL: fields[8].isEmpty ? nil : URL(string: fields[8]),
      duration: Double(fields[5]) ?? 0,
      position: Double(fields[6]) ?? 0,
      volume: (Double(fields[7]) ?? 100) / 100,
      lyrics: lyrics.isEmpty ? nil : lyrics,
      isShuffling: fields[9] == "true",
      repeatMode: MediaRepeatMode(rawValue: fields[10]) ?? .off,
      trackURL: fields[11].isEmpty ? nil : URL(string: fields[11]),
      updatedAt: .now
    )
  }

  private nonisolated static func fetchYouTubeSnapshot() -> MediaSnapshot? {
    let url = StoragePaths.root.appending(path: "youtube-state.json")
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    guard
      let data = try? Data(contentsOf: url),
      let snapshot = try? decoder.decode(MediaSnapshot.self, from: data),
      Date().timeIntervalSince(snapshot.updatedAt) < 8
    else {
      return nil
    }
    return snapshot
  }

  private nonisolated static func queueYouTubeCommand(_ command: MediaCommand) {
    let payload: [String: Any]
    switch command {
    case .previous:
      payload = ["command": "seekBy", "value": -10]
    case .playPause:
      payload = ["command": "playPause"]
    case .next:
      payload = ["command": "seekBy", "value": 10]
    case .seek(let position):
      payload = ["command": "seek", "value": position]
    case .setVolume(let volume):
      payload = ["command": "volume", "value": volume]
    case .toggleShuffle, .setRepeat:
      return
    }
    guard let data = try? JSONSerialization.data(withJSONObject: payload) else {
      return
    }
    try? data.write(
      to: StoragePaths.root.appending(path: "youtube-command.json"),
      options: .atomic
    )
  }

  private nonisolated static func runCommand(
    _ command: MediaCommand,
    for source: MediaSource
  ) {
    let appName = source == .spotify ? "Spotify" : "Music"
    let action: String

    switch command {
    case .previous:
      action = "previous track"
    case .playPause:
      action = "playpause"
    case .next:
      action = "next track"
    case .seek(let position):
      action = "set player position to \(max(0, position))"
    case .setVolume(let volume):
      action = "set sound volume to \(Int(max(0, min(1, volume)) * 100))"
    case .toggleShuffle:
      action =
        source == .spotify
        ? "set shuffling to not shuffling"
        : "set shuffle enabled to not shuffle enabled"
    case .setRepeat(let mode):
      if source == .spotify {
        action = "set repeating to \(mode == .off ? "false" : "true")"
      } else {
        action = "set song repeat to \(mode.rawValue)"
      }
    }

    _ = runAppleScript(
      """
      if application "\(appName)" is running then
          tell application "\(appName)" to \(action)
      end if
      """
    )
  }

  private nonisolated static func runAppleScript(_ source: String) -> String? {
    let process = Process()
    let outputPipe = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-e", source]
    process.standardOutput = outputPipe
    process.standardError = Pipe()

    do {
      try process.run()
      process.waitUntilExit()
    } catch {
      return nil
    }

    guard process.terminationStatus == 0 else { return nil }
    let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8)?
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private nonisolated static let mediaQueryScript = """
    if application "Spotify" is running then
        tell application "Spotify"
            if player state is not stopped then
                set trackName to name of current track
                set trackArtist to artist of current track
                set trackAlbum to album of current track
                set trackDuration to (duration of current track) / 1000
                set trackPosition to player position
                set trackVolume to sound volume
                set trackArtwork to artwork url of current track
                set shuffleState to false
                set repeatState to "off"
                set trackLink to ""
                try
                    set shuffleState to shuffling
                end try
                try
                    if repeating is true then set repeatState to "all"
                end try
                try
                    set trackLink to spotify url of current track
                end try
                return "spotify|||" & (player state as text) & "|||" & trackName & "|||" & trackArtist & "|||" & trackAlbum & "|||" & trackDuration & "|||" & trackPosition & "|||" & trackVolume & "|||" & trackArtwork & "|||" & shuffleState & "|||" & repeatState & "|||" & trackLink & "|||"
            end if
        end tell
    end if

    if application "Music" is running then
        tell application "Music"
            if player state is not stopped then
                set trackName to name of current track
                set trackArtist to artist of current track
                set trackAlbum to album of current track
                set trackDuration to duration of current track
                set trackPosition to player position
                set trackVolume to sound volume
                set trackLyrics to ""
                set shuffleState to false
                set repeatState to "off"
                try
                    set trackLyrics to lyrics of current track
                end try
                try
                    set shuffleState to shuffle enabled
                end try
                try
                    set repeatState to song repeat as text
                end try
                return "appleMusic|||" & (player state as text) & "|||" & trackName & "|||" & trackArtist & "|||" & trackAlbum & "|||" & trackDuration & "|||" & trackPosition & "|||" & trackVolume & "||||||" & shuffleState & "|||" & repeatState & "||||||" & trackLyrics
            end if
        end tell
    end if

    return ""
    """
}
