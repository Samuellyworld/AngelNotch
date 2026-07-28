import Foundation

enum StoragePaths {
  static let root: URL = {
    if let override = ProcessInfo.processInfo.environment["ANGELNOTCH_STORAGE_ROOT"] {
      let url = URL(fileURLWithPath: override, isDirectory: true)
      try? FileManager.default.createDirectory(
        at: url,
        withIntermediateDirectories: true
      )
      return url
    }

    let base =
      FileManager.default.urls(
        for: .applicationSupportDirectory,
        in: .userDomainMask
      ).first ?? FileManager.default.temporaryDirectory
    let url = base.appending(path: "AngelNotch", directoryHint: .isDirectory)
    try? FileManager.default.createDirectory(
      at: url,
      withIntermediateDirectories: true
    )
    return url
  }()

  static func load<T: Decodable>(_ type: T.Type, from filename: String) -> T? {
    let url = root.appending(path: filename)
    guard let data = try? Data(contentsOf: url) else { return nil }
    return try? JSONDecoder.angelNotch.decode(type, from: data)
  }

  static func save<T: Encodable>(_ value: T, to filename: String) {
    let url = root.appending(path: filename)
    guard let data = try? JSONEncoder.angelNotch.encode(value) else { return }
    try? data.write(to: url, options: .atomic)
  }
}

extension JSONEncoder {
  fileprivate static var angelNotch: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    return encoder
  }
}

extension JSONDecoder {
  fileprivate static var angelNotch: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }
}
