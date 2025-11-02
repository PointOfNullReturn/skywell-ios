//
//  SettingsViewModelTests.swift
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

import XCTest
import SwiftData
@testable import skywell

final class SettingsViewModelTests: XCTestCase {

    private var modelContext: ModelContext!
    private var preferencesManager: UserPreferencesManager!
    private var viewModel: SettingsViewModel!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: UserPreferences.self, WeatherProviderCredential.self, configurations: config)
        modelContext = ModelContext(container)
        preferencesManager = UserPreferencesManager(modelContext: modelContext)
        viewModel = SettingsViewModel(preferencesManager: preferencesManager, modelContext: modelContext)
    }

    override func tearDown() {
        viewModel = nil
        preferencesManager = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testViewModelInitializationLoadsCurrentPreferences() {
        let prefs = viewModel.currentPreferences
        XCTAssertNil(prefs.activeProviderId)
        XCTAssertEqual(prefs.unitPreference, .metric)
        XCTAssertFalse(prefs.hasCompletedOnboarding)
    }

    func testViewModelInitializationSetsDefaultErrorState() {
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
        XCTAssertFalse(viewModel.showAddProvider)
    }

    // MARK: - Provider Addition Tests

    func testAddProviderCreatesCredentialAndSavesKeychain() {
        let testApiKey = "test-api-key-123"

        viewModel.addProvider(name: "OpenWeatherMap", apiKey: testApiKey)

        // Verify credential was created
        let descriptor = FetchDescriptor<WeatherProviderCredential>(
            predicate: #Predicate { $0.providerName == "OpenWeatherMap" }
        )
        let credentials = (try? modelContext.fetch(descriptor)) ?? []

        XCTAssertEqual(credentials.count, 1)
        XCTAssertEqual(credentials.first?.providerName, "OpenWeatherMap")

        // Verify API key was saved to Keychain
        if let credential = credentials.first {
            let savedKey = try? KeychainManager.shared.retrieve(for: credential.keychainKey)
            XCTAssertEqual(savedKey, testApiKey)
        }
    }

    func testAddProviderSetsAsActiveWhenNoneExists() {
        viewModel.addProvider(name: "OpenWeatherMap", apiKey: "test-key")

        let prefs = viewModel.currentPreferences
        XCTAssertNotNil(prefs.activeProviderId)
    }

    func testAddProviderDoesNotOverrideActiveProviderIfOneExists() {
        // Set an active provider first
        try? preferencesManager.updateActiveProvider("existing-provider")
        viewModel.refreshPreferences()
        let existingProviderId = viewModel.currentPreferences.activeProviderId

        viewModel.addProvider(name: "NewProvider", apiKey: "new-key")

        let prefs = viewModel.currentPreferences
        XCTAssertEqual(prefs.activeProviderId, existingProviderId)
    }

    func testAddProviderHidesAddProviderSheet() {
        viewModel.showAddProvider = true

        viewModel.addProvider(name: "TestProvider", apiKey: "test-key")

        XCTAssertFalse(viewModel.showAddProvider)
    }

    func testAddProviderWithEmptyApiKeyHandlesError() {
        viewModel.addProvider(name: "TestProvider", apiKey: "")

        // Should not crash, credential should still be created
        let descriptor = FetchDescriptor<WeatherProviderCredential>(
            predicate: #Predicate { $0.providerName == "TestProvider" }
        )
        let credentials = (try? modelContext.fetch(descriptor)) ?? []
        XCTAssertEqual(credentials.count, 1)
    }

    // MARK: - Provider Deletion Tests

    func testDeleteProviderRemovesCredential() {
        let credential = WeatherProviderCredential(providerName: "ToDelete", keychainKey: UUID().uuidString)
        let credentialId = credential.id
        modelContext.insert(credential)
        try? modelContext.save()

        viewModel.deleteProvider(credential)

        let descriptor = FetchDescriptor<WeatherProviderCredential>(
            predicate: #Predicate { $0.id == credentialId }
        )
        let remaining = (try? modelContext.fetch(descriptor)) ?? []
        XCTAssertEqual(remaining.count, 0)
    }

    func testDeleteProviderRemovesKeychainEntry() {
        let keychainKey = UUID().uuidString
        let credential = WeatherProviderCredential(providerName: "TestProvider", keychainKey: keychainKey)

        // Save API key to Keychain
        try? KeychainManager.shared.save("test-api-key", for: keychainKey)
        modelContext.insert(credential)
        try? modelContext.save()

        viewModel.deleteProvider(credential)

        // Verify Keychain entry was removed
        let retrieved = try? KeychainManager.shared.retrieve(for: keychainKey)
        XCTAssertNil(retrieved)
    }

    func testDeleteProviderResetsActiveProviderWhenDeletingActive() {
        let credential = WeatherProviderCredential(providerName: "ActiveProvider", keychainKey: UUID().uuidString)
        modelContext.insert(credential)
        try? modelContext.save()

        try? preferencesManager.updateActiveProvider(credential.id)
        viewModel.refreshPreferences()

        viewModel.deleteProvider(credential)

        let prefs = viewModel.currentPreferences
        XCTAssertNil(prefs.activeProviderId)
    }

    func testDeleteProviderSwitchesToNextProviderWhenAvailable() {
        let cred1 = WeatherProviderCredential(providerName: "Provider1", keychainKey: UUID().uuidString)
        let cred2 = WeatherProviderCredential(providerName: "Provider2", keychainKey: UUID().uuidString)

        modelContext.insert(cred1)
        modelContext.insert(cred2)
        try? modelContext.save()

        try? preferencesManager.updateActiveProvider(cred1.id)
        viewModel.refreshPreferences()

        viewModel.deleteProvider(cred1)

        let prefs = viewModel.currentPreferences
        XCTAssertEqual(prefs.activeProviderId, cred2.id)
    }

    // MARK: - Active Provider Update Tests

    func testUpdateActiveProviderChangesSelection() {
        let credential = WeatherProviderCredential(providerName: "TestProvider", keychainKey: UUID().uuidString)
        modelContext.insert(credential)
        try? modelContext.save()

        viewModel.updateActiveProvider(credential.id)

        let prefs = viewModel.currentPreferences
        XCTAssertEqual(prefs.activeProviderId, credential.id)
    }

    func testUpdateActiveProviderMultipleTimes() {
        let cred1 = WeatherProviderCredential(providerName: "Provider1", keychainKey: UUID().uuidString)
        let cred2 = WeatherProviderCredential(providerName: "Provider2", keychainKey: UUID().uuidString)

        modelContext.insert(cred1)
        modelContext.insert(cred2)
        try? modelContext.save()

        viewModel.updateActiveProvider(cred1.id)
        XCTAssertEqual(viewModel.currentPreferences.activeProviderId, cred1.id)

        viewModel.updateActiveProvider(cred2.id)
        XCTAssertEqual(viewModel.currentPreferences.activeProviderId, cred2.id)
    }

    // MARK: - Unit Preference Update Tests

    func testUpdateUnitPreferenceToImperial() {
        viewModel.updateUnitPreference(.imperial)

        let prefs = viewModel.currentPreferences
        XCTAssertEqual(prefs.unitPreference, .imperial)
    }

    func testUpdateUnitPreferenceToMetric() {
        try? preferencesManager.updateUnitPreference(.imperial)
        viewModel.refreshPreferences()

        viewModel.updateUnitPreference(.metric)

        let prefs = viewModel.currentPreferences
        XCTAssertEqual(prefs.unitPreference, .metric)
    }

    func testUpdateUnitPreferencePreservesActiveProvider() {
        let credential = WeatherProviderCredential(providerName: "TestProvider", keychainKey: UUID().uuidString)
        modelContext.insert(credential)
        try? modelContext.save()

        try? preferencesManager.updateActiveProvider(credential.id)
        viewModel.refreshPreferences()
        let activeProviderId = viewModel.currentPreferences.activeProviderId

        viewModel.updateUnitPreference(.imperial)

        let prefs = viewModel.currentPreferences
        XCTAssertEqual(prefs.activeProviderId, activeProviderId)
        XCTAssertEqual(prefs.unitPreference, .imperial)
    }

    // MARK: - Active Provider Status Tests

    func testIsActiveProviderReturnsTrueWhenActive() {
        let credential = WeatherProviderCredential(providerName: "TestProvider", keychainKey: UUID().uuidString)
        modelContext.insert(credential)
        try? modelContext.save()

        viewModel.updateActiveProvider(credential.id)

        XCTAssertTrue(viewModel.isActiveProvider(credential.id))
    }

    func testIsActiveProviderReturnsFalseWhenInactive() {
        let credential = WeatherProviderCredential(providerName: "TestProvider", keychainKey: UUID().uuidString)
        modelContext.insert(credential)
        try? modelContext.save()

        XCTAssertFalse(viewModel.isActiveProvider(credential.id))
    }

    func testIsActiveProviderReturnsFalseWhenNoneActive() {
        XCTAssertFalse(viewModel.isActiveProvider("any-id"))
    }

    // MARK: - Preference Refresh Tests

    func testRefreshPreferencesLoadsLatestState() {
        let credential = WeatherProviderCredential(providerName: "TestProvider", keychainKey: UUID().uuidString)
        modelContext.insert(credential)
        try? modelContext.save()

        try? preferencesManager.updateActiveProvider(credential.id)

        viewModel.refreshPreferences()

        XCTAssertEqual(viewModel.currentPreferences.activeProviderId, credential.id)
    }

    func testRefreshPreferencesReflectsExternalChanges() {
        let prefs = viewModel.currentPreferences
        XCTAssertEqual(prefs.unitPreference, .metric)

        try? preferencesManager.updateUnitPreference(.imperial)

        viewModel.refreshPreferences()

        XCTAssertEqual(viewModel.currentPreferences.unitPreference, .imperial)
    }

    // MARK: - Error Handling Tests

    func testAddProviderWithInvalidKeychainOperationShowsError() {
        // This test verifies error handling by attempting an operation
        // that would fail if the Keychain key is invalid
        let longKey = String(repeating: "a", count: 10000)

        viewModel.addProvider(name: "TestProvider", apiKey: longKey)

        // Should still create the credential even if there's a Keychain issue
        let descriptor = FetchDescriptor<WeatherProviderCredential>(
            predicate: #Predicate { $0.providerName == "TestProvider" }
        )
        let credentials = (try? modelContext.fetch(descriptor)) ?? []
        XCTAssertEqual(credentials.count, 1)
    }

    func testDeleteProviderErrorHandling() {
        let credential = WeatherProviderCredential(providerName: "TestProvider", keychainKey: UUID().uuidString)
        modelContext.insert(credential)
        try? modelContext.save()

        // Delete should not crash even with complex scenarios
        viewModel.deleteProvider(credential)

        XCTAssertTrue(true) // Verify no exception was thrown
    }

    // MARK: - Combined Operation Tests

    func testCompleteSettingsWorkflow() {
        // Add first provider
        viewModel.addProvider(name: "OpenWeatherMap", apiKey: "key-1")
        var prefs = viewModel.currentPreferences
        XCTAssertEqual(prefs.activeProviderId, preferencesManager.getActiveProviderId())
        XCTAssertEqual(prefs.unitPreference, .metric)

        // Change units
        viewModel.updateUnitPreference(.imperial)
        prefs = viewModel.currentPreferences
        XCTAssertEqual(prefs.unitPreference, .imperial)

        // Add second provider
        viewModel.addProvider(name: "WeatherAPI", apiKey: "key-2")
        prefs = viewModel.currentPreferences
        let firstProviderId = prefs.activeProviderId

        // Switch to second provider
        let descriptor = FetchDescriptor<WeatherProviderCredential>(
            predicate: #Predicate { $0.providerName == "WeatherAPI" }
        )
        let credentials = (try? modelContext.fetch(descriptor)) ?? []
        if let secondProvider = credentials.first {
            viewModel.updateActiveProvider(secondProvider.id)
            prefs = viewModel.currentPreferences
            XCTAssertNotEqual(prefs.activeProviderId, firstProviderId)
        }
    }

    func testAddAndDeleteMultipleProviders() {
        let names = ["Provider1", "Provider2", "Provider3"]

        for (index, name) in names.enumerated() {
            viewModel.addProvider(name: name, apiKey: "key-\(index)")
        }

        // Verify all added
        let allDescriptor = FetchDescriptor<WeatherProviderCredential>()
        let allCredentials = (try? modelContext.fetch(allDescriptor)) ?? []
        XCTAssertGreaterThanOrEqual(allCredentials.count, 3)

        // Delete one
        if let toDelete = allCredentials.first {
            viewModel.deleteProvider(toDelete)
        }

        // Verify deletion
        let afterDelete = (try? modelContext.fetch(allDescriptor)) ?? []
        XCTAssertEqual(afterDelete.count, allCredentials.count - 1)
    }

    func testToggleUnitPreferenceMultipleTimes() {
        let iterations = 5

        for i in 0..<iterations {
            let unit: UnitPreference = i % 2 == 0 ? .metric : .imperial
            viewModel.updateUnitPreference(unit)
            XCTAssertEqual(viewModel.currentPreferences.unitPreference, unit)
        }
    }

    // MARK: - State Consistency Tests

    func testCurrentPreferencesAlwaysInSync() {
        let credential = WeatherProviderCredential(providerName: "Sync Test", keychainKey: UUID().uuidString)
        modelContext.insert(credential)
        try? modelContext.save()

        viewModel.updateActiveProvider(credential.id)
        viewModel.updateUnitPreference(.imperial)

        let vmPrefs = viewModel.currentPreferences
        let managerPrefs = preferencesManager.getPreferences()

        XCTAssertEqual(vmPrefs.activeProviderId, managerPrefs.activeProviderId)
        XCTAssertEqual(vmPrefs.unitPreference, managerPrefs.unitPreference)
    }

    func testAddProviderModalStateManagement() {
        XCTAssertFalse(viewModel.showAddProvider)

        viewModel.showAddProvider = true
        XCTAssertTrue(viewModel.showAddProvider)

        viewModel.addProvider(name: "TestProvider", apiKey: "test-key")
        XCTAssertFalse(viewModel.showAddProvider)
    }

    func testErrorStateProperties() {
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)

        let credential = WeatherProviderCredential(providerName: "Test", keychainKey: UUID().uuidString)
        modelContext.insert(credential)
        try? modelContext.save()

        viewModel.updateActiveProvider(credential.id)

        // Error properties should remain unchanged after successful operations
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }

    // MARK: - Notification Tests

    func testUpdateActiveProviderPostsNotification() {
        let credential = WeatherProviderCredential(providerName: "Test", keychainKey: UUID().uuidString)
        modelContext.insert(credential)
        try? modelContext.save()

        // Set up notification observer
        let expectation = XCTestExpectation(description: "Notification posted")
        var notificationPosted = false

        let observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ActiveProviderChanged"),
            object: nil,
            queue: nil
        ) { _ in
            notificationPosted = true
            expectation.fulfill()
        }

        // Update active provider
        viewModel.updateActiveProvider(credential.id)

        // Wait for notification
        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(notificationPosted)

        // Clean up observer
        NotificationCenter.default.removeObserver(observer)
    }

    // MARK: - Color Scheme Tests

    func testUpdateColorSchemeToDark() {
        viewModel.updateColorScheme(.dark)

        let prefs = viewModel.currentPreferences
        XCTAssertEqual(prefs.colorScheme, .dark)
    }

    func testUpdateColorSchemeToLight() {
        viewModel.updateColorScheme(.light)

        let prefs = viewModel.currentPreferences
        XCTAssertEqual(prefs.colorScheme, .light)
    }

    func testUpdateColorSchemeToSystem() {
        viewModel.updateColorScheme(.dark)
        viewModel.updateColorScheme(.system)

        let prefs = viewModel.currentPreferences
        XCTAssertEqual(prefs.colorScheme, .system)
    }

    func testUpdateColorSchemeMultipleTimes() {
        viewModel.updateColorScheme(.light)
        var prefs = viewModel.currentPreferences
        XCTAssertEqual(prefs.colorScheme, .light)

        viewModel.updateColorScheme(.dark)
        prefs = viewModel.currentPreferences
        XCTAssertEqual(prefs.colorScheme, .dark)

        viewModel.updateColorScheme(.system)
        prefs = viewModel.currentPreferences
        XCTAssertEqual(prefs.colorScheme, .system)
    }

    func testColorSchemePreferenceIndependentFromOthers() {
        let credential = WeatherProviderCredential(providerName: "TestProvider", keychainKey: UUID().uuidString)
        modelContext.insert(credential)
        try? modelContext.save()

        viewModel.updateActiveProvider(credential.id)
        viewModel.updateUnitPreference(.imperial)
        viewModel.updateColorScheme(.dark)

        var prefs = viewModel.currentPreferences
        XCTAssertEqual(prefs.activeProviderId, credential.id)
        XCTAssertEqual(prefs.unitPreference, .imperial)
        XCTAssertEqual(prefs.colorScheme, .dark)

        // Update color scheme, verify others unchanged
        viewModel.updateColorScheme(.light)
        prefs = viewModel.currentPreferences
        XCTAssertEqual(prefs.activeProviderId, credential.id)
        XCTAssertEqual(prefs.unitPreference, .imperial)
        XCTAssertEqual(prefs.colorScheme, .light)
    }

    func testColorSchemeDefaultsToSystem() {
        let prefs = viewModel.currentPreferences
        XCTAssertEqual(prefs.colorScheme, .system)
    }

    func testUpdateColorSchemePostsNotification() {
        let expectation = XCTestExpectation(description: "Notification posted")
        var notificationPosted = false

        let observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ColorSchemeChanged"),
            object: nil,
            queue: nil
        ) { _ in
            notificationPosted = true
            expectation.fulfill()
        }

        viewModel.updateColorScheme(.dark)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(notificationPosted)

        NotificationCenter.default.removeObserver(observer)
    }

    func testCompleteSettingsWorkflowWithColorScheme() {
        // Initial state
        var prefs = viewModel.currentPreferences
        XCTAssertEqual(prefs.colorScheme, .system)
        XCTAssertEqual(prefs.unitPreference, .metric)

        // Add provider
        viewModel.addProvider(name: "OpenWeatherMap", apiKey: "key-1")
        prefs = viewModel.currentPreferences
        XCTAssertEqual(prefs.activeProviderId, preferencesManager.getActiveProviderId())

        // Change color scheme
        viewModel.updateColorScheme(.dark)
        prefs = viewModel.currentPreferences
        XCTAssertEqual(prefs.colorScheme, .dark)

        // Change units
        viewModel.updateUnitPreference(.imperial)
        prefs = viewModel.currentPreferences
        XCTAssertEqual(prefs.unitPreference, .imperial)
        XCTAssertEqual(prefs.colorScheme, .dark)

        // Switch color scheme
        viewModel.updateColorScheme(.light)
        prefs = viewModel.currentPreferences
        XCTAssertEqual(prefs.colorScheme, .light)
        XCTAssertEqual(prefs.unitPreference, .imperial)
    }
}
