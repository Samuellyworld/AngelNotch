import Foundation
import LocalAuthentication
import Security

enum KeychainError: LocalizedError {
  case itemNotFound
  case unexpectedData
  case authenticationFailed
  case osStatus(OSStatus)

  var errorDescription: String? {
    switch self {
    case .itemNotFound:
      return "Keychain item not found."
    case .unexpectedData:
      return "Keychain item had an unexpected format."
    case .authenticationFailed:
      return "Authentication was cancelled or failed."
    case .osStatus(let status):
      let message = SecCopyErrorMessageString(status, nil) as String? ?? "OSStatus \(status)"
      return "Keychain error: \(message)"
    }
  }
}

enum KeychainManager {
  nonisolated static let service = "com.angelnotch.mac.face-unlock"

  nonisolated static func exists(account: String) -> Bool {
    let context = LAContext()
    context.interactionNotAllowed = true
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecMatchLimit as String: kSecMatchLimitOne,
      kSecUseAuthenticationContext as String: context,
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    return status != errSecItemNotFound
  }

  nonisolated static func read(account: String) throws -> Data {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    switch status {
    case errSecSuccess:
      guard let data = item as? Data else { throw KeychainError.unexpectedData }
      return data
    case errSecItemNotFound:
      throw KeychainError.itemNotFound
    case errSecUserCanceled, errSecAuthFailed:
      throw KeychainError.authenticationFailed
    default:
      throw KeychainError.osStatus(status)
    }
  }

  nonisolated static func save(account: String, data: Data) throws {
    let deleteQuery: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    SecItemDelete(deleteQuery as CFDictionary)

    let addQuery: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecValueData as String: data,
    ]

    let status = SecItemAdd(addQuery as CFDictionary, nil)
    guard status == errSecSuccess else { throw KeychainError.osStatus(status) }
    try? trustCurrentApplication(account: account)
  }

  nonisolated static func delete(account: String) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainError.osStatus(status)
    }
  }

  nonisolated static func trustCurrentApplication(account: String) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnRef as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var result: CFTypeRef?
    let findStatus = SecItemCopyMatching(query as CFDictionary, &result)
    guard findStatus == errSecSuccess else { throw KeychainError.osStatus(findStatus) }
    guard let item = result as! SecKeychainItem? else { throw KeychainError.unexpectedData }

    var trustedApplication: SecTrustedApplication?
    let appStatus = SecTrustedApplicationCreateFromPath(nil, &trustedApplication)
    guard appStatus == errSecSuccess, let trustedApplication else {
      throw KeychainError.osStatus(appStatus)
    }

    var access: SecAccess?
    let accessStatus = SecAccessCreate(
      service as CFString,
      [trustedApplication] as CFArray,
      &access
    )
    guard accessStatus == errSecSuccess, let access else {
      throw KeychainError.osStatus(accessStatus)
    }

    let updateStatus = SecKeychainItemSetAccess(item, access)
    guard updateStatus == errSecSuccess else { throw KeychainError.osStatus(updateStatus) }
  }

}
