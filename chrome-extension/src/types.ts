export interface YouTubePlaybackState {
  title: string;
  artist: string;
  album: "YouTube" | "YouTube Music";
  isPlaying: boolean;
  artworkURL: string | null;
  duration: number;
  position: number;
  volume: number;
}

export interface YouTubeStateMessage {
  type: "youtube-state";
  payload: YouTubePlaybackState;
}

export type PlaybackCommandName = "playPause" | "seek" | "seekBy" | "volume";

export interface PlaybackCommand {
  command: PlaybackCommandName;
  value?: number;
}

export interface AngelNotchCommandMessage {
  type: "angelnotch-command";
  payload: PlaybackCommand;
}

export interface NativeCommandResponse {
  command?: PlaybackCommandName;
  value?: number;
}

export interface DownloadPayload {
  id: string;
  filename: string;
  bytesReceived: number;
  totalBytes: number;
  state: string;
}

export interface NativeStateEnvelope {
  type: "state";
  payload: YouTubePlaybackState;
}

export interface NativeDownloadEnvelope {
  type: "download";
  download: DownloadPayload;
}
