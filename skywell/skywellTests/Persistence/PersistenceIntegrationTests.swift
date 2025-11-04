//
//  PersistenceIntegrationTests.swift
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

final class PersistenceIntegrationTests: XCTestCase {

    private var modelContext: ModelContext!

    override func setUp() {
        super.setUp()
        // Configure in-memory SwiftData for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: WeatherProviderCredential.self, UserPreferences.self, configurations: config)
        modelContext = ModelContext(container)
    }

    override func tearDown() {
        modelContext = nil
        super.tearDown()
    }

    // MARK: - WeatherProviderCredential Tests

    func testSaveWeatherProviderCredential() throws {
        let credentialID = UUID().uuidString
        let credential = WeatherProviderCredential(
            id: credentialID,
            providerName: "OpenWeatherMap",
            keychainKey: "openweather-key-1"
        )

        modelContext.insert(credential)
        try modelContext.save()

        let descriptor = FetchDescriptor<WeatherProviderCredential>(
            predicate: #Predicate { $0.id == credentialID }
        )
        let fetched = try modelContext.fetch(descriptor)

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.providerName, "OpenWeatherMap")
        XCTAssertEqual(fetched.first?.keychainKey, "openweather-key-1")
    }

    func testRetrieveWeatherProviderCredentialByID() throws {
        let id = UUID().uuidString
        let credential = WeatherProviderCredential(
            id: id,
            providerName: "WeatherAPI",
            keychainKey: "weatherapi-key"
        )

        modelContext.insert(credential)
        try modelContext.save()

        let descriptor = FetchDescriptor<WeatherProviderCredential>(
            predicate: #Predicate { $0.id == id }
        )
        let fetched = try modelContext.fetch(descriptor)

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, id)
    }

    func testUpdateCredentialLastUsedDate() throws {
        let credentialID = UUID().uuidString
        let credential = WeatherProviderCredential(
            id: credentialID,
            providerName: "OpenWeatherMap",
            keychainKey: "key"
        )

        modelContext.insert(credential)
        try modelContext.save()

        let descriptor = FetchDescriptor<WeatherProviderCredential>(
            predicate: #Predicate { $0.id == credentialID }
        )
        var fetched = try modelContext.fetch(descriptor)
        XCTAssertNil(fetched.first?.lastUsedDate)

        // Update lastUsedDate
        fetched.first?.lastUsedDate = Date()
        try modelContext.save()

        // Verify update
        let updated = try modelContext.fetch(descriptor)
        XCTAssertNotNil(updated.first?.lastUsedDate)
    }

    func testDeleteWeatherProviderCredential() throws {
        let credentialID = UUID().uuidString
        let credential = WeatherProviderCredential(
            id: credentialID,
            providerName: "OpenWeatherMap",
            keychainKey: "key"
        )

        modelContext.insert(credential)
        try modelContext.save()

        // Delete
        modelContext.delete(credential)
        try modelContext.save()

        // Verify deletion
        let descriptor = FetchDescriptor<WeatherProviderCredential>(
            predicate: #Predicate { $0.id == credentialID }
        )
        let fetched = try modelContext.fetch(descriptor)
        XCTAssertEqual(fetched.count, 0)
    }

    func testMultipleProvidersWithUniqueIDs() throws {
        let cred1 = WeatherProviderCredential(
            providerName: "OpenWeatherMap",
            keychainKey: "key1"
        )
        let cred2 = WeatherProviderCredential(
            providerName: "WeatherAPI",
            keychainKey: "key2"
        )

        modelContext.insert(cred1)
        modelContext.insert(cred2)
        try modelContext.save()

        let descriptor = FetchDescriptor<WeatherProviderCredential>()
        let fetched = try modelContext.fetch(descriptor)

        XCTAssertEqual(fetched.count, 2)
        XCTAssertNotEqual(cred1.id, cred2.id)
    }

    // MARK: - UserPreferences Tests

    func testSaveUserPreferences() throws {
        let prefs = UserPreferences(
            activeProviderId: "provider-123",
            unitPreference: .imperial
        )

        modelContext.insert(prefs)
        try modelContext.save()

        let descriptor = FetchDescriptor<UserPreferences>(
            predicate: #Predicate { $0.id == "user-preferences" }
        )
        let fetched = try modelContext.fetch(descriptor)

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.activeProviderId, "provider-123")
        XCTAssertEqual(fetched.first?.unitPreference, .imperial)
    }

    func testRetrieveUserPreferencesSingleton() throws {
        let prefs = UserPreferences(
            activeProviderId: "provider-456",
            unitPreference: .metric
        )

        modelContext.insert(prefs)
        try modelContext.save()

        let descriptor = FetchDescriptor<UserPreferences>(
            predicate: #Predicate { $0.id == "user-preferences" }
        )
        let fetched = try modelContext.fetch(descriptor)

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, "user-preferences")
    }

    func testUpdateActiveProvider() throws {
        let prefs = UserPreferences(
            activeProviderId: "provider-1",
            unitPreference: .metric
        )

        modelContext.insert(prefs)
        try modelContext.save()

        // Update active provider
        let descriptor = FetchDescriptor<UserPreferences>(
            predicate: #Predicate { $0.id == "user-preferences" }
        )
        var fetched = try modelContext.fetch(descriptor)
        fetched.first?.activeProviderId = "provider-2"
        try modelContext.save()

        // Verify update
        let updated = try modelContext.fetch(descriptor)
        XCTAssertEqual(updated.first?.activeProviderId, "provider-2")
    }

    func testUpdateUnitPreference() throws {
        let prefs = UserPreferences(unitPreference: .metric)

        modelContext.insert(prefs)
        try modelContext.save()

        let descriptor = FetchDescriptor<UserPreferences>(
            predicate: #Predicate { $0.id == "user-preferences" }
        )
        var fetched = try modelContext.fetch(descriptor)
        fetched.first?.unitPreference = .imperial
        try modelContext.save()

        let updated = try modelContext.fetch(descriptor)
        XCTAssertEqual(updated.first?.unitPreference, .imperial)
    }

    // MARK: - Query and Filtering Tests

    func testQueryAllCredentials() throws {
        let cred1 = WeatherProviderCredential(
            providerName: "OpenWeatherMap",
            keychainKey: "key1"
        )
        let cred2 = WeatherProviderCredential(
            providerName: "WeatherAPI",
            keychainKey: "key2"
        )

        modelContext.insert(cred1)
        modelContext.insert(cred2)
        try modelContext.save()

        let descriptor = FetchDescriptor<WeatherProviderCredential>()
        let all = try modelContext.fetch(descriptor)

        XCTAssertEqual(all.count, 2)
    }

    func testFilterCredentialsByProviderName() throws {
        let cred1 = WeatherProviderCredential(
            providerName: "OpenWeatherMap",
            keychainKey: "key1"
        )
        let cred2 = WeatherProviderCredential(
            providerName: "OpenWeatherMap",
            keychainKey: "key2"
        )
        let cred3 = WeatherProviderCredential(
            providerName: "WeatherAPI",
            keychainKey: "key3"
        )

        modelContext.insert(cred1)
        modelContext.insert(cred2)
        modelContext.insert(cred3)
        try modelContext.save()

        let descriptor = FetchDescriptor<WeatherProviderCredential>(
            predicate: #Predicate { $0.providerName == "OpenWeatherMap" }
        )
        let openWeather = try modelContext.fetch(descriptor)

        XCTAssertEqual(openWeather.count, 2)
    }

    // MARK: - Data Integrity Tests

    func testCreatedDateIsSetOnInit() throws {
        let credentialID = UUID().uuidString
        let beforeInit = Date()
        let credential = WeatherProviderCredential(
            id: credentialID,
            providerName: "OpenWeatherMap",
            keychainKey: "key"
        )
        let afterInit = Date()

        modelContext.insert(credential)
        try modelContext.save()
        let afterInsert = Date()

        let descriptor = FetchDescriptor<WeatherProviderCredential>(
            predicate: #Predicate { $0.id == credentialID }
        )
        let fetched = try modelContext.fetch(descriptor)

        XCTAssertNotNil(fetched.first?.createdDate)
        if let createdDate = fetched.first?.createdDate {
            XCTAssertGreaterThanOrEqual(createdDate, beforeInit)
            XCTAssertLessThanOrEqual(createdDate, max(afterInit, afterInsert))
        }
    }

    func testLastModifiedDateUpdatesOnPreferencesChange() throws {
        let prefs = UserPreferences(
            activeProviderId: "provider-1",
            unitPreference: .metric
        )

        modelContext.insert(prefs)
        try modelContext.save()

        // Wait a tiny bit then update
        Thread.sleep(forTimeInterval: 0.1)

        let descriptor = FetchDescriptor<UserPreferences>(
            predicate: #Predicate { $0.id == "user-preferences" }
        )
        let fetched = try modelContext.fetch(descriptor)
        guard let storedPreferences = fetched.first else {
            XCTFail("Expected stored preferences")
            return
        }

        let originalLastModified = storedPreferences.lastModifiedDate

        let preferencesManager = UserPreferencesManager(modelContext: modelContext)
        try preferencesManager.updateActiveProvider("provider-2")

        let updated = try modelContext.fetch(descriptor)
        let updatedLastModified = updated.first?.lastModifiedDate
        XCTAssertNotNil(updatedLastModified)
        if let updatedLastModified {
            XCTAssertGreaterThan(updatedLastModified, originalLastModified)
        }
    }
}
