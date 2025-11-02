//
//  UserPreferencesManagerTests.swift
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

final class UserPreferencesManagerTests: XCTestCase {

    private var modelContext: ModelContext!
    private var manager: UserPreferencesManager!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: UserPreferences.self, configurations: config)
        modelContext = ModelContext(container)
        manager = UserPreferencesManager(modelContext: modelContext)
    }

    override func tearDown() {
        manager = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - Preference Retrieval Tests

    func testGetPreferencesReturnsDefault() {
        let prefs = manager.getPreferences()

        XCTAssertEqual(prefs.id, "user-preferences")
        XCTAssertNil(prefs.activeProviderId)
        XCTAssertEqual(prefs.unitPreference, .metric)
        XCTAssertEqual(prefs.colorScheme, .system)
        XCTAssertFalse(prefs.hasCompletedOnboarding)
    }

    func testGetPreferencesReturnsSameInstanceOnMultipleCalls() {
        let prefs1 = manager.getPreferences()
        let prefs2 = manager.getPreferences()

        XCTAssertEqual(prefs1.id, prefs2.id)
    }

    func testGetPreferencesEnsuresSingletonConstraint() {
        let prefs1 = manager.getPreferences()
        prefs1.activeProviderId = "provider-123"

        let prefs2 = manager.getPreferences()

        XCTAssertEqual(prefs2.activeProviderId, "provider-123")
    }

    // MARK: - Update Active Provider Tests

    func testUpdateActiveProvider() throws {
        try manager.updateActiveProvider("provider-456")

        let prefs = manager.getPreferences()
        XCTAssertEqual(prefs.activeProviderId, "provider-456")
    }

    func testUpdateActiveProviderUpdatesLastModifiedDate() throws {
        let before = Date()
        Thread.sleep(forTimeInterval: 0.01)

        try manager.updateActiveProvider("provider-789")

        Thread.sleep(forTimeInterval: 0.01)
        let after = Date()

        let prefs = manager.getPreferences()
        XCTAssertGreaterThan(prefs.lastModifiedDate, before)
        XCTAssertLessThan(prefs.lastModifiedDate, after)
    }

    func testUpdateActiveProviderMultipleTimes() throws {
        try manager.updateActiveProvider("provider-1")
        var prefs = manager.getPreferences()
        XCTAssertEqual(prefs.activeProviderId, "provider-1")

        try manager.updateActiveProvider("provider-2")
        prefs = manager.getPreferences()
        XCTAssertEqual(prefs.activeProviderId, "provider-2")

        try manager.updateActiveProvider("provider-3")
        prefs = manager.getPreferences()
        XCTAssertEqual(prefs.activeProviderId, "provider-3")
    }

    // MARK: - Update Unit Preference Tests

    func testUpdateUnitPreferenceToImperial() throws {
        try manager.updateUnitPreference(.imperial)

        let prefs = manager.getPreferences()
        XCTAssertEqual(prefs.unitPreference, .imperial)
    }

    func testUpdateUnitPreferenceBackToMetric() throws {
        try manager.updateUnitPreference(.imperial)
        try manager.updateUnitPreference(.metric)

        let prefs = manager.getPreferences()
        XCTAssertEqual(prefs.unitPreference, .metric)
    }

    func testUpdateUnitPreferenceUpdatesLastModifiedDate() throws {
        let before = Date()
        Thread.sleep(forTimeInterval: 0.01)

        try manager.updateUnitPreference(.imperial)

        Thread.sleep(forTimeInterval: 0.01)
        let after = Date()

        let prefs = manager.getPreferences()
        XCTAssertGreaterThan(prefs.lastModifiedDate, before)
        XCTAssertLessThan(prefs.lastModifiedDate, after)
    }

    // MARK: - Initialize Default Preferences Tests

    func testInitializeDefaultPreferencesWithoutProvider() throws {
        try manager.initializeDefaultPreferences()

        let prefs = manager.getPreferences()
        XCTAssertNil(prefs.activeProviderId)
        XCTAssertEqual(prefs.unitPreference, .metric)
        XCTAssertFalse(prefs.hasCompletedOnboarding)
    }

    func testInitializeDefaultPreferencesWithProvider() throws {
        try manager.initializeDefaultPreferences(activeProviderId: "initial-provider", hasCompletedOnboarding: true)

        let prefs = manager.getPreferences()
        XCTAssertEqual(prefs.activeProviderId, "initial-provider")
        XCTAssertEqual(prefs.unitPreference, .metric)
        XCTAssertTrue(prefs.hasCompletedOnboarding)
    }

    // MARK: - Reset Active Provider Tests

    func testResetActiveProvider() throws {
        try manager.updateActiveProvider("current-provider")
        try manager.resetActiveProvider(to: "new-provider")

        let prefs = manager.getPreferences()
        XCTAssertEqual(prefs.activeProviderId, "new-provider")
    }

    func testResetActiveProviderToClear() throws {
        try manager.updateActiveProvider("some-provider")
        try manager.resetActiveProvider(to: "")

        let prefs = manager.getPreferences()
        XCTAssertNil(prefs.activeProviderId)
    }

    func testResetActiveProviderUpdatesLastModifiedDate() throws {
        try manager.updateActiveProvider("provider-1")
        let after1 = manager.getPreferences().lastModifiedDate

        Thread.sleep(forTimeInterval: 0.01)

        try manager.resetActiveProvider(to: "provider-2")
        let after2 = manager.getPreferences().lastModifiedDate

        XCTAssertGreaterThan(after2, after1)
    }

    // MARK: - Onboarding Completion Tests

    func testMarkOnboardingCompleteSetsFlag() throws {
        try manager.markOnboardingComplete()

        let prefs = manager.getPreferences()
        XCTAssertTrue(prefs.hasCompletedOnboarding)
    }

    func testHasCompletedOnboardingReflectsState() throws {
        XCTAssertFalse(manager.hasCompletedOnboarding())

        try manager.markOnboardingComplete()

        XCTAssertTrue(manager.hasCompletedOnboarding())
    }

    // MARK: - Provider Status Tests

    func testIsActiveProviderReturnsTrueWhenActive() throws {
        try manager.updateActiveProvider("target-provider")

        XCTAssertTrue(manager.isActiveProvider("target-provider"))
    }

    func testIsActiveProviderReturnsFalseWhenInactive() throws {
        try manager.updateActiveProvider("target-provider")

        XCTAssertFalse(manager.isActiveProvider("other-provider"))
    }

    func testIsActiveProviderReturnsFalseWhenNoActive() {
        XCTAssertFalse(manager.isActiveProvider("any-provider"))
    }

    // MARK: - Preference Queries Tests

    func testGetActiveProviderId() throws {
        try manager.updateActiveProvider("query-provider")

        let providerId = manager.getActiveProviderId()
        XCTAssertEqual(providerId, "query-provider")
    }

    func testGetActiveProviderIdReturnsNilWhenNone() {
        let providerId = manager.getActiveProviderId()
        XCTAssertNil(providerId)
    }

    func testGetUnitPreference() throws {
        try manager.updateUnitPreference(.imperial)

        let unit = manager.getUnitPreference()
        XCTAssertEqual(unit, .imperial)
    }

    func testGetUnitPreferenceDefaultsToMetric() {
        let unit = manager.getUnitPreference()
        XCTAssertEqual(unit, .metric)
    }

    // MARK: - Combined Operations Tests

    func testUpdateMultiplePreferencesIndependently() throws {
        try manager.updateActiveProvider("provider-1")
        try manager.updateUnitPreference(.imperial)

        var prefs = manager.getPreferences()
        XCTAssertEqual(prefs.activeProviderId, "provider-1")
        XCTAssertEqual(prefs.unitPreference, .imperial)

        // Update one, verify other unchanged
        try manager.updateActiveProvider("provider-2")
        prefs = manager.getPreferences()
        XCTAssertEqual(prefs.activeProviderId, "provider-2")
        XCTAssertEqual(prefs.unitPreference, .imperial)
    }

    func testCompleteUserPreferenceWorkflow() throws {
        // Initial state
        var prefs = manager.getPreferences()
        XCTAssertNil(prefs.activeProviderId)
        XCTAssertEqual(prefs.unitPreference, .metric)

        // User adds first provider
        try manager.updateActiveProvider("openweathermap")
        prefs = manager.getPreferences()
        XCTAssertEqual(prefs.activeProviderId, "openweathermap")

        // User changes units
        try manager.updateUnitPreference(.imperial)
        prefs = manager.getPreferences()
        XCTAssertEqual(prefs.unitPreference, .imperial)

        // User switches to another provider
        try manager.updateActiveProvider("weatherapi")
        prefs = manager.getPreferences()
        XCTAssertEqual(prefs.activeProviderId, "weatherapi")
        XCTAssertEqual(prefs.unitPreference, .imperial) // Units unchanged

        // User reverts to metric
        try manager.updateUnitPreference(.metric)
        prefs = manager.getPreferences()
        XCTAssertEqual(prefs.activeProviderId, "weatherapi")
        XCTAssertEqual(prefs.unitPreference, .metric)
    }

    // MARK: - Color Scheme Tests

    func testUpdateColorSchemeToDark() throws {
        try manager.updateColorScheme(.dark)

        let prefs = manager.getPreferences()
        XCTAssertEqual(prefs.colorScheme, .dark)
    }

    func testUpdateColorSchemeToLight() throws {
        try manager.updateColorScheme(.light)

        let prefs = manager.getPreferences()
        XCTAssertEqual(prefs.colorScheme, .light)
    }

    func testUpdateColorSchemeToSystem() throws {
        try manager.updateColorScheme(.dark)
        try manager.updateColorScheme(.system)

        let prefs = manager.getPreferences()
        XCTAssertEqual(prefs.colorScheme, .system)
    }

    func testUpdateColorSchemeUpdatesLastModifiedDate() throws {
        let before = Date()
        Thread.sleep(forTimeInterval: 0.01)

        try manager.updateColorScheme(.dark)

        Thread.sleep(forTimeInterval: 0.01)
        let after = Date()

        let prefs = manager.getPreferences()
        XCTAssertGreaterThan(prefs.lastModifiedDate, before)
        XCTAssertLessThan(prefs.lastModifiedDate, after)
    }

    func testUpdateColorSchemeMultipleTimes() throws {
        try manager.updateColorScheme(.light)
        var prefs = manager.getPreferences()
        XCTAssertEqual(prefs.colorScheme, .light)

        try manager.updateColorScheme(.dark)
        prefs = manager.getPreferences()
        XCTAssertEqual(prefs.colorScheme, .dark)

        try manager.updateColorScheme(.system)
        prefs = manager.getPreferences()
        XCTAssertEqual(prefs.colorScheme, .system)
    }

    func testGetColorSchemeDefaultsToSystem() {
        let colorScheme = manager.getColorScheme()
        XCTAssertEqual(colorScheme, .system)
    }

    func testGetColorSchemeAfterUpdate() throws {
        try manager.updateColorScheme(.dark)

        let colorScheme = manager.getColorScheme()
        XCTAssertEqual(colorScheme, .dark)
    }

    func testColorSchemePreferenceIndependentFromOthers() throws {
        try manager.updateActiveProvider("provider-1")
        try manager.updateUnitPreference(.imperial)
        try manager.updateColorScheme(.dark)

        var prefs = manager.getPreferences()
        XCTAssertEqual(prefs.activeProviderId, "provider-1")
        XCTAssertEqual(prefs.unitPreference, .imperial)
        XCTAssertEqual(prefs.colorScheme, .dark)

        // Update one preference, verify others unchanged
        try manager.updateColorScheme(.light)
        prefs = manager.getPreferences()
        XCTAssertEqual(prefs.activeProviderId, "provider-1")
        XCTAssertEqual(prefs.unitPreference, .imperial)
        XCTAssertEqual(prefs.colorScheme, .light)
    }

    func testCompletePreferenceWorkflowWithColorScheme() throws {
        // Initial state
        var prefs = manager.getPreferences()
        XCTAssertEqual(prefs.colorScheme, .system)
        XCTAssertEqual(prefs.unitPreference, .metric)

        // User configures provider
        try manager.updateActiveProvider("openweathermap")
        prefs = manager.getPreferences()
        XCTAssertEqual(prefs.activeProviderId, "openweathermap")
        XCTAssertEqual(prefs.colorScheme, .system)

        // User changes color scheme
        try manager.updateColorScheme(.dark)
        prefs = manager.getPreferences()
        XCTAssertEqual(prefs.colorScheme, .dark)
        XCTAssertEqual(prefs.activeProviderId, "openweathermap")

        // User changes units
        try manager.updateUnitPreference(.imperial)
        prefs = manager.getPreferences()
        XCTAssertEqual(prefs.unitPreference, .imperial)
        XCTAssertEqual(prefs.colorScheme, .dark)
        XCTAssertEqual(prefs.activeProviderId, "openweathermap")

        // User switches color scheme
        try manager.updateColorScheme(.light)
        prefs = manager.getPreferences()
        XCTAssertEqual(prefs.colorScheme, .light)
        XCTAssertEqual(prefs.unitPreference, .imperial)
        XCTAssertEqual(prefs.activeProviderId, "openweathermap")
    }
}
