import CryptoKit
import Foundation
import LocalAuthentication

enum SecureCredentialError: LocalizedError {
  case emptyPassword
  case sessionLocked
  case encryptionFailed
  case decryptionFailed
  case sessionKeyUnavailable

  var errorDescription: String? {
    switch self {
    case .emptyPassword:
      return "Password cannot be empty."
    case .sessionLocked:
      return "Session is locked. Authenticate with Touch ID before storing or using the password."
    case .encryptionFailed:
      return "Encryption failed."
    case .decryptionFailed:
      return "Decryption failed. The stored credential may be corrupted."
    case .sessionKeyUnavailable:
      return
        "The session key is missing, but encrypted data still exists that only it could read. Nothing has been deleted. Remove the stored password on the Password tab to clear both and start fresh."
    }
  }
}

extension Notification.Name {
  static let secureCredentialSessionDidChange = Notification.Name(
    "SecureCredentialManager.sessionDidChange")
}

enum SecureCredentialManager {
  nonisolated private static let sessionKeyAccount = "sessionKey"
  nonisolated private static let passwordBlobAccount = "encryptedPassword"

  nonisolated private static let sessionLock = NSLock()
  nonisolated(unsafe) private static var _cachedKey: SymmetricKey?
  nonisolated(unsafe) private static var _lastActivityAt: Date?

  nonisolated static var isSessionUnlocked: Bool {
    sessionLock.lock()
    defer { sessionLock.unlock() }
    return _cachedKey != nil
  }

  nonisolated static var lastActivityAt: Date? {
    sessionLock.lock()
    defer { sessionLock.unlock() }
    return _lastActivityAt
  }

  nonisolated private static func cachedKey() -> SymmetricKey? {
    sessionLock.lock()
    defer { sessionLock.unlock() }
    return _cachedKey
  }

  nonisolated private static func setCachedKey(_ key: SymmetricKey?) {
    sessionLock.lock()
    let changed = (key != nil) != (_cachedKey != nil)
    _cachedKey = key
    _lastActivityAt = key == nil ? nil : Date()
    sessionLock.unlock()
    guard changed else { return }
    NotificationCenter.default.post(name: .secureCredentialSessionDidChange, object: nil)
  }

  nonisolated private static func recordActivity() {
    sessionLock.lock()
    if _cachedKey != nil { _lastActivityAt = Date() }
    sessionLock.unlock()
  }

  nonisolated static func encrypt(_ plaintext: Data) throws -> Data {
    guard let key = cachedKey() else { throw SecureCredentialError.sessionLocked }
    do {
      let sealed = try AES.GCM.seal(plaintext, using: key)
      guard let combined = sealed.combined else { throw SecureCredentialError.encryptionFailed }
      return combined
    } catch {
      throw SecureCredentialError.encryptionFailed
    }
  }

  nonisolated static func decrypt(_ ciphertext: Data) throws -> Data {
    guard let key = cachedKey() else { throw SecureCredentialError.sessionLocked }
    do {
      let sealed = try AES.GCM.SealedBox(combined: ciphertext)
      return try AES.GCM.open(sealed, using: key)
    } catch {
      throw SecureCredentialError.decryptionFailed
    }
  }

  nonisolated static func hasStoredPassword() -> Bool {
    KeychainManager.exists(account: passwordBlobAccount)
  }

  nonisolated static func unlockSession(reason: String) async throws {
    if cachedKey() != nil { return }

    let hasSessionKey = KeychainManager.exists(account: sessionKeyAccount)
    guard hasSessionKey || !hasSessionEncryptedData else {
      throw SecureCredentialError.sessionKeyUnavailable
    }

    let context = LAContext()
    var policyError: NSError?
    guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &policyError) else {
      throw policyError ?? KeychainError.authenticationFailed
    }
    guard try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
    else {
      throw KeychainError.authenticationFailed
    }

    if hasSessionKey {
      let data = try KeychainManager.read(account: sessionKeyAccount)
      if KeychainManager.exists(account: passwordBlobAccount) {
        _ = try KeychainManager.read(account: passwordBlobAccount)
      }
      try? KeychainManager.trustCurrentApplication(account: sessionKeyAccount)
      try? KeychainManager.trustCurrentApplication(account: passwordBlobAccount)
      setCachedKey(SymmetricKey(data: data))
    } else {
      let key = SymmetricKey(size: .bits256)
      try KeychainManager.save(
        account: sessionKeyAccount,
        data: key.withUnsafeBytes { Data($0) }
      )
      setCachedKey(key)
    }
  }

  nonisolated static var hasSessionEncryptedData: Bool {
    KeychainManager.exists(account: passwordBlobAccount) || SecureFaceStore.exists
  }

  nonisolated static func lockSession() {
    setCachedKey(nil)
  }

  nonisolated static func savePassword(_ passwordBytes: Data) throws {
    guard !passwordBytes.isEmpty else { throw SecureCredentialError.emptyPassword }
    let combined = try encrypt(passwordBytes)
    try KeychainManager.save(account: passwordBlobAccount, data: combined)
  }

  nonisolated static func readPassword() throws -> Data {
    guard cachedKey() != nil else { throw SecureCredentialError.sessionLocked }
    let ciphertext = try KeychainManager.read(account: passwordBlobAccount)
    let plaintext = try decrypt(ciphertext)
    recordActivity()
    return plaintext
  }

  nonisolated static func deletePassword() throws {
    try KeychainManager.delete(account: passwordBlobAccount)
    try KeychainManager.delete(account: sessionKeyAccount)
    setCachedKey(nil)
  }
}
