//
//  WeatherProviderCredential.swift
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
import SwiftData

@Model
final class WeatherProviderCredential {
    @Attribute(.unique) var id: String
    var providerName: String
    var keychainKey: String
    var createdDate: Date
    var lastUsedDate: Date?

    init(id: String = UUID().uuidString, providerName: String, keychainKey: String) {
        self.id = id
        self.providerName = providerName
        self.keychainKey = keychainKey
        self.createdDate = Date()
        self.lastUsedDate = nil
    }
}
