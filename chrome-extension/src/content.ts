import type {
  AngelNotchCommandMessage,
  PlaybackCommand,
  YouTubePlaybackState,
  YouTubeStateMessage,
} from "./types";

function readText(...selectors: string[]): string {
  for (const selector of selectors) {
    const value = document.querySelector(selector)?.textContent?.trim();
    if (value) return value;
  }
  return "";
}

function currentVideo(): HTMLVideoElement | null {
  return document.querySelector<HTMLVideoElement>("video");
}

function metadataContent(selector: string): string | null {
  return document.querySelector<HTMLMetaElement>(selector)?.content ?? null;
}

function publishState(): void {
  const video = currentVideo();
  if (!video || !Number.isFinite(video.duration)) return;

  const title =
    readText(
      "ytd-watch-metadata h1 yt-formatted-string",
      "ytmusic-player-bar .title",
      "meta[name='title']",
    ) || document.title.replace(/\s*-\s*YouTube.*$/, "");

  const artist =
    readText(
      "ytd-watch-metadata ytd-channel-name a",
      "ytmusic-player-bar .byline",
      "#upload-info #channel-name a",
    ) || "YouTube";

  const state: YouTubePlaybackState = {
    title,
    artist,
    album:
      location.hostname === "music.youtube.com" ? "YouTube Music" : "YouTube",
    isPlaying: !video.paused && !video.ended,
    artworkURL: metadataContent("meta[property='og:image']"),
    duration: video.duration || 0,
    position: video.currentTime || 0,
    volume: video.muted ? 0 : video.volume,
  };
  const message: YouTubeStateMessage = {
    type: "youtube-state",
    payload: state,
  };

  void chrome.runtime.sendMessage(message);
}

function isCommandMessage(value: unknown): value is AngelNotchCommandMessage {
  if (!value || typeof value !== "object") return false;
  const candidate = value as Partial<AngelNotchCommandMessage>;
  return candidate.type === "angelnotch-command" && candidate.payload !== undefined;
}

function applyCommand(video: HTMLVideoElement, command: PlaybackCommand): void {
  const value = command.value ?? 0;
  switch (command.command) {
    case "playPause":
      if (video.paused) {
        void video.play();
      } else {
        video.pause();
      }
      break;
    case "seek":
      video.currentTime = Math.max(0, Math.min(video.duration || value, value));
      break;
    case "seekBy":
      video.currentTime = Math.max(
        0,
        Math.min(
          video.duration || video.currentTime + value,
          video.currentTime + value,
        ),
      );
      break;
    case "volume":
      video.muted = false;
      video.volume = Math.max(0, Math.min(1, value));
      break;
  }
}

chrome.runtime.onMessage.addListener((message: unknown): void => {
  if (!isCommandMessage(message)) return;
  const video = currentVideo();
  if (video) applyCommand(video, message.payload);
});

window.setInterval(publishState, 900);
document.addEventListener("play", publishState, true);
document.addEventListener("pause", publishState, true);
publishState();
