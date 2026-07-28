import SwiftUI

struct MediaPanel: View {
  let snapshot: MediaSnapshot
  @ObservedObject var media: MediaMonitor
  @ObservedObject var system: SystemMonitor
  let reducedMotion: Bool

  @State private var seekPosition = 0.0
  @State private var mediaVolume = 1.0
  @State private var isScrubbing = false

  private var accent: Color {
    mediaColor(snapshot.source)
  }

  var body: some View {
    VStack(spacing: 8) {
      nowPlaying
      timeline
      controlDock
      lyricsFooter
    }
    .padding(12)
    .background(
      LoopDesign.Palette.surfaceQuiet,
      in: RoundedRectangle(cornerRadius: 17, style: .continuous)
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .onAppear {
      seekPosition = snapshot.position
      mediaVolume = snapshot.volume
    }
    .onChange(of: snapshot.position) { _, value in
      if !isScrubbing {
        seekPosition = value
      }
    }
    .onChange(of: snapshot.volume) { _, value in
      mediaVolume = value
    }
  }

  private var nowPlaying: some View {
    HStack(spacing: 11) {
      MediaArtwork(
        snapshot: snapshot,
        size: 52,
        animated: snapshot.isPlaying && !reducedMotion
      )

      VStack(alignment: .leading, spacing: 3) {
        HStack(spacing: 5) {
          Circle()
            .fill(accent)
            .frame(width: 5, height: 5)
          Text(snapshot.source.displayName)
          Text("·")
          Text(snapshot.isPlaying ? "Playing" : "Paused")
        }
        .font(.system(size: 9, weight: .medium))
        .foregroundStyle(accent)

        Text(snapshot.title)
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(LoopDesign.Palette.textPrimary)
          .lineLimit(1)

        HStack(spacing: 5) {
          Text(snapshot.artist)
          if !snapshot.album.isEmpty {
            Text("·")
              .foregroundStyle(LoopDesign.Palette.textTertiary)
            Text(snapshot.album)
          }
        }
        .font(LoopDesign.TypeStyle.label)
        .foregroundStyle(LoopDesign.Palette.textSecondary)
        .lineLimit(1)
      }

      Spacer(minLength: 8)

      HStack(spacing: 6) {
        Menu {
          Button(
            "Open in \(snapshot.source.displayName)",
            systemImage: "arrow.up.forward.app"
          ) {
            media.openCurrentTrack()
          }
          Button("Copy track details", systemImage: "doc.on.doc") {
            media.copyCurrentTrack()
          }
          if snapshot.source != .youtube {
            Divider()
            Button(
              snapshot.isShuffling == true
                ? "Turn shuffle off"
                : "Turn shuffle on",
              systemImage: "shuffle"
            ) {
              media.send(.toggleShuffle)
            }
            Button(
              "Repeat: \(repeatModeTitle)",
              systemImage: repeatSymbol
            ) {
              media.send(.setRepeat(nextRepeatMode))
            }
          }
        } label: {
          Image(systemName: "ellipsis")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(LoopDesign.Palette.textSecondary)
            .frame(width: 28, height: 28)
            .background(
              LoopDesign.Palette.surface,
              in: Circle()
            )
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .help("Track actions")
        .interactiveCursor()

        ZStack {
          RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(accent.opacity(0.11))
          AnimatedWaveform(
            color: accent,
            isPlaying: snapshot.isPlaying,
            reducedMotion: reducedMotion
          )
        }
        .frame(width: 34, height: 34)
      }
    }
    .frame(height: 54)
  }

  private var timeline: some View {
    VStack(spacing: 2) {
      Slider(
        value: $seekPosition,
        in: 0...max(1, snapshot.duration),
        onEditingChanged: { editing in
          isScrubbing = editing
          if !editing {
            media.seek(to: seekPosition)
          }
        }
      )
      .controlSize(.small)
      .tint(accent)

      HStack {
        timeLabel(seekPosition)
        Spacer()
        timeLabel(snapshot.duration)
      }
    }
  }

  private var controlDock: some View {
    HStack(spacing: 9) {
      HStack(spacing: 6) {
        MediaControlButton(
          systemImage: "backward.fill",
          size: 28
        ) {
          media.send(.previous)
        }
        MediaControlButton(
          systemImage: snapshot.isPlaying ? "pause.fill" : "play.fill",
          size: 38,
          emphasized: true,
          color: accent
        ) {
          media.send(.playPause)
        }
        MediaControlButton(
          systemImage: "forward.fill",
          size: 28
        ) {
          media.send(.next)
        }
      }

      Rectangle()
        .fill(LoopDesign.Palette.cream.opacity(0.08))
        .frame(width: 0.5, height: 24)

      Spacer(minLength: 0)

      HStack(spacing: 7) {
        Image(
          systemName: mediaVolume < 0.01
            ? "speaker.slash.fill"
            : "speaker.wave.2.fill"
        )
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(LoopDesign.Palette.textTertiary)

        Slider(value: $mediaVolume, in: 0...1) {
          Text("Media volume")
        } onEditingChanged: { editing in
          if !editing {
            media.setVolume(mediaVolume)
          }
        }
        .labelsHidden()
        .controlSize(.small)
        .tint(accent)
        .frame(width: 64)

        Menu {
          ForEach(system.outputDevices) { device in
            Button(device.name) {
              system.selectOutput(device)
            }
          }
        } label: {
          Image(systemName: "airplayaudio")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(LoopDesign.Palette.textSecondary)
            .frame(width: 30, height: 30)
            .background(
              LoopDesign.Palette.surfaceRaised,
              in: RoundedRectangle(cornerRadius: 10)
            )
        }
        .menuStyle(.borderlessButton)
        .help("Choose audio output")
        .interactiveCursor()
      }
    }
    .padding(.horizontal, 8)
    .frame(height: 48)
    .background(
      LoopDesign.Palette.surface,
      in: RoundedRectangle(cornerRadius: 14, style: .continuous)
    )
  }

  @ViewBuilder
  private var lyricsFooter: some View {
    if let lyrics = snapshot.lyrics, !lyrics.isEmpty {
      ScrollView {
        Text(lyrics)
          .font(LoopDesign.TypeStyle.detail)
          .foregroundStyle(LoopDesign.Palette.textSecondary)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(maxHeight: 30)
      .padding(.horizontal, 3)
    } else {
      HStack(spacing: 6) {
        Image(systemName: "quote.bubble")
        Text("Lyrics unavailable")
        Spacer()
        if snapshot.source == .spotify {
          Text("Spotify limits local access")
        }
      }
      .font(.system(size: 9))
      .foregroundStyle(LoopDesign.Palette.textTertiary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 3)
    }
  }

  private var repeatSymbol: String {
    snapshot.repeatMode == .one ? "repeat.1" : "repeat"
  }

  private var repeatModeTitle: String {
    switch snapshot.repeatMode ?? .off {
    case .off: "Off"
    case .all: "All"
    case .one: "One"
    }
  }

  private var nextRepeatMode: MediaRepeatMode {
    if snapshot.source == .spotify {
      return snapshot.repeatMode == .off ? .all : .off
    }
    switch snapshot.repeatMode ?? .off {
    case .off: return .all
    case .all: return .one
    case .one: return .off
    }
  }

  private func timeLabel(_ seconds: Double) -> some View {
    Text(time(seconds))
      .font(LoopDesign.TypeStyle.detail)
      .monospacedDigit()
      .foregroundStyle(LoopDesign.Palette.textSecondary)
  }

  private func time(_ seconds: Double) -> String {
    guard seconds.isFinite else { return "0:00" }
    return String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60)
  }
}
