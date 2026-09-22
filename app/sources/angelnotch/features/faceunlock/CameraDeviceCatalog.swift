import AVFoundation
import AppKit

struct CameraDevice: Identifiable, Hashable {
  let id: String
  let name: String
}

enum CameraDeviceCatalog {
  static func availableDevices() -> [CameraDevice] {
    let discovery = AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera],
      mediaType: .video,
      position: .unspecified
    )
    return discovery.devices.map { CameraDevice(id: $0.uniqueID, name: $0.localizedName) }
  }

  static func isUsingBuiltInDisplay() -> Bool {
    guard let screen = NSScreen.main,
      let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")]
        as? CGDirectDisplayID
    else { return true }
    return CGDisplayIsBuiltin(screenNumber) != 0
  }

  static func resolvedDevice() -> AVCaptureDevice? {
    return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
      ?? AVCaptureDevice.default(for: .video)
  }
}
