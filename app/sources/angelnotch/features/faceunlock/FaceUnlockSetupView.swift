import AppKit
import Combine
import Foundation
import SwiftUI

@MainActor
final class FaceEnrollmentController: ObservableObject {
  @Published private(set) var capturedCount = 0
  @Published private(set) var status = "Position your face in the frame."
  @Published private(set) var isCapturing = false
  @Published private(set) var isComplete = false

  let camera = CameraManager()
  private let pipeline = FaceRecognitionPipeline()
  private var samples: [FaceSample] = []

  static let directions = [
    "Look straight ahead",
    "Turn slightly left",
    "Turn slightly right",
    "Look slightly up",
    "Look slightly down",
    "Turn left and up",
    "Turn right and up",
    "Turn left and down",
    "Turn right and down",
  ]

  var currentDirection: String {
    Self.directions[min(capturedCount, Self.directions.count - 1)]
  }

  func start() async {
    guard !pipeline.usingFallbackEmbedder else {
      status = "The ArcFace model could not be loaded. Reinstall AngelNotch."
      return
    }
    await camera.start()
    if let error = camera.errorMessage { status = error }
  }

  func stop() {
    camera.stop()
  }

  func capture(name: String) async {
    guard !isCapturing, !isComplete, let frame = camera.currentFrame else {
      status = "Waiting for the camera…"
      return
    }
    isCapturing = true
    defer { isCapturing = false }

    let pipeline = pipeline
    let result = await Task.detached(priority: .userInitiated) { () -> FaceRecognitionResult? in
      guard let faces = try? FaceDetector.detectFaces(in: frame.image),
        let face = FaceRecognitionPipeline.largestFace(in: faces),
        face.normalizedBoundingBox.width >= 0.18,
        (face.quality ?? 0.5) >= 0.35
      else { return nil }
      return try? pipeline.recognize(face, in: frame.image)
    }.value

    guard let result else {
      status = "Move closer, face the camera, and try again."
      return
    }
    guard poseMatches(result.face, at: capturedCount) else {
      status = "Hold the requested pose, then try again."
      return
    }

    samples.append(
      FaceSample(
        embedding: result.embedding,
        pose: currentDirection,
        capturedAt: Date(),
        quality: result.quality
      )
    )
    capturedCount = samples.count

    if capturedCount == Self.directions.count {
      do {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.isEmpty ? NSFullUserName() : trimmedName
        try FaceEnrollmentStore.shared.commitEnrollment(
          replacing: nil,
          name: finalName,
          samples: samples,
          embedder: pipeline.embedder
        )
        isComplete = true
        status = "Face enrolled securely."
        camera.stop()
      } catch {
        status = error.localizedDescription
      }
    } else {
      status = "Captured. Next: \(currentDirection.lowercased())."
    }
  }

  private func poseMatches(_ face: DetectedFace, at index: Int) -> Bool {
    let yaw = face.yaw ?? 0
    let pitch = face.pitch ?? 0
    switch index {
    case 0:
      return abs(yaw) < 0.14 && abs(pitch) < 0.14
    case 1:
      return yaw > 0.12
    case 2:
      return yaw < -0.12
    case 3:
      return pitch < -0.08
    case 4:
      return pitch > 0.08
    case 5:
      return yaw > 0.10 && pitch < -0.06
    case 6:
      return yaw < -0.10 && pitch < -0.06
    case 7:
      return yaw > 0.10 && pitch > 0.06
    case 8:
      return yaw < -0.10 && pitch > 0.06
    default:
      return false
    }
  }
}

struct FaceUnlockSetupView: View {
  @ObservedObject var service: FaceUnlockService
  @ObservedObject var settings: AppSettings
  @StateObject private var enrollment = FaceEnrollmentController()
  @State private var password = ""
  @State private var name = NSFullUserName()
  @State private var acceptedRisk = false
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Label("Face Unlock", systemImage: "faceid")
          .font(.title2.weight(.semibold))
        Spacer()
        Button("Close") { dismiss() }
      }

      GroupBox("Important security limitation") {
        Text(
          "A Mac camera cannot provide Face ID security. AngelNotch can reject many photos, but it may not reject a convincing video. macOS also provides no third-party unlock API, so AngelNotch unlocks by typing your encrypted password into the verified lock screen."
        )
        .font(.callout)
        .frame(maxWidth: .infinity, alignment: .leading)
        Toggle(
          "I understand this is a convenience feature, not a security upgrade.", isOn: $acceptedRisk
        )
        .padding(.top, 8)
      }

      HStack(spacing: 10) {
        setupBadge("Touch ID session", ready: service.isSessionAuthorized)
        setupBadge("Password", ready: service.hasStoredPassword)
        setupBadge("Accessibility", ready: service.isAccessibilityGranted)
        setupBadge(
          "Face",
          ready: !FaceEnrollmentStore.shared.activeIdentities.isEmpty || enrollment.isComplete)
      }

      if !service.isSessionAuthorized {
        Button("Authorize with Touch ID") {
          Task { _ = await service.authorizeSession() }
        }
        .buttonStyle(.borderedProminent)
        .disabled(!acceptedRisk)
      } else if !service.hasStoredPassword {
        HStack {
          SecureField("Mac login password", text: $password)
          Button("Encrypt and save") {
            let entered = password
            password = ""
            Task { _ = await service.storePassword(entered) }
          }
          .buttonStyle(.borderedProminent)
          .disabled(password.isEmpty)
        }
      } else if !service.isAccessibilityGranted {
        VStack(alignment: .leading, spacing: 8) {
          Text(
            "Accessibility permission lets AngelNotch type the password only after the lock state, face match, and liveness checks all pass."
          )
          .font(.callout)
          .foregroundStyle(.secondary)
          Button("Open Accessibility permission") { service.requestAccessibility() }
            .buttonStyle(.borderedProminent)
        }
      } else if !enrollment.isComplete && FaceEnrollmentStore.shared.activeIdentities.isEmpty {
        HStack(alignment: .top, spacing: 16) {
          CameraPreviewView(session: enrollment.camera.session)
            .frame(width: 230, height: 172)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
              RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.14))
            }

          VStack(alignment: .leading, spacing: 10) {
            Text("Enroll your face")
              .font(.headline)
            Text(enrollment.currentDirection)
              .foregroundStyle(.secondary)
            ProgressView(
              value: Double(enrollment.capturedCount),
              total: Double(FaceEnrollmentController.directions.count)
            )
            TextField("Name", text: $name)
            Button(enrollment.isCapturing ? "Capturing…" : "Capture") {
              Task { await enrollment.capture(name: name) }
            }
            .buttonStyle(.borderedProminent)
            .disabled(enrollment.isCapturing)
            Text(enrollment.status)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .task { await enrollment.start() }
        .onDisappear { enrollment.stop() }
      } else {
        VStack(alignment: .leading, spacing: 10) {
          Label("Face Unlock is ready", systemImage: "checkmark.seal.fill")
            .foregroundStyle(.green)
            .font(.headline)
          Text(
            "Multi-frame liveness checking is enabled. The authorization session automatically expires after 8 hours."
          )
          .foregroundStyle(.secondary)
          Button("Enable Face Unlock") {
            settings.enableFaceUnlock = true
            service.updateEnabledState()
            dismiss()
          }
          .buttonStyle(.borderedProminent)
        }
      }

      if case .unavailable(let error) = service.phase {
        Text(error)
          .font(.caption)
          .foregroundStyle(.red)
      }
    }
    .padding(24)
    .frame(width: 650, height: 610, alignment: .topLeading)
    .preferredColorScheme(.dark)
    .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification))
    { _ in
      service.refreshSecurityState()
    }
  }

  private func setupBadge(_ title: String, ready: Bool) -> some View {
    Label(title, systemImage: ready ? "checkmark.circle.fill" : "circle")
      .font(.caption)
      .foregroundStyle(ready ? .green : .secondary)
      .padding(.horizontal, 9)
      .padding(.vertical, 6)
      .background(.white.opacity(0.06), in: Capsule())
  }
}
