//
//  TemperatureConversionTests.swift
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

final class TemperatureConversionTests: XCTestCase {

    // MARK: - Temperature Conversion Formula Tests
    // Formula: °F = (°C × 9/5) + 32

    func testConvertZeroCelsiusToFahrenheit() {
        let celsius = 0.0
        let fahrenheit = (celsius * 9 / 5) + 32

        XCTAssertEqual(fahrenheit, 32.0, accuracy: 0.01)
    }

    func testConvertFreesingPoint() {
        // 0°C = 32°F
        let celsius = 0.0
        let fahrenheit = (celsius * 9 / 5) + 32

        XCTAssertEqual(fahrenheit, 32.0, accuracy: 0.01)
    }

    func testConvertBoilingPoint() {
        // 100°C = 212°F
        let celsius = 100.0
        let fahrenheit = (celsius * 9 / 5) + 32

        XCTAssertEqual(fahrenheit, 212.0, accuracy: 0.01)
    }

    func testConvertBodyTemperature() {
        // 37°C = 98.6°F
        let celsius = 37.0
        let fahrenheit = (celsius * 9 / 5) + 32

        XCTAssertEqual(fahrenheit, 98.6, accuracy: 0.01)
    }

    func testConvertRoomTemperature() {
        // 20°C = 68°F
        let celsius = 20.0
        let fahrenheit = (celsius * 9 / 5) + 32

        XCTAssertEqual(fahrenheit, 68.0, accuracy: 0.01)
    }

    func testConvertComfortableTemperature() {
        // 22°C = 71.6°F
        let celsius = 22.0
        let fahrenheit = (celsius * 9 / 5) + 32

        XCTAssertEqual(fahrenheit, 71.6, accuracy: 0.01)
    }

    // MARK: - Extreme Temperature Tests

    func testConvertExtremelyLowTemperature() {
        // -40°C = -40°F (special case where both scales converge)
        let celsius = -40.0
        let fahrenheit = (celsius * 9 / 5) + 32

        XCTAssertEqual(fahrenheit, -40.0, accuracy: 0.01)
    }

    func testConvertNegativeTemperature() {
        // -10°C = 14°F
        let celsius = -10.0
        let fahrenheit = (celsius * 9 / 5) + 32

        XCTAssertEqual(fahrenheit, 14.0, accuracy: 0.01)
    }

    func testConvertVeryHighTemperature() {
        // 50°C = 122°F
        let celsius = 50.0
        let fahrenheit = (celsius * 9 / 5) + 32

        XCTAssertEqual(fahrenheit, 122.0, accuracy: 0.01)
    }

    func testConvertAntarcticTemperature() {
        // -80°C = -112°F
        let celsius = -80.0
        let fahrenheit = (celsius * 9 / 5) + 32

        XCTAssertEqual(fahrenheit, -112.0, accuracy: 0.01)
    }

    func testConvertDeathValleyTemperature() {
        // 54°C = 129.2°F (Death Valley record)
        let celsius = 54.0
        let fahrenheit = (celsius * 9 / 5) + 32

        XCTAssertEqual(fahrenheit, 129.2, accuracy: 0.01)
    }

    // MARK: - Decimal Temperature Tests

    func testConvertDecimalTemperature() {
        // 22.5°C = 72.5°F
        let celsius = 22.5
        let fahrenheit = (celsius * 9 / 5) + 32

        XCTAssertEqual(fahrenheit, 72.5, accuracy: 0.01)
    }

    func testConvertSmallDecimalTemperature() {
        // 15.3°C = 59.54°F
        let celsius = 15.3
        let fahrenheit = (celsius * 9 / 5) + 32

        XCTAssertEqual(fahrenheit, 59.54, accuracy: 0.01)
    }

    func testConvertNegativeDecimalTemperature() {
        // -5.5°C = 22.1°F
        let celsius = -5.5
        let fahrenheit = (celsius * 9 / 5) + 32

        XCTAssertEqual(fahrenheit, 22.1, accuracy: 0.01)
    }

    // MARK: - Inverse Conversion (Fahrenheit to Celsius)
    // Formula: °C = (°F - 32) × 5/9

    func testInverseConvert32Fahrenheit() {
        // 32°F = 0°C
        let fahrenheit = 32.0
        let celsius = (fahrenheit - 32) * 5 / 9

        XCTAssertEqual(celsius, 0.0, accuracy: 0.01)
    }

    func testInverseConvert212Fahrenheit() {
        // 212°F = 100°C
        let fahrenheit = 212.0
        let celsius = (fahrenheit - 32) * 5 / 9

        XCTAssertEqual(celsius, 100.0, accuracy: 0.01)
    }

    func testInverseConvert68Fahrenheit() {
        // 68°F = 20°C
        let fahrenheit = 68.0
        let celsius = (fahrenheit - 32) * 5 / 9

        XCTAssertEqual(celsius, 20.0, accuracy: 0.01)
    }

    func testInverseConvert98Point6Fahrenheit() {
        // 98.6°F = 37°C
        let fahrenheit = 98.6
        let celsius = (fahrenheit - 32) * 5 / 9

        XCTAssertEqual(celsius, 37.0, accuracy: 0.01)
    }

    // MARK: - Rounding Tests

    func testRoundingWhenConverting() {
        let celsius = 20.0
        let fahrenheit = (celsius * 9 / 5) + 32
        let rounded = round(fahrenheit * 10) / 10  // Round to 1 decimal place

        XCTAssertEqual(rounded, 68.0)
    }

    func testPrecisionWithDecimalValues() {
        let celsius = 18.5
        let fahrenheit = (celsius * 9 / 5) + 32

        XCTAssertEqual(fahrenheit, 65.3, accuracy: 0.01)
    }

    // MARK: - Common Weather Temperatures

    func testConvertColdWeatherTemperature() {
        // Winter: -5°C = 23°F
        let celsius = -5.0
        let fahrenheit = (celsius * 9 / 5) + 32

        XCTAssertEqual(fahrenheit, 23.0, accuracy: 0.01)
    }

    func testConvertMildWeatherTemperature() {
        // Spring: 15°C = 59°F
        let celsius = 15.0
        let fahrenheit = (celsius * 9 / 5) + 32

        XCTAssertEqual(fahrenheit, 59.0, accuracy: 0.01)
    }

    func testConvertWarmWeatherTemperature() {
        // Summer: 25°C = 77°F
        let celsius = 25.0
        let fahrenheit = (celsius * 9 / 5) + 32

        XCTAssertEqual(fahrenheit, 77.0, accuracy: 0.01)
    }

    func testConvertHotWeatherTemperature() {
        // Very hot: 35°C = 95°F
        let celsius = 35.0
        let fahrenheit = (celsius * 9 / 5) + 32

        XCTAssertEqual(fahrenheit, 95.0, accuracy: 0.01)
    }
}
