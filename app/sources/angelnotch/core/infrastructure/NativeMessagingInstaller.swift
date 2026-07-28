import Foundation

/// Registers the bundled browser bridge with Google Chrome.
enum NativeMessagingInstaller {
  private static let hostName = "com.angelnotch.youtube"
  private static let extensionOrigin =
    "chrome-extension://fiaklbabbciligidldojbndobojmgbae/"

  static func installIfAvailable() {
    let hostURL = Bundle.main.bundleURL
      .appending(path: "Contents/MacOS/AngelNotchNativeHost")
    guard FileManager.default.isExecutableFile(atPath: hostURL.path) else {
      return
    }

    let manifest = NativeMessagingManifest(
      name: hostName,
      description: "AngelNotch YouTube media bridge",
      path: hostURL.path,
      type: "stdio",
      allowedOrigins: [extensionOrigin]
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    guard let data = try? encoder.encode(manifest) else { return }

    let directory = manifestDirectory
    do {
      try FileManager.default.createDirectory(
        at: directory,
        withIntermediateDirectories: true
      )
      try data.write(
        to: directory.appending(path: "\(hostName).json"),
        options: .atomic
      )
    } catch {
      NSLog(
        "AngelNotch could not register its browser bridge at %@: %@",
        directory.path,
        error.localizedDescription
      )
    }
  }

  private static var manifestDirectory: URL {
    FileManager.default.homeDirectoryForCurrentUser
      .appending(path: "Library/Application Support/Google/Chrome")
      .appending(path: "NativeMessagingHosts")
  }
}

private struct NativeMessagingManifest: Encodable {
  let name: String
  let description: String
  let path: String
  let type: String
  let allowedOrigins: [String]

  private enum CodingKeys: String, CodingKey {
    case name
    case description
    case path
    case type
    case allowedOrigins = "allowed_origins"
  }
}
