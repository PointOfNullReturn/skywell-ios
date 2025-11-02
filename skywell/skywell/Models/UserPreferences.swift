//
//  UserPreferences.swift
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
final class UserPreferences {
    @Attribute(.unique) var id: String = "user-preferences"
    var activeProviderId: String?
    var unitPreference: UnitPreference
    var colorScheme: ColorScheme
    var lastModifiedDate: Date
    var hasCompletedOnboarding: Bool

    init(
        activeProviderId: String? = nil,
        unitPreference: UnitPreference = .metric,
        colorScheme: ColorScheme = .system,
        hasCompletedOnboarding: Bool = false
    ) {
        self.id = "user-preferences"
        self.activeProviderId = activeProviderId
        self.unitPreference = unitPreference
        self.colorScheme = colorScheme
        self.lastModifiedDate = Date()
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}

enum UnitPreference: String, Codable {
    case metric = "metric"
    case imperial = "imperial"
}
