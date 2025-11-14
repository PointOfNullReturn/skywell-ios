//
//  OpenWeatherOneCallAPIAdapterTests.swift
//  SkywellTests
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

final class OpenWeatherOneCallAPIAdapterTests: XCTestCase {

    func testAdapterName() {
        let adapter = OpenWeatherOneCallAPIAdapter(apiKey: "test-key")
        XCTAssertEqual(adapter.name, "openweatheronecall")
    }

    func testSupportsAlwaysReturnsTrue() {
        let adapter = OpenWeatherOneCallAPIAdapter(apiKey: "test-key")
        let request = WeatherRequest(latitude: 10.0, longitude: 20.0)
        XCTAssertTrue(adapter.supports(request))
    }

    func testParseWeatherDecodesCurrentConditions() throws {
        let adapter = OpenWeatherOneCallAPIAdapter(apiKey: "test-key")
        let data = try XCTUnwrap(samplePayload(timezone: "America/Los_Angeles", weatherIcon: "04d").data(using: .utf8))

        let weather = try adapter.parseWeather(from: data)

        XCTAssertEqual(weather.city, "Los Angeles")
        XCTAssertEqual(weather.temperature, 14.3)
        XCTAssertEqual(weather.feelsLike, 13.2)
        XCTAssertEqual(weather.condition, "Clouds")
        XCTAssertEqual(weather.windSpeed, 3.4)
        XCTAssertEqual(weather.humidity, 82)
        XCTAssertEqual(weather.icon, "04d")
        XCTAssertEqual(weather.pressure, 1013)
        XCTAssertEqual(weather.windSpeedDegree, 180)
        XCTAssertEqual(weather.windGust, 4.0)
        XCTAssertEqual(weather.cloudCover, 50)
    }

    func testParseWeatherFallsBackToCoordinatesWhenTimezoneMissing() throws {
        let adapter = OpenWeatherOneCallAPIAdapter(apiKey: "test-key")
        let data = try XCTUnwrap(samplePayload(timezone: "", weatherIcon: nil).data(using: .utf8))

        let weather = try adapter.parseWeather(from: data)

        XCTAssertEqual(weather.city, "47.61°, -122.33°")
        XCTAssertEqual(weather.condition, "Unknown")
        XCTAssertEqual(weather.icon, nil)
    }

    func testParseWeatherThrowsDecodingErrorForInvalidPayload() throws {
        let adapter = OpenWeatherOneCallAPIAdapter(apiKey: "test-key")
        let invalidData = Data("{}".utf8)

        XCTAssertThrowsError(try adapter.parseWeather(from: invalidData)) { error in
            guard case OpenWeatherError.decodingError = error else {
                return XCTFail("Expected decodingError but received \(error)")
            }
        }
    }

    // MARK: - Helpers

    private func samplePayload(timezone: String, weatherIcon: String?) -> String {
        let iconFragment: String
        if let weatherIcon {
            iconFragment = """
            {
                "main": "Clouds",
                "description": "broken clouds",
                "icon": "\(weatherIcon)"
            }
            """
        } else {
            iconFragment = ""
        }

        let weatherArray = weatherIcon == nil ? "[]" : "[\(iconFragment)]"

        return """
        {
            "lat": 47.61,
            "lon": -122.33,
            "timezone": "\(timezone)",
            "current": {
                "temp": 14.3,
                "feels_like": 13.2,
                "pressure": 1013,
                "humidity": 82,
                "wind_speed": 3.4,
                "wind_deg": 180,
                "wind_gust": 4.0,
                "clouds": 50,
                "weather": \(weatherArray)
            }
        }
        """
    }
}
