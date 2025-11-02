//
//  MockKeyChainManager.swift
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
@testable import skywell

/// Mock KeyChainManager for testing without accessing actual Keychain
class MockKeyChainManager {
    var storage: [String: String] = [:]
    var shouldFailRetrieval = false
    var shouldFailSave = false
    var shouldFailDelete = false

    init() {}

    func save(_ key: String, for identifier: String) throws {
        if shouldFailSave {
            throw KeychainManager.KeychainError.unexpectedError(1)
        }
        storage[identifier] = key
    }

    func retrieve(for identifier: String) throws -> String {
        if shouldFailRetrieval {
            throw KeychainManager.KeychainError.itemNotFound
        }
        guard let key = storage[identifier] else {
            throw KeychainManager.KeychainError.itemNotFound
        }
        return key
    }

    func delete(for identifier: String) throws {
        if shouldFailDelete {
            throw KeychainManager.KeychainError.unexpectedError(1)
        }
        storage.removeValue(forKey: identifier)
    }
}
