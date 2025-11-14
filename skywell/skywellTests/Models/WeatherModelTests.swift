//
//  WeatherModelTests.swift
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
@testable import skywell

final class WeatherModelTests: XCTestCase {

    // MARK: - Weather Tests

    func testWeatherInitialization() {
        let weather = Weather(
            city: "New York",
            condition: "Sunny",
            icon: "01d",
            temperature: 72.5,
            feelsLike: 72.5,
            pressure: 1013,
            humidity: 65,
            windSpeed: 10.0,
            windSpeedDegree: 180,
            windGust: 12.0,
            cloudCover: 0
        )

        XCTAssertEqual(weather.city, "New York")
        XCTAssertEqual(weather.temperature, 72.5)
        XCTAssertEqual(weather.feelsLike, 72.5)
        XCTAssertEqual(weather.condition, "Sunny")
        XCTAssertEqual(weather.windSpeed, 10.0)
        XCTAssertEqual(weather.humidity, 65)
        XCTAssertEqual(weather.icon, "01d")
    }

    func testWeatherWithoutIcon() {
        let weather = Weather(
            city: "Los Angeles",
            condition: "Clear",
            icon: nil,
            temperature: 80.0,
            feelsLike: 80.0,
            pressure: 1013,
            humidity: 50,
            windSpeed: 5.0,
            windSpeedDegree: 90,
            windGust: 6.0,
            cloudCover: 0
        )

        XCTAssertNil(weather.icon)
        XCTAssertEqual(weather.city, "Los Angeles")
        XCTAssertEqual(weather.feelsLike, 80.0)
    }

    func testWeatherEquality() {
        let weather1 = Weather(
            city: "Chicago",
            condition: "Cloudy",
            icon: "04d",
            temperature: 65.0,
            feelsLike: 65.0,
            pressure: 1013,
            humidity: 70,
            windSpeed: 8.0,
            windSpeedDegree: 180,
            windGust: 10.0,
            cloudCover: 50
        )

        let weather2 = Weather(
            city: "Chicago",
            condition: "Cloudy",
            icon: "04d",
            temperature: 65.0,
            feelsLike: 65.0,
            pressure: 1013,
            humidity: 70,
            windSpeed: 8.0,
            windSpeedDegree: 180,
            windGust: 10.0,
            cloudCover: 50
        )

        XCTAssertEqual(weather1, weather2)
    }

    func testWeatherInequality() {
        let weather1 = Weather(
            city: "Boston",
            condition: "Rainy",
            icon: "10d",
            temperature: 55.0,
            feelsLike: 55.0,
            pressure: 1013,
            humidity: 80,
            windSpeed: 12.0,
            windSpeedDegree: 180,
            windGust: 15.0,
            cloudCover: 100
        )

        let weather2 = Weather(
            city: "Boston",
            condition: "Rainy",
            icon: "10d",
            temperature: 56.0,  // Different temperature
            feelsLike: 56.0,
            pressure: 1013,
            humidity: 80,
            windSpeed: 12.0,
            windSpeedDegree: 180,
            windGust: 15.0,
            cloudCover: 100
        )

        XCTAssertNotEqual(weather1, weather2)
    }

    func testWeatherWithNegativeTemperature() {
        let weather = Weather(
            city: "Anchorage",
            condition: "Snow",
            icon: "13d",
            temperature: -15.0,
            feelsLike: -15.0,
            pressure: 1013,
            humidity: 85,
            windSpeed: 20.0,
            windSpeedDegree: 270,
            windGust: 25.0,
            cloudCover: 100
        )

        XCTAssertEqual(weather.temperature, -15.0)
    }

    func testWeatherWithZeroTemperature() {
        let weather = Weather(
            city: "Denver",
            condition: "Clear",
            icon: "01d",
            temperature: 0.0,
            feelsLike: 0.0,
            pressure: 1013,
            humidity: 40,
            windSpeed: 3.0,
            windSpeedDegree: 90,
            windGust: 4.0,
            cloudCover: 0
        )

        XCTAssertEqual(weather.temperature, 0.0)
    }

    // MARK: - WeatherRequest Tests

    func testWeatherRequestInitialization() {
        let request = WeatherRequest(
            latitude: 40.7128,
            longitude: -74.0060
        )

        XCTAssertEqual(request.latitude, 40.7128)
        XCTAssertEqual(request.longitude, -74.0060)
    }

    func testWeatherRequestWithNegativeCoordinates() {
        let request = WeatherRequest(
            latitude: -33.8688,
            longitude: 151.2093
        )

        XCTAssertEqual(request.latitude, -33.8688)
        XCTAssertEqual(request.longitude, 151.2093)
    }

    func testWeatherRequestAlwaysUsesMetric() {
        // All requests always use metric units (international standard)
        // Unit conversion for display happens at presentation layer
        let request = WeatherRequest(
            latitude: 40.0,
            longitude: -74.0
        )

        XCTAssertNotNil(request)
        // No units field - always metric at API level
    }

    // MARK: - WeatherProviderCredential Tests

    func testWeatherProviderCredentialInitialization() {
        let credential = WeatherProviderCredential(
            providerName: "OpenWeatherMap",
            keychainKey: "test-keychain-key"
        )

        XCTAssertEqual(credential.providerName, "OpenWeatherMap")
        XCTAssertEqual(credential.keychainKey, "test-keychain-key")
        XCTAssertNil(credential.lastUsedDate)
        XCTAssertNotNil(credential.createdDate)
    }

    func testWeatherProviderCredentialWithCustomId() {
        let customId = "custom-id-123"
        let credential = WeatherProviderCredential(
            id: customId,
            providerName: "WeatherAPI",
            keychainKey: "api-key-ref"
        )

        XCTAssertEqual(credential.id, customId)
    }

    func testWeatherProviderCredentialWithAutoGeneratedId() {
        let credential = WeatherProviderCredential(
            providerName: "DarkSky",
            keychainKey: "darksky-ref"
        )

        XCTAssertFalse(credential.id.isEmpty)
        // UUID format check (basic - just verify it's not empty and reasonably formatted)
        XCTAssert(credential.id.count > 30)  // UUIDs are typically 36 chars with dashes
    }

    func testWeatherProviderCredentialLastUsedDateInitiallyNil() {
        let credential = WeatherProviderCredential(
            providerName: "Test",
            keychainKey: "test"
        )

        XCTAssertNil(credential.lastUsedDate)
    }

    // MARK: - UserPreferences Tests

    func testUserPreferencesDefaultInitialization() {
        let prefs = UserPreferences()

        XCTAssertEqual(prefs.id, "user-preferences")
        XCTAssertNil(prefs.activeProviderId)
        XCTAssertEqual(prefs.unitPreference, .metric)
        XCTAssertNotNil(prefs.lastModifiedDate)
        XCTAssertFalse(prefs.hasCompletedOnboarding)
    }

    func testUserPreferencesWithActiveProvider() {
        let providerId = "provider-123"
        let prefs = UserPreferences(activeProviderId: providerId)

        XCTAssertEqual(prefs.activeProviderId, providerId)
        XCTAssertEqual(prefs.unitPreference, .metric)
        XCTAssertFalse(prefs.hasCompletedOnboarding)
    }

    func testUserPreferencesWithImperialUnits() {
        let prefs = UserPreferences(unitPreference: .imperial)

        XCTAssertEqual(prefs.unitPreference, .imperial)
        XCTAssertNil(prefs.activeProviderId)
        XCTAssertFalse(prefs.hasCompletedOnboarding)
    }

    func testUserPreferencesWithAllFields() {
        let prefs = UserPreferences(
            activeProviderId: "active-provider",
            unitPreference: .imperial
        )

        XCTAssertEqual(prefs.activeProviderId, "active-provider")
        XCTAssertEqual(prefs.unitPreference, .imperial)
        XCTAssertEqual(prefs.id, "user-preferences")
        XCTAssertFalse(prefs.hasCompletedOnboarding)
    }

    func testUserPreferencesSingletonId() {
        let prefs1 = UserPreferences()
        let prefs2 = UserPreferences(activeProviderId: "test")

        XCTAssertEqual(prefs1.id, "user-preferences")
        XCTAssertEqual(prefs2.id, "user-preferences")
    }

    // MARK: - UnitPreference Enum Tests

    func testUnitPreferenceMetric() {
        let metric = UnitPreference.metric

        XCTAssertEqual(metric.rawValue, "metric")
    }

    func testUnitPreferenceImperial() {
        let imperial = UnitPreference.imperial

        XCTAssertEqual(imperial.rawValue, "imperial")
    }

    func testUnitPreferenceEquality() {
        let metric1 = UnitPreference.metric
        let metric2 = UnitPreference.metric

        XCTAssertEqual(metric1, metric2)
    }

    func testUnitPreferenceInequality() {
        let metric = UnitPreference.metric
        let imperial = UnitPreference.imperial

        XCTAssertNotEqual(metric, imperial)
    }
}
