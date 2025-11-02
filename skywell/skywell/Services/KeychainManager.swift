//
//  KeychainManager.swift
//  Skywell
//
//  Created by Kevin Cox.
//
//  This software is provided "as is", without warranty of any kind,
//  express or implied, including but not limited to the warranties of
//  merchantability, fitness for a particular purpose and noninfringement.
//  In no event shall the authors be liable for any claim, damages or other
//  liability arising from, out of or in connection with the software.
//

import Foundation

class KeychainManager {
    static let shared = KeychainManager()

    enum KeychainError: Error {
        case itemNotFound
        case duplicateItem
        case unexpectedError(OSStatus)
        case conversionError
    }

    private init() {}

    /// Save an API key to Keychain
    /// - Parameters:
    ///   - key: The API key value to store
    ///   - identifier: Unique identifier for this credential (e.g., provider name)
    /// - Throws: KeychainError if save fails
    func save(_ key: String, for identifier: String) throws {
        guard let data = key.data(using: .utf8) else {
            throw KeychainError.conversionError
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecAttrService as String: "com.skywell.weather-provider",
            kSecValueData as String: data,
        ]

        // Try to delete existing item first to avoid duplicates
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedError(status)
        }
    }

    /// Retrieve an API key from Keychain
    /// - Parameters:
    ///   - identifier: Unique identifier for this credential
    /// - Returns: The stored API key
    /// - Throws: KeychainError if retrieval fails
    func retrieve(for identifier: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecAttrService as String: "com.skywell.weather-provider",
            kSecReturnData as String: true,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedError(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.conversionError
        }

        guard let key = String(data: data, encoding: .utf8) else {
            throw KeychainError.conversionError
        }

        return key
    }

    /// Delete an API key from Keychain
    /// - Parameters:
    ///   - identifier: Unique identifier for this credential
    /// - Throws: KeychainError if deletion fails
    func delete(for identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecAttrService as String: "com.skywell.weather-provider",
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedError(status)
        }
    }
}
