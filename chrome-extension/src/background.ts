import type {
  DownloadPayload,
  NativeCommandResponse,
  NativeDownloadEnvelope,
  NativeStateEnvelope,
  AngelNotchCommandMessage,
  YouTubeStateMessage,
} from "./types";

const HOST_NAME = "com.angelnotch.youtube";

function isYouTubeStateMessage(value: unknown): value is YouTubeStateMessage {
  if (!value || typeof value !== "object") return false;
  const candidate = value as Partial<YouTubeStateMessage>;
  return candidate.type === "youtube-state" && candidate.payload !== undefined;
}

chrome.runtime.onMessage.addListener(
  (message: unknown, sender: chrome.runtime.MessageSender): void => {
    if (!isYouTubeStateMessage(message) || sender.tab?.id === undefined) return;

    const tabID = sender.tab.id;
    const envelope: NativeStateEnvelope = {
      type: "state",
      payload: message.payload,
    };

    chrome.runtime.sendNativeMessage(
      HOST_NAME,
      envelope,
      (response: NativeCommandResponse | undefined): void => {
        if (chrome.runtime.lastError || !response?.command) return;

        const payload =
          response.value === undefined
            ? { command: response.command }
            : { command: response.command, value: response.value };
        const command: AngelNotchCommandMessage = {
          type: "angelnotch-command",
          payload,
        };
        void chrome.tabs.sendMessage(tabID, command);
      },
    );
  },
);

function fileName(path: string | undefined): string {
  return path?.split("/").pop() || "Download";
}

function publishDownload(download?: chrome.downloads.DownloadItem): void {
  if (!download) return;

  const payload: DownloadPayload = {
    id: String(download.id),
    filename: fileName(download.filename),
    bytesReceived: download.bytesReceived || 0,
    totalBytes: download.totalBytes || 0,
    state: download.state || "in_progress",
  };
  const envelope: NativeDownloadEnvelope = {
    type: "download",
    download: payload,
  };

  chrome.runtime.sendNativeMessage(HOST_NAME, envelope);
}

chrome.downloads.onCreated.addListener(publishDownload);
chrome.downloads.onChanged.addListener((delta): void => {
  void chrome.downloads.search({ id: delta.id }).then(([download]) => {
    publishDownload(download);
  });
});
