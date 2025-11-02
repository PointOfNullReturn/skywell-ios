//
//  WeatherServiceTests.swift
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

final class WeatherServiceTests: XCTestCase {

    // MARK: - Initialization Tests

    func testWeatherServiceInitialization() {
        let mockProvider = MockWeatherProvider()
        let service = WeatherService(provider: mockProvider)

        XCTAssertNotNil(service)
    }

    func testWeatherServiceInitializationWithCustomKeychain() {
        let mockProvider = MockWeatherProvider()
        let service = WeatherService(provider: mockProvider, keychainManager: .shared)

        XCTAssertNotNil(service)
    }

    // MARK: - Fetch Weather Tests

    func testFetchWeatherSuccess() {
        let mockProvider = MockWeatherProvider()
        let expectedWeather = Weather(
            city: "New York",
            temperature: 72.0,
            condition: "Sunny",
            windSpeed: 5.0,
            humidity: 60,
            icon: "01d"
        )
        mockProvider.mockWeather = expectedWeather

        let service = WeatherService(provider: mockProvider)

        var capturedWeather: Weather?
        let expectation = XCTestExpectation(description: "Weather fetch completes")

        service.fetchWeather(latitude: 40.7128, longitude: -74.0060) { weather in
            capturedWeather = weather
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        XCTAssertNotNil(capturedWeather)
        XCTAssertEqual(capturedWeather, expectedWeather)
    }

    func testFetchWeatherCallsProviderWithCorrectCoordinates() {
        let mockProvider = MockWeatherProvider()
        let weather = Weather(
            city: "Los Angeles",
            temperature: 80.0,
            condition: "Clear",
            windSpeed: 3.0,
            humidity: 50,
            icon: "01d"
        )
        mockProvider.mockWeather = weather

        let service = WeatherService(provider: mockProvider)

        let expectation = XCTestExpectation(description: "Weather fetch completes")

        let latitude = 34.0522
        let longitude = -118.2437

        service.fetchWeather(latitude: latitude, longitude: longitude) { _ in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        XCTAssertNotNil(mockProvider.lastRequestReceived)
        XCTAssertEqual(mockProvider.lastRequestReceived?.latitude, latitude)
        XCTAssertEqual(mockProvider.lastRequestReceived?.longitude, longitude)
    }

    func testFetchWeatherWithError() {
        let mockProvider = MockWeatherProvider()
        mockProvider.shouldThrow = MockWeatherProviderError.noMockWeatherSet

        let service = WeatherService(provider: mockProvider)

        var capturedWeather: Weather?
        let expectation = XCTestExpectation(description: "Weather fetch completes with error")

        service.fetchWeather(latitude: 41.8781, longitude: -87.6298) { weather in
            capturedWeather = weather
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        XCTAssertNil(capturedWeather)
    }

    func testFetchWeatherHandlesMultipleRequests() {
        let mockProvider = MockWeatherProvider()
        let service = WeatherService(provider: mockProvider)

        let weather1 = Weather(
            city: "Boston",
            temperature: 65.0,
            condition: "Rainy",
            windSpeed: 10.0,
            humidity: 75,
            icon: "10d"
        )
        let weather2 = Weather(
            city: "Miami",
            temperature: 85.0,
            condition: "Sunny",
            windSpeed: 8.0,
            humidity: 70,
            icon: "01d"
        )

        mockProvider.mockWeather = weather1
        var result1: Weather?
        let expectation1 = XCTestExpectation(description: "First fetch completes")

        service.fetchWeather(latitude: 42.3601, longitude: -71.0589) { weather in
            result1 = weather
            expectation1.fulfill()
        }

        wait(for: [expectation1], timeout: 1.0)
        XCTAssertEqual(result1?.city, "Boston")

        // Change mock data
        mockProvider.mockWeather = weather2
        var result2: Weather?
        let expectation2 = XCTestExpectation(description: "Second fetch completes")

        service.fetchWeather(latitude: 25.7617, longitude: -80.1918) { weather in
            result2 = weather
            expectation2.fulfill()
        }

        wait(for: [expectation2], timeout: 1.0)
        XCTAssertEqual(result2?.city, "Miami")
    }

    func testFetchWeatherCallsCompletionOnMainThread() {
        let mockProvider = MockWeatherProvider()
        let weather = Weather(
            city: "Seattle",
            temperature: 60.0,
            condition: "Cloudy",
            windSpeed: 6.0,
            humidity: 80,
            icon: "04d"
        )
        mockProvider.mockWeather = weather

        let service = WeatherService(provider: mockProvider)

        var callbackThread: Thread?
        let expectation = XCTestExpectation(description: "Callback executes")

        service.fetchWeather(latitude: 47.6062, longitude: -122.3321) { _ in
            callbackThread = Thread.current
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(Thread.current == callbackThread)
    }

    func testFetchWeatherWithVariousCoordinates() {
        let mockProvider = MockWeatherProvider()
        let service = WeatherService(provider: mockProvider)

        let coordinates = [
            (latitude: 40.7128, longitude: -74.0060),   // New York
            (latitude: 34.0522, longitude: -118.2437),  // Los Angeles
            (latitude: 41.8781, longitude: -87.6298),   // Chicago
            (latitude: 29.7604, longitude: -95.3698),   // Houston
            (latitude: 33.4484, longitude: -112.0742),  // Phoenix
        ]

        for (lat, lon) in coordinates {
            mockProvider.mockWeather = Weather(
                city: "Test City",
                temperature: 70.0,
                condition: "Clear",
                windSpeed: 5.0,
                humidity: 60,
                icon: nil
            )

            var result: Weather?
            let expectation = XCTestExpectation(description: "Fetch at (\(lat), \(lon))")

            service.fetchWeather(latitude: lat, longitude: lon) { weather in
                result = weather
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 1.0)
            XCTAssertNotNil(result)
        }
    }

    func testFetchWeatherPreservesWeatherData() {
        let mockProvider = MockWeatherProvider()
        let weather = Weather(
            city: "Denver",
            temperature: 68.5,
            condition: "Partly Cloudy",
            windSpeed: 7.3,
            humidity: 55,
            icon: "02d"
        )
        mockProvider.mockWeather = weather

        let service = WeatherService(provider: mockProvider)

        var result: Weather?
        let expectation = XCTestExpectation(description: "Weather fetch")

        service.fetchWeather(latitude: 39.7392, longitude: -104.9903) { w in
            result = w
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(result?.city, "Denver")
        XCTAssertEqual(result?.temperature, 68.5)
        XCTAssertEqual(result?.condition, "Partly Cloudy")
        XCTAssertEqual(result?.windSpeed, 7.3)
        XCTAssertEqual(result?.humidity, 55)
        XCTAssertEqual(result?.icon, "02d")
    }
}
