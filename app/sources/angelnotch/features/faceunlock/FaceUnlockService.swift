import AppKit
import Combine
import Foundation
import OSLog

enum FaceUnlockPhase: Equatable {
  case idle
  case unavailable(String)
  case scanning
  case recognized(String)
  case failed(String)

  var label: String {
    switch self {
    case .idle: "Ready"
    case .unavailable(let reason): reason
    case .scanning: "Looking for you…"
    case .recognized(let name): "Welcome, \(name)"
    case .failed(let reason): reason
    }
  }

  var symbol: String {
    switch self {
    case .idle: "faceid"
    case .unavailable: "lock.trianglebadge.exclamationmark"
    case .scanning: "viewfinder"
    case .recognized: "faceid"
    case .failed: "xmark.circle.fill"
    }
  }
}

@MainActor
final class FaceUnlockService: ObservableObject {
  private static let logger = Logger(subsystem: "com.angelnotch.mac", category: "FaceUnlock")

  @Published private(set) var phase: FaceUnlockPhase = .idle
  @Published private(set) var isSessionAuthorized = SecureCredentialManager.isSessionUnlocked
  @Published private(set) var hasStoredPassword = SecureCredentialManager.hasStoredPassword()
  @Published private(set) var isAccessibilityGranted = KeystrokeInjector.isAccessibilityTrusted()

  let camera = CameraManager()
  let pipeline = FaceRecognitionPipeline()

  private let settings: AppSettings
  private let lockMonitor = LockMonitor()
  private var hasScannedCurrentLock = false
  private var scanTask: Task<Void, Never>?
  private var successResetTask: Task<Void, Never>?
  private var sessionTimer: Timer?
  private var lockEventSubscription: AnyCancellable?
  private var started = false
  private var lastScanStartedAt: ContinuousClock.Instant?
  private var scanGeneration = 0

  private let matchThreshold: Float = 0.5
  private let scanDuration: TimeInterval = 15
  private let sessionLifetime: TimeInterval = 8 * 60 * 60
  private let wakeDebounce: Duration = .seconds(2)

  init(settings: AppSettings) {
    self.settings = settings
  }

  func start() {
    guard !started else { return }
    started = true
    observeLockEvents()
    sessionTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
      Task { @MainActor [weak self] in self?.expireIdleSessionIfNeeded() }
    }
    refreshSecurityState()
    Self.logger.info(
      "service started enabled=\(self.settings.enableFaceUnlock) ready=\(self.isReady) accessibility=\(self.isAccessibilityGranted)"
    )
  }

  func updateEnabledState() {
    guard settings.enableFaceUnlock else {
      cancelScan()
      successResetTask?.cancel()
      successResetTask = nil
      phase = .idle
      return
    }
    evaluateLockEvent()
  }

  func authorizeSession() async -> Bool {
    do {
      try await SecureCredentialManager.unlockSession(
        reason: "Authorize AngelNotch Face Unlock"
      )
      refreshSecurityState()
      FaceEnrollmentStore.shared.reloadIfUnlocked()
      phase = .idle
      return true
    } catch {
      refreshSecurityState()
      phase = .unavailable(error.localizedDescription)
      return false
    }
  }

  func storePassword(_ password: String) async -> Bool {
    guard !password.isEmpty else {
      phase = .unavailable("Enter your Mac password first.")
      return false
    }
    do {
      try await Task.detached(priority: .userInitiated) {
        guard var bytes = password.data(using: .utf8) else {
          throw SecureCredentialError.emptyPassword
        }
        defer { bytes.resetBytes(in: 0..<bytes.count) }
        try SecureCredentialManager.savePassword(bytes)
      }.value
      refreshSecurityState()
      phase = .idle
      return true
    } catch {
      phase = .unavailable(error.localizedDescription)
      return false
    }
  }

  func requestAccessibility() {
    KeystrokeInjector.promptForAccessibility()
    refreshSecurityState()
  }

  func refreshSecurityState() {
    isSessionAuthorized = SecureCredentialManager.isSessionUnlocked
    hasStoredPassword = SecureCredentialManager.hasStoredPassword()
    isAccessibilityGranted = KeystrokeInjector.isAccessibilityTrusted()
  }

  func removeFaceUnlockData() {
    cancelScan()
    FaceEnrollmentStore.shared.deleteAll()
    try? SecureCredentialManager.deletePassword()
    settings.enableFaceUnlock = false
    refreshSecurityState()
    phase = .idle
  }

  var isReady: Bool {
    isSessionAuthorized
      && hasStoredPassword
      && !FaceEnrollmentStore.shared.activeIdentities.isEmpty
      && isAccessibilityGranted
      && !pipeline.usingFallbackEmbedder
  }

  private func observeLockEvents() {
    lockEventSubscription = lockMonitor.$eventCount
      .dropFirst()
      .sink { [weak self] _ in
        Task { @MainActor [weak self] in
          guard let self else { return }
          try? await Task.sleep(for: .milliseconds(300))
          self.evaluateLockEvent()
        }
      }
  }

  private func evaluateLockEvent() {
    let isLocked = LockMonitor.isScreenActuallyLocked()
    let event = lockMonitor.lastEvent?.rawValue ?? "none"
    Self.logger.info(
      "evaluate event=\(event, privacy: .public) locked=\(isLocked) enabled=\(self.settings.enableFaceUnlock) ready=\(self.isReady) sleeping=\(self.lockMonitor.isSleeping)"
    )
    guard isLocked else {
      hasScannedCurrentLock = false
      cancelScan()
      if case .recognized = phase {
        scheduleSuccessReset()
      } else {
        phase = .idle
      }
      return
    }
    if lockMonitor.lastEvent == .wake, !isWithinRecentScanBurst {
      hasScannedCurrentLock = false
    }
    guard settings.enableFaceUnlock, !lockMonitor.isSleeping, !hasScannedCurrentLock else { return }
    guard lockMonitor.lastEvent == .screenLocked || lockMonitor.lastEvent == .wake else { return }
    guard isReady else {
      phase = .unavailable(readinessFailure)
      return
    }
    hasScannedCurrentLock = true
    lastScanStartedAt = .now
    beginScan()
  }

  private var isWithinRecentScanBurst: Bool {
    guard let lastScanStartedAt else { return false }
    return ContinuousClock.now - lastScanStartedAt < wakeDebounce
  }

  private var readinessFailure: String {
    if pipeline.usingFallbackEmbedder { return "Face model unavailable. Reinstall AngelNotch." }
    if !isSessionAuthorized {
      return "Authorize Face Unlock with Touch ID after launching AngelNotch."
    }
    if !hasStoredPassword { return "Finish Face Unlock setup in Settings." }
    if FaceEnrollmentStore.shared.activeIdentities.isEmpty { return "Enroll a face in Settings." }
    if !isAccessibilityGranted {
      return "Allow Accessibility access in System Settings."
    }
    return "Face Unlock is not ready."
  }

  private func beginScan() {
    successResetTask?.cancel()
    successResetTask = nil
    scanTask?.cancel()
    scanGeneration &+= 1
    let generation = scanGeneration
    scanTask = Task { [weak self] in await self?.runScan(generation: generation) }
  }

  private func cancelScan() {
    scanTask?.cancel()
    scanTask = nil
    scanGeneration &+= 1
    camera.stop()
  }

  private func scheduleSuccessReset() {
    successResetTask?.cancel()
    successResetTask = Task { @MainActor [weak self] in
      try? await Task.sleep(for: .seconds(3))
      guard !Task.isCancelled else { return }
      self?.phase = .idle
      self?.successResetTask = nil
    }
  }

  private func runScan(generation: Int) async {
    guard LockMonitor.isScreenActuallyLocked() else { return }
    Self.logger.info("scan started")
    await camera.start()
    guard generation == scanGeneration, !Task.isCancelled else { return }
    if let error = camera.errorMessage {
      Self.logger.error("camera failed: \(error, privacy: .public)")
      phase = .failed(error)
      camera.stop()
      return
    }

    phase = .scanning
    let deadline = Date().addingTimeInterval(scanDuration)
    let liveness = LivenessAnalyzer()
    liveness.modeProvider = { .light }
    var lastFrameID: UInt64?
    var lastFaceBox: CGRect?
    var matchedIdentity: ScoredIdentity?
    var livenessConfirmed = false
    var bestCentroidSimilarity: Float = -1
    var bestSampleSimilarity: Float = -1

    while Date() < deadline, generation == scanGeneration, !Task.isCancelled,
      LockMonitor.isScreenActuallyLocked()
    {
      guard let frame = camera.currentFrame, frame.id != lastFrameID else {
        try? await Task.sleep(for: .milliseconds(25))
        continue
      }
      lastFrameID = frame.id
      let previousBox = lastFaceBox
      let pipeline = pipeline
      let result = await Task.detached(priority: .userInitiated) {
        try? pipeline.recognize(in: frame.image, preferNear: previousBox)
      }.value
      guard generation == scanGeneration, !Task.isCancelled else { return }
      guard let result else { continue }
      lastFaceBox = result.face.normalizedBoundingBox

      let faceCrop = CameraManager.renderCrop(from: frame, imageRect: result.face.boundingBox)
      let liveFrame = LivenessFeatureExtractor.extract(
        from: result,
        frame: frame.image,
        faceCrop: faceCrop
      )
      let liveSnapshot = liveness.observe(liveFrame)
      if case .denied = liveSnapshot.decision {
        let reason = liveSnapshot.decision.denialReason ?? "Liveness check failed."
        Self.logger.notice("scan denied: \(reason, privacy: .public)")
        phase = .failed(reason)
        camera.stop()
        return
      }
      if case .confirmed = liveSnapshot.decision { livenessConfirmed = true }

      let scored = pipeline.score(
        result.embedding,
        against: FaceEnrollmentStore.shared.activeIdentities
      )
      if let best = scored.first {
        bestCentroidSimilarity = max(bestCentroidSimilarity, best.centroidSimilarity)
        bestSampleSimilarity = max(bestSampleSimilarity, best.maxSampleSimilarity)
      }
      matchedIdentity = pipeline.bestMatch(in: scored, threshold: matchThreshold)
      if let matchedIdentity, livenessConfirmed {
        Self.logger.info("face matched and liveness confirmed")
        phase = .recognized(matchedIdentity.identity.name)
        camera.stop()
        await injectStoredPassword()
        return
      }
    }

    guard generation == scanGeneration else { return }
    camera.stop()
    let reason = matchedIdentity == nil ? "Face not recognized." : "Could not confirm a live face."
    Self.logger.notice(
      "scan ended: \(reason, privacy: .public) bestCentroid=\(bestCentroidSimilarity) bestSample=\(bestSampleSimilarity)"
    )
    phase = .failed(reason)
  }

  private func injectStoredPassword() async {
    guard LockMonitor.isScreenActuallyLocked(), KeystrokeInjector.isAccessibilityTrusted() else {
      return
    }
    do {
      try await Task.detached(priority: .userInitiated) {
        var bytes = try SecureCredentialManager.readPassword()
        defer { bytes.resetBytes(in: 0..<bytes.count) }
        guard LockMonitor.isScreenActuallyLocked() else { return }
        try KeystrokeInjector.typeAndReturn(bytes)
      }.value
      Self.logger.info("password injected")
    } catch {
      Self.logger.error(
        "password injection failed: \(error.localizedDescription, privacy: .public)")
      phase = .failed(error.localizedDescription)
    }
  }

  private func expireIdleSessionIfNeeded() {
    guard let lastActivity = SecureCredentialManager.lastActivityAt,
      Date().timeIntervalSince(lastActivity) >= sessionLifetime
    else { return }
    SecureCredentialManager.lockSession()
    refreshSecurityState()
    phase = .unavailable("Face Unlock session expired. Authorize it again with Touch ID.")
  }
}
