//
//  SettingsViewModel.swift
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
import Combine
import SwiftData

/// ViewModel for SettingsView
///
/// Manages:
/// - Active provider selection
/// - Unit preference management
/// - Provider addition and deletion
/// - Error handling and user feedback
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties (for SwiftUI reactivity)

    @Published var currentPreferences: UserPreferences
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showAddProvider = false

    // MARK: - Dependencies

    private var preferencesManager: UserPreferencesManager?
    private var modelContext: ModelContext?

    // MARK: - Initialization

    init(
        preferencesManager: UserPreferencesManager? = nil,
        modelContext: ModelContext? = nil
    ) {
        self.preferencesManager = preferencesManager
        self.modelContext = modelContext
        if let preferencesManager {
            self.currentPreferences = preferencesManager.getPreferences()
        } else {
            self.currentPreferences = UserPreferences()
        }
    }

    /// Configure persistence dependencies once the shared context is available
    /// - Parameters:
    ///   - preferencesManager: Manager backed by the shared SwiftData context
    ///   - modelContext: Shared model context for WeatherProviderCredential updates
    func configure(preferencesManager: UserPreferencesManager, modelContext: ModelContext) {
        self.preferencesManager = preferencesManager
        self.modelContext = modelContext
        self.currentPreferences = preferencesManager.getPreferences()
    }

    // MARK: - Provider Management

    /// Add a new weather provider with API key
    /// - Parameters:
    ///   - name: Display name of the provider (e.g., "OpenWeatherMap")
    ///   - apiKey: API key to store securely in Keychain
    func addProvider(name: String, apiKey: String) {
        guard let modelContext = modelContext,
              let preferencesManager = preferencesManager else {
            handleError("Persistence is not available")
            return
        }

        let credential = WeatherProviderCredential(
            providerName: name,
            keychainKey: UUID().uuidString
        )

        do {
            // Save API key to Keychain
            try KeychainManager.shared.save(apiKey, for: credential.keychainKey)

            // Save credential to SwiftData
            modelContext.insert(credential)
            try modelContext.save()

            // Set as active provider if none exists
            if currentPreferences.activeProviderId == nil {
                try preferencesManager.updateActiveProvider(credential.id)
                currentPreferences = preferencesManager.getPreferences()
            }

            showAddProvider = false
        } catch {
            handleError("Failed to add provider: \(error.localizedDescription)")
        }
    }

    /// Delete an existing provider and its credentials
    /// - Parameter credential: The provider credential to delete
    func deleteProvider(_ credential: WeatherProviderCredential) {
        guard let modelContext = modelContext,
              let preferencesManager = preferencesManager else {
            handleError("Persistence is not available")
            return
        }

        do {
            // Remove from Keychain
            try KeychainManager.shared.delete(for: credential.keychainKey)

            // Remove from SwiftData
            modelContext.delete(credential)
            try modelContext.save()

            // Reset active provider if the deleted one was active
            if currentPreferences.activeProviderId == credential.id {
                // Find next available provider to set as active
                let deletedId = credential.id
                let descriptor = FetchDescriptor<WeatherProviderCredential>(
                    predicate: #Predicate { $0.id != deletedId }
                )
                let otherProviders = (try? modelContext.fetch(descriptor)) ?? []
                let fallbackId = otherProviders.first?.id ?? ""

                try preferencesManager.resetActiveProvider(to: fallbackId)
                currentPreferences = preferencesManager.getPreferences()
            }
        } catch {
            handleError("Failed to delete provider: \(error.localizedDescription)")
        }
    }

    // MARK: - Preference Updates

    /// Update the active weather provider
    /// - Parameter providerId: ID of the provider to activate
    func updateActiveProvider(_ providerId: String) {
        guard let preferencesManager = preferencesManager else {
            handleError("Preferences are not available")
            return
        }

        do {
            try preferencesManager.updateActiveProvider(providerId)
            currentPreferences = preferencesManager.getPreferences()
            // Notify ContentViewModel to reconfigure with new provider
            NotificationCenter.default.post(name: NSNotification.Name("ActiveProviderChanged"), object: nil)
        } catch {
            handleError("Failed to update provider: \(error.localizedDescription)")
        }
    }

    /// Update the temperature unit preference
    /// - Parameter unit: Unit preference (metric or imperial)
    func updateUnitPreference(_ unit: UnitPreference) {
        guard let preferencesManager = preferencesManager else {
            handleError("Preferences are not available")
            return
        }

        do {
            try preferencesManager.updateUnitPreference(unit)
            currentPreferences = preferencesManager.getPreferences()
        } catch {
            handleError("Failed to update units: \(error.localizedDescription)")
        }
    }

    /// Update the color scheme preference
    /// - Parameter colorScheme: Color scheme preference (light, dark, or system)
    func updateColorScheme(_ colorScheme: ColorScheme) {
        guard let preferencesManager = preferencesManager else {
            handleError("Preferences are not available")
            return
        }

        do {
            try preferencesManager.updateColorScheme(colorScheme)
            currentPreferences = preferencesManager.getPreferences()
            // Notify app to apply new theme
            NotificationCenter.default.post(name: NSNotification.Name("ColorSchemeChanged"), object: nil)
        } catch {
            handleError("Failed to update color scheme: \(error.localizedDescription)")
        }
    }

    // MARK: - Error Handling

    /// Handle errors by displaying them to the user
    /// - Parameter message: Error message to display
    private func handleError(_ message: String) {
        errorMessage = message
        showError = true
    }

    // MARK: - State Queries

    /// Check if a provider is currently active
    /// - Parameter providerId: ID to check
    func isActiveProvider(_ providerId: String) -> Bool {
        preferencesManager?.isActiveProvider(providerId) ?? false
    }

    /// Refresh preferences from persistent storage
    func refreshPreferences() {
        if let preferencesManager {
            currentPreferences = preferencesManager.getPreferences()
        }
    }
}
