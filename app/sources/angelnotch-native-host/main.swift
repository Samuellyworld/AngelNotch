import Foundation

struct YouTubePayload: Decodable {
  let title: String
  let artist: String
  let album: String?
  let isPlaying: Bool
  let artworkURL: String?
  let duration: Double
  let position: Double
  let volume: Double
}

struct HostMessage: Decodable {
  let type: String
  let payload: YouTubePayload?
  let download: DownloadPayload?
}

struct DownloadPayload: Decodable {
  let id: String
  let filename: String
  let bytesReceived: Double
  let totalBytes: Double
  let state: String
}

struct NativeMediaSnapshot: Encodable {
  let source = "youtube"
  let title: String
  let artist: String
  let album: String
  let isPlaying: Bool
  let artworkURL: URL?
  let duration: Double
  let position: Double
  let volume: Double
  let lyrics: String? = nil
  let updatedAt: Date
}

struct NativeLoopActivity: Encodable {
  let id: String
  let kind = "download"
  let title: String
  let detail: String
  let progress: Double?
  let updatedAt: Date
  let isComplete: Bool
}

let input = FileHandle.standardInput
let output = FileHandle.standardOutput

guard
  let lengthData = try? input.read(upToCount: 4),
  lengthData.count == 4
else {
  exit(0)
}

let length = lengthData.withUnsafeBytes { rawBuffer in
  rawBuffer.loadUnaligned(as: UInt32.self).littleEndian
}

guard length > 0, length <= 1_048_576 else {
  exit(0)
}

guard
  let messageData = try? input.read(upToCount: Int(length)),
  messageData.count == Int(length),
  let message = try? JSONDecoder().decode(HostMessage.self, from: messageData)
else {
  exit(0)
}

let root: URL
if let override = ProcessInfo.processInfo.environment["ANGELNOTCH_STORAGE_ROOT"] {
  root = URL(fileURLWithPath: override, isDirectory: true)
} else {
  let base =
    FileManager.default.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    ).first ?? FileManager.default.temporaryDirectory
  root = base.appending(path: "AngelNotch", directoryHint: .isDirectory)
}
try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

if message.type == "state", let payload = message.payload {
  let snapshot = NativeMediaSnapshot(
    title: payload.title,
    artist: payload.artist,
    album: payload.album ?? "YouTube",
    isPlaying: payload.isPlaying,
    artworkURL: payload.artworkURL.flatMap(URL.init(string:)),
    duration: payload.duration,
    position: payload.position,
    volume: payload.volume,
    updatedAt: .now
  )
  let encoder = JSONEncoder()
  encoder.dateEncodingStrategy = .iso8601
  if let data = try? encoder.encode(snapshot) {
    try? data.write(
      to: root.appending(path: "youtube-state.json"),
      options: .atomic
    )
  }
}

if message.type == "download", let download = message.download {
  let progress =
    download.totalBytes > 0
    ? min(1, download.bytesReceived / download.totalBytes)
    : nil
  let formatter = ByteCountFormatter()
  formatter.countStyle = .file
  let received = formatter.string(fromByteCount: Int64(download.bytesReceived))
  let total =
    download.totalBytes > 0
    ? formatter.string(fromByteCount: Int64(download.totalBytes))
    : "Unknown size"
  let activity = NativeLoopActivity(
    id: "chrome-download-\(download.id)",
    title: download.filename,
    detail: "\(received) of \(total)",
    progress: progress,
    updatedAt: .now,
    isComplete: download.state == "complete"
  )
  let encoder = JSONEncoder()
  encoder.dateEncodingStrategy = .iso8601
  if let data = try? encoder.encode(activity) {
    try? data.write(
      to: root.appending(path: "download-activity.json"),
      options: .atomic
    )
  }
}

let commandURL = root.appending(path: "youtube-command.json")
let response: Data
if let command = try? Data(contentsOf: commandURL) {
  response = command
  try? FileManager.default.removeItem(at: commandURL)
} else {
  response = Data(#"{"command":null}"#.utf8)
}

var responseLength = UInt32(response.count).littleEndian
output.write(Data(bytes: &responseLength, count: 4))
output.write(response)
