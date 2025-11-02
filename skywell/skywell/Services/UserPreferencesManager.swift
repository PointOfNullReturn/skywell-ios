//
//  UserPreferencesManager.swift
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

/// Application Service for managing user preferences
///
/// Encapsulates all preference-related business logic including:
/// - Retrieving current preferences
/// - Updating active weather provider
/// - Updating unit preferences
/// - Ensuring singleton constraint on UserPreferences
/// - Coordinating between SwiftData persistence and Keychain
class UserPreferencesManager {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Preference Retrieval

    /// Get current user preferences, creating defaults if needed
    func getPreferences() -> UserPreferences {
        let descriptor = FetchDescriptor<UserPreferences>(
            predicate: #Predicate { $0.id == "user-preferences" }
        )

        do {
            if let existing = try modelContext.fetch(descriptor).first {
                return existing
            }
        } catch {
            // If fetch fails, we'll create new preferences below
        }

        // Create and return default preferences
        let defaultPrefs = UserPreferences()
        modelContext.insert(defaultPrefs)
        try? modelContext.save()
        return defaultPrefs
    }

    // MARK: - Preference Updates

    /// Update the active weather provider
    /// - Parameter providerId: ID of the WeatherProviderCredential to set as active
    func updateActiveProvider(_ providerId: String) throws {
        let prefs = getPreferences()
        prefs.activeProviderId = providerId
        prefs.lastModifiedDate = Date()
        try modelContext.save()
    }

    /// Update the temperature unit preference
    /// - Parameter unit: Desired unit preference (metric or imperial)
    func updateUnitPreference(_ unit: UnitPreference) throws {
        let prefs = getPreferences()
        prefs.unitPreference = unit
        prefs.lastModifiedDate = Date()
        try modelContext.save()
    }

    /// Set up default preferences for first-time users
    /// - Parameters:
    ///   - activeProviderId: ID of provider to set as active (optional)
    ///   - hasCompletedOnboarding: Flag indicating if the onboarding flow has been completed
    func initializeDefaultPreferences(
        activeProviderId: String? = nil,
        hasCompletedOnboarding: Bool = false
    ) throws {
        let prefs = UserPreferences(
            activeProviderId: activeProviderId,
            unitPreference: .metric,
            colorScheme: .system,
            hasCompletedOnboarding: hasCompletedOnboarding
        )
        modelContext.insert(prefs)
        try modelContext.save()
    }

    // MARK: - Provider Management

    /// Reset active provider (used when current provider is deleted)
    /// - Parameter fallbackProviderId: ID to set as active, or empty string to clear
    func resetActiveProvider(to fallbackProviderId: String = "") throws {
        let prefs = getPreferences()
        prefs.activeProviderId = fallbackProviderId.isEmpty ? nil : fallbackProviderId
        prefs.lastModifiedDate = Date()
        try modelContext.save()
    }

    /// Check if a provider is currently active
    /// - Parameter providerId: ID of the provider to check
    func isActiveProvider(_ providerId: String) -> Bool {
        let prefs = getPreferences()
        return prefs.activeProviderId == providerId
    }

    // MARK: - Preference Queries

    /// Get the currently active provider ID
    func getActiveProviderId() -> String? {
        getPreferences().activeProviderId
    }

    /// Get the current unit preference
    func getUnitPreference() -> UnitPreference {
        getPreferences().unitPreference
    }

    /// Update the color scheme preference
    /// - Parameter colorScheme: Desired color scheme (light, dark, or system)
    func updateColorScheme(_ colorScheme: ColorScheme) throws {
        let prefs = getPreferences()
        prefs.colorScheme = colorScheme
        prefs.lastModifiedDate = Date()
        try modelContext.save()
    }

    /// Get the current color scheme preference
    func getColorScheme() -> ColorScheme {
        getPreferences().colorScheme
    }

    /// Check if onboarding has been completed
    func hasCompletedOnboarding() -> Bool {
        getPreferences().hasCompletedOnboarding
    }

    /// Mark the onboarding flow as completed
    func markOnboardingComplete() throws {
        let prefs = getPreferences()
        prefs.hasCompletedOnboarding = true
        prefs.lastModifiedDate = Date()
        try modelContext.save()
    }
}
