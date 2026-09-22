@preconcurrency import AVFoundation
import Combine
@preconcurrency import CoreImage

enum CameraPermission {
  case notDetermined
  case granted
  case denied
}

struct CameraFrame {
  let id: UInt64
  let image: CGImage
  let source: CIImage
  let sourceSize: CGSize
}

@MainActor
final class CameraManager: NSObject, ObservableObject {
  @Published private(set) var permission: CameraPermission = .notDetermined
  @Published private(set) var isRunning: Bool = false
  @Published private(set) var currentFrame: CameraFrame?
  @Published private(set) var errorMessage: String?

  let session = AVCaptureSession()
  private let videoOutput = AVCaptureVideoDataOutput()
  private let sessionQueue = DispatchQueue(label: "com.angelnotch.face-unlock.camera.session")

  private let framePublisher = FramePublisher()

  override init() {
    super.init()
    framePublisher.owner = self
  }

  func start() async {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    switch status {
    case .authorized:
      permission = .granted
    case .notDetermined:
      let granted = await AVCaptureDevice.requestAccess(for: .video)
      permission = granted ? .granted : .denied
    default:
      permission = .denied
    }

    guard permission == .granted else {
      errorMessage =
        "Camera access not granted (status: \(describe(status))). "
        + (status == .restricted
          ? "macOS reports this as *restricted* — not a simple user denial. This usually means Screen Time content restrictions or an MDM/profile policy is blocking camera access for this app; toggling it in System Settings > Privacy & Security > Camera won't help until that restriction is lifted."
          : "Enable AngelNotch in System Settings > Privacy & Security > Camera, then relaunch the app.")
      return
    }

    errorMessage = nil
    configureSessionIfNeeded()
    reconcileDeviceIfNeeded()

    let started = await withCheckedContinuation { continuation in
      sessionQueue.async { [session] in
        if !session.isRunning {
          session.startRunning()
        }
        continuation.resume(returning: session.isRunning)
      }
    }
    isRunning = started
    if !started {
      errorMessage = "The camera did not start. Try locking your Mac again."
    }
  }

  func stop() {
    sessionQueue.async { [session] in
      if session.isRunning {
        session.stopRunning()
      }
    }
    isRunning = false
    currentFrame = nil
  }

  private func describe(_ status: AVAuthorizationStatus) -> String {
    switch status {
    case .notDetermined: return "notDetermined"
    case .restricted: return "restricted"
    case .denied: return "denied"
    case .authorized: return "authorized"
    @unknown default: return "unknown(\(status.rawValue))"
    }
  }

  private var isConfigured = false
  private var currentInput: AVCaptureDeviceInput?

  private func configureSessionIfNeeded() {
    guard !isConfigured else { return }
    isConfigured = true

    session.beginConfiguration()
    session.sessionPreset = .high

    videoOutput.videoSettings = [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
    ]
    videoOutput.alwaysDiscardsLateVideoFrames = true
    videoOutput.setSampleBufferDelegate(framePublisher, queue: sessionQueue)
    if session.canAddOutput(videoOutput) {
      session.addOutput(videoOutput)
    }

    session.commitConfiguration()
  }

  private func reconcileDeviceIfNeeded() {
    guard let device = CameraDeviceCatalog.resolvedDevice() else {
      errorMessage = "No camera device found."
      return
    }
    guard device.uniqueID != currentInput?.device.uniqueID else { return }

    session.beginConfiguration()
    if let currentInput {
      session.removeInput(currentInput)
    }
    if let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) {
      session.addInput(input)
      currentInput = input
      selectHighestResolutionFormat(for: device)
    } else {
      currentInput = nil
      errorMessage = "No camera device found."
    }
    session.commitConfiguration()
  }

  private func selectHighestResolutionFormat(for device: AVCaptureDevice) {
    let best = device.formats.max { lhs, rhs in
      let l = CMVideoFormatDescriptionGetDimensions(lhs.formatDescription)
      let r = CMVideoFormatDescriptionGetDimensions(rhs.formatDescription)
      return Int(l.width) * Int(l.height) < Int(r.width) * Int(r.height)
    }
    guard let best else { return }
    do {
      try device.lockForConfiguration()
      device.activeFormat = best
      device.unlockForConfiguration()
    } catch {
      errorMessage =
        "Couldn't select the camera's highest-resolution format: \(error.localizedDescription)"
    }
  }

  fileprivate func publish(frame: CameraFrame) {
    currentFrame = frame
  }

  nonisolated static func renderCrop(
    from frame: CameraFrame, imageRect: CGRect, maxEdge: CGFloat = 448
  ) -> CGImage? {
    let workingWidth = CGFloat(frame.image.width)
    let workingHeight = CGFloat(frame.image.height)
    guard workingWidth > 0, workingHeight > 0 else { return nil }
    let scaleX = frame.sourceSize.width / workingWidth
    let scaleY = frame.sourceSize.height / workingHeight

    let expanded = imageRect.insetBy(dx: -imageRect.width * 0.15, dy: -imageRect.height * 0.15)

    let nativeX = expanded.origin.x * scaleX
    let nativeWidth = expanded.width * scaleX
    let nativeHeight = expanded.height * scaleY
    let nativeY = frame.sourceSize.height - (expanded.origin.y + expanded.height) * scaleY
    var nativeRect = CGRect(x: nativeX, y: nativeY, width: nativeWidth, height: nativeHeight)

    let sourceExtent = CGRect(origin: .zero, size: frame.sourceSize)
    nativeRect = nativeRect.intersection(sourceExtent)
    guard !nativeRect.isEmpty else { return nil }

    var cropped = frame.source.cropped(to: nativeRect)
      .transformed(by: CGAffineTransform(translationX: -nativeRect.minX, y: -nativeRect.minY))
    let longEdge = max(nativeRect.width, nativeRect.height)
    if longEdge > maxEdge {
      let scale = maxEdge / longEdge
      cropped = cropped.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }

    return cropRenderContext.createCGImage(cropped, from: cropped.extent)
  }

  private nonisolated(unsafe) static let cropRenderContext = CIContext()

  private final class FramePublisher: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    weak var owner: CameraManager?
    private let ciContext = CIContext()
    private let maxLongEdge: CGFloat = 640
    private var nextFrameID: UInt64 = 0

    func captureOutput(
      _ output: AVCaptureOutput,
      didOutput sampleBuffer: CMSampleBuffer,
      from connection: AVCaptureConnection
    ) {
      guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
      let sourceImage = CIImage(cvPixelBuffer: pixelBuffer)
      let sourceExtent = sourceImage.extent
      var ciImage = sourceImage
      let longEdge = max(ciImage.extent.width, ciImage.extent.height)
      if longEdge > maxLongEdge {
        let scale = maxLongEdge / longEdge
        ciImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
      }
      guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }

      nextFrameID &+= 1
      let frame = CameraFrame(
        id: nextFrameID,
        image: cgImage,
        source: sourceImage,
        sourceSize: sourceExtent.size
      )

      Task { @MainActor [weak owner] in
        owner?.publish(frame: frame)
      }
    }
  }
}
