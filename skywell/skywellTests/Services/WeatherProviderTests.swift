//
//  WeatherProviderTests.swift
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

final class WeatherProviderTests: XCTestCase {

    // MARK: - Protocol Conformance Tests

    func testMockWeatherProviderConformsToProtocol() {
        let provider: WeatherProvider = MockWeatherProvider()

        XCTAssertNotNil(provider)
    }

    func testOpenWeatherAPIAdapterConformsToProtocol() {
        let provider: WeatherProvider = OpenWeatherAPIAdapter(apiKey: "test-key")

        XCTAssertNotNil(provider)
    }

    // MARK: - MockWeatherProvider Tests

    func testMockWeatherProviderName() {
        let provider = MockWeatherProvider()

        XCTAssertEqual(provider.name, "mock")
    }

    func testMockWeatherProviderSupports() {
        let provider = MockWeatherProvider()
        let request = WeatherRequest(
            latitude: 40.0,
            longitude: -74.0
        )

        XCTAssertTrue(provider.supports(request))
    }

    func testMockWeatherProviderSupportsReturnsFalseWhenConfigured() {
        let provider = MockWeatherProvider()
        provider.supportsShouldReturn = false
        let request = WeatherRequest(
            latitude: 40.0,
            longitude: -74.0
        )

        XCTAssertFalse(provider.supports(request))
    }

    func testMockWeatherProviderFetchWeatherReturnsWeather() async throws {
        let provider = MockWeatherProvider()
        let expectedWeather = Weather(
            city: "Test City",
            temperature: 72.0,
            condition: "Sunny",
            windSpeed: 5.0,
            humidity: 60,
            icon: "01d"
        )
        provider.mockWeather = expectedWeather

        let request = WeatherRequest(
            latitude: 40.0,
            longitude: -74.0
        )

        let result = try await provider.fetchWeather(request)

        XCTAssertEqual(result, expectedWeather)
    }

    func testMockWeatherProviderFetchWeatherThrowsError() async {
        let provider = MockWeatherProvider()
        provider.shouldThrow = MockWeatherProviderError.noMockWeatherSet

        let request = WeatherRequest(
            latitude: 40.0,
            longitude: -74.0
        )

        do {
            _ = try await provider.fetchWeather(request)
            XCTFail("Expected error to be thrown")
        } catch is MockWeatherProviderError {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testMockWeatherProviderTracksLastRequest() async throws {
        let provider = MockWeatherProvider()
        provider.mockWeather = Weather(
            city: "Test",
            temperature: 70.0,
            condition: "Clear",
            windSpeed: 3.0,
            humidity: 50,
            icon: nil
        )

        let request = WeatherRequest(
            latitude: 51.5,
            longitude: -0.1
        )

        _ = try await provider.fetchWeather(request)

        XCTAssertNotNil(provider.lastRequestReceived)
        XCTAssertEqual(provider.lastRequestReceived?.latitude, 51.5)
        XCTAssertEqual(provider.lastRequestReceived?.longitude, -0.1)
    }

    func testMockWeatherProviderMultipleWeatherResults() async throws {
        let provider = MockWeatherProvider()

        // First call
        let weather1 = Weather(
            city: "City1",
            temperature: 70.0,
            condition: "Sunny",
            windSpeed: 5.0,
            humidity: 60,
            icon: "01d"
        )
        provider.mockWeather = weather1

        let request1 = WeatherRequest(
            latitude: 40.0,
            longitude: -74.0
        )
        let result1 = try await provider.fetchWeather(request1)
        XCTAssertEqual(result1.city, "City1")

        // Second call with different data
        let weather2 = Weather(
            city: "City2",
            temperature: 75.0,
            condition: "Cloudy",
            windSpeed: 8.0,
            humidity: 65,
            icon: "04d"
        )
        provider.mockWeather = weather2

        let request2 = WeatherRequest(
            latitude: 51.5,
            longitude: -0.1
        )
        let result2 = try await provider.fetchWeather(request2)
        XCTAssertEqual(result2.city, "City2")
    }

    // MARK: - OpenWeatherAPIAdapter Tests

    func testOpenWeatherAPIAdapterName() {
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")

        XCTAssertEqual(adapter.name, "openweatherapi")
    }

    func testOpenWeatherAPIAdapterSupportsAllRequests() {
        let adapter = OpenWeatherAPIAdapter(apiKey: "test-key")
        let request = WeatherRequest(
            latitude: 40.0,
            longitude: -74.0
        )

        XCTAssertTrue(adapter.supports(request))
    }
}
