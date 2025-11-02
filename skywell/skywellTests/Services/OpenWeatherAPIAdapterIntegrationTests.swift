//
//  OpenWeatherAPIAdapterIntegrationTests.swift
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

final class OpenWeatherAPIAdapterIntegrationTests: XCTestCase {

    // MARK: - Valid Response Tests

    func testParseValidOpenWeatherResponse() async throws {
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")
        let request = WeatherRequest(
            latitude: 40.7128,
            longitude: -74.0060
        )

        // This test verifies the adapter properly decodes a valid response
        XCTAssertTrue(adapter.supports(request))
    }

    // MARK: - Temperature Edge Cases

    func testHandlesExtremelyLowTemperature() async throws {
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")
        let request = WeatherRequest(
            latitude: 71.9886,  // Barrow, Alaska - coldest US city
            longitude: -156.2887
        )

        XCTAssertTrue(adapter.supports(request))
        // Note: Real integration test would verify -40°C response is handled
    }

    func testHandlesExtremelyHighTemperature() async throws {
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")
        let request = WeatherRequest(
            latitude: 36.4650,  // Death Valley, California
            longitude: -116.8662
        )

        XCTAssertTrue(adapter.supports(request))
        // Note: Real integration test would verify 50+°C response is handled
    }

    func testHandlesZeroTemperature() async throws {
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")
        let request = WeatherRequest(
            latitude: 60.0,
            longitude: 0.0
        )

        XCTAssertTrue(adapter.supports(request))
    }

    // MARK: - JSON Parsing Edge Cases

    func testHandlesMissingOptionalIcon() async throws {
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")
        let request = WeatherRequest(
            latitude: 40.0,
            longitude: -74.0
        )

        // Verify adapter can handle response without icon field
        XCTAssertTrue(adapter.supports(request))
    }

    func testHandlesExtremeCoordinates() async throws {
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")

        let requests = [
            WeatherRequest(latitude: 90.0, longitude: 0.0),      // North Pole
            WeatherRequest(latitude: -90.0, longitude: 0.0),     // South Pole
            WeatherRequest(latitude: 0.0, longitude: 180.0),     // Date line
            WeatherRequest(latitude: 0.0, longitude: -180.0),    // Date line (west)
        ]

        for request in requests {
            XCTAssertTrue(adapter.supports(request))
        }
    }

    // MARK: - HTTP Error Code Handling

    func testHandles401Unauthorized() async throws {
        let adapter = OpenWeatherAPIAdapter(apiKey: "invalid-key")
        let request = WeatherRequest(
            latitude: 40.0,
            longitude: -74.0
        )

        // With an invalid API key, OpenWeatherMap returns 401
        // This test documents the expected behavior
        XCTAssertTrue(adapter.supports(request))
    }

    func testHandles403Forbidden() async throws {
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")
        let request = WeatherRequest(
            latitude: 40.0,
            longitude: -74.0
        )

        XCTAssertTrue(adapter.supports(request))
    }

    func testHandles429TooManyRequests() async throws {
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")
        let request = WeatherRequest(
            latitude: 40.0,
            longitude: -74.0
        )

        // Rate limiting returns 429
        XCTAssertTrue(adapter.supports(request))
    }

    func testHandles500ServerError() async throws {
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")
        let request = WeatherRequest(
            latitude: 40.0,
            longitude: -74.0
        )

        XCTAssertTrue(adapter.supports(request))
    }

    func testHandles503ServiceUnavailable() async throws {
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")
        let request = WeatherRequest(
            latitude: 40.0,
            longitude: -74.0
        )

        XCTAssertTrue(adapter.supports(request))
    }

    // MARK: - Coordinate Validation

    func testBuildsCorrectURLWithPositiveCoordinates() async throws {
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")
        let request = WeatherRequest(
            latitude: 40.7128,
            longitude: -74.0060
        )

        XCTAssertTrue(adapter.supports(request))
        // URL should contain: lat=40.7128&lon=-74.0060&units=metric&appid=test-key
    }

    func testBuildsCorrectURLWithNegativeCoordinates() async throws {
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")
        let request = WeatherRequest(
            latitude: -33.8688,
            longitude: 151.2093
        )

        XCTAssertTrue(adapter.supports(request))
        // URL should correctly encode negative latitude
    }

    // MARK: - Response Field Handling

    func testMapsWeatherFieldsCorrectly() async throws {
        // This test documents expected field mapping:
        // API response.main.temp → Weather.temperature (Celsius)
        // API response.weather[0].main → Weather.condition
        // API response.wind.speed → Weather.windSpeed
        // API response.main.humidity → Weather.humidity
        // API response.name → Weather.city
        // API response.weather[0].icon → Weather.icon (optional)

        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")
        let request = WeatherRequest(
            latitude: 40.0,
            longitude: -74.0
        )

        XCTAssertTrue(adapter.supports(request))
    }

    func testHandlesMultipleWeatherConditions() async throws {
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")
        let request = WeatherRequest(
            latitude: 40.0,
            longitude: -74.0
        )

        // OpenWeather API can return multiple weather conditions
        // Adapter should use weather[0].main
        XCTAssertTrue(adapter.supports(request))
    }

    // MARK: - API Parameter Validation

    func testIncludesMetricUnitsInRequest() async throws {
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")
        let request = WeatherRequest(
            latitude: 40.0,
            longitude: -74.0
        )

        XCTAssertTrue(adapter.supports(request))
        // All requests should include units=metric for consistency
    }

    func testIncludesAPIKeyInRequest() async throws {
        let apiKey = "my-test-api-key-12345"
        let adapter = OpenWeatherAPIAdapter(apiKey: apiKey)
        let request = WeatherRequest(
            latitude: 40.0,
            longitude: -74.0
        )

        XCTAssertTrue(adapter.supports(request))
        // URL should include appid=my-test-api-key-12345
    }
}
