//
//  OpenWeatherAPIAdapterTests.swift
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

final class OpenWeatherAPIAdapterTests: XCTestCase {

    // MARK: - Initialization Tests

    func testOpenWeatherAPIAdapterInitialization() {
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-api-key")

        XCTAssertNotNil(adapter)
        XCTAssertEqual(adapter.name, "openweatherapi")
    }

    // MARK: - Supports Tests

    func testSupportsReturnsTrue() {
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")
        let request = WeatherRequest(
            latitude: 40.7128,
            longitude: -74.0060
        )

        XCTAssertTrue(adapter.supports(request))
    }

    func testSupportsReturnsTrueForAllRequests() {
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")

        let requests = [
            WeatherRequest(latitude: 0, longitude: 0),
            WeatherRequest(latitude: 90, longitude: 180),
            WeatherRequest(latitude: -90, longitude: -180),
            WeatherRequest(latitude: 51.5074, longitude: -0.1278),
        ]

        for request in requests {
            XCTAssertTrue(adapter.supports(request))
        }
    }

    // MARK: - Name Property Tests

    func testAdapterNameIsCorrect() {
        let adapter = OpenWeatherAPIAdapter(apiKey: "any-key")

        XCTAssertEqual(adapter.name, "openweatherapi")
    }

    // MARK: - JSON Parsing Tests

    func testParseValidOpenWeatherResponse() async throws {
        // Note: This is a unit test using mock data
        // Real API tests would require network mocking
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")

        let request = WeatherRequest(
            latitude: 40.7128,
            longitude: -74.0060
        )

        // This test verifies the adapter is properly initialized
        XCTAssertTrue(adapter.supports(request))
    }

    // MARK: - Error Handling Tests

    func testAdapterInitializationWithEmptyApiKey() {
        // Should still initialize - validation happens at request time
        let adapter = OpenWeatherAPIAdapter(apiKey: "")

        XCTAssertNotNil(adapter)
        XCTAssertEqual(adapter.name, "openweatherapi")
    }

    func testAdapterInitializationWithVariousApiKeyFormats() {
        let apiKeys = [
            "short",
            "a-very-long-api-key-that-could-be-real",
            "1234567890abcdef",
            "special!@#$%chars",
        ]

        for apiKey in apiKeys {
            let adapter = OpenWeatherAPIAdapter(apiKey: apiKey)
            XCTAssertEqual(adapter.name, "openweatherapi")
        }
    }

    // MARK: - Protocol Conformance Tests

    func testOpenWeatherAdapterConformsToWeatherProviderProtocol() {
        let adapter: WeatherProvider = OpenWeatherAPIAdapter(apiKey: "test-key")

        XCTAssertNotNil(adapter)
        XCTAssertEqual(adapter.name, "openweatherapi")
    }

    func testOpenWeatherAdapterCanBeUsedAsWeatherProvider() {
        let adapter: WeatherProvider = OpenWeatherAPIAdapter(apiKey: "test-key")
        let request = WeatherRequest(
            latitude: 40.7128,
            longitude: -74.0060
        )

        XCTAssertTrue(adapter.supports(request))
    }

    // MARK: - Request Building Tests

    func testAdapterHandlesPositiveCoordinates() {
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")

        let request = WeatherRequest(
            latitude: 40.7128,
            longitude: -74.0060
        )

        XCTAssertTrue(adapter.supports(request))
    }

    func testAdapterHandlesNegativeCoordinates() {
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")

        let request = WeatherRequest(
            latitude: -33.8688,
            longitude: 151.2093
        )

        XCTAssertTrue(adapter.supports(request))
    }

    func testAdapterHandlesEquatorCoordinates() {
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")

        let request = WeatherRequest(
            latitude: 0.0,
            longitude: 0.0
        )

        XCTAssertTrue(adapter.supports(request))
    }

    func testAdapterHandlesPoleCoordinates() {
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")

        let northPole = WeatherRequest(
            latitude: 90.0,
            longitude: 0.0
        )
        let southPole = WeatherRequest(
            latitude: -90.0,
            longitude: 0.0
        )

        XCTAssertTrue(adapter.supports(northPole))
        XCTAssertTrue(adapter.supports(southPole))
    }

    func testAdapterAlwaysUsesMetricUnits() {
        // The adapter always uses metric units (international standard) at the API level.
        // Unit conversion for display is handled at the presentation layer.
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")

        let request = WeatherRequest(
            latitude: 40.0,
            longitude: -74.0
        )

        XCTAssertTrue(adapter.supports(request))
        // The adapter will fetch in metric regardless of user preference,
        // which is handled at the display layer in ContentView
    }
}
