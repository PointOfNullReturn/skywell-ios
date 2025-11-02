//
//  TemperatureConverterTests.swift
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

final class TemperatureConverterTests: XCTestCase {

    // MARK: - Celsius to Fahrenheit Tests

    func testConvertFreezingPoint() {
        let result = TemperatureConverter.celsiusToFahrenheit(0)
        XCTAssertEqual(result, 32.0)
    }

    func testConvertBoilingPoint() {
        let result = TemperatureConverter.celsiusToFahrenheit(100)
        XCTAssertEqual(result, 212.0)
    }

    func testConvertRoomTemperature() {
        let result = TemperatureConverter.celsiusToFahrenheit(20)
        XCTAssertEqual(result, 68.0)
    }

    func testConvertBodyTemperature() {
        let result = TemperatureConverter.celsiusToFahrenheit(37)
        XCTAssertEqual(result, 98.6)
    }

    func testConvertNegativeTemperature() {
        let result = TemperatureConverter.celsiusToFahrenheit(-40)
        XCTAssertEqual(result, -40.0)
    }

    func testConvertVeryLowTemperature() {
        let result = TemperatureConverter.celsiusToFahrenheit(-50)
        XCTAssertEqual(result, -58.0)
    }

    func testConvertVeryHighTemperature() {
        let result = TemperatureConverter.celsiusToFahrenheit(50)
        XCTAssertEqual(result, 122.0)
    }

    func testConvertDecimalCelsius() {
        let result = TemperatureConverter.celsiusToFahrenheit(25.5)
        XCTAssertEqual(result, 77.9)
    }

    func testConvertSmallNegativeDecimal() {
        let result = TemperatureConverter.celsiusToFahrenheit(-10.5)
        XCTAssertEqual(result, 13.1, accuracy: 0.01)
    }

    func testConvertColdWeatherTemperature() {
        let result = TemperatureConverter.celsiusToFahrenheit(-5)
        XCTAssertEqual(result, 23.0)
    }

    func testConvertWarmWeatherTemperature() {
        let result = TemperatureConverter.celsiusToFahrenheit(30)
        XCTAssertEqual(result, 86.0)
    }

    func testConvertComfortableTemperature() {
        let result = TemperatureConverter.celsiusToFahrenheit(22)
        XCTAssertEqual(result, 71.6)
    }

    // MARK: - Fahrenheit to Celsius Tests

    func testConvertFreezingPointFahrenheit() {
        let result = TemperatureConverter.fahrenheitToCelsius(32)
        XCTAssertEqual(result, 0.0)
    }

    func testConvertBoilingPointFahrenheit() {
        let result = TemperatureConverter.fahrenheitToCelsius(212)
        XCTAssertEqual(result, 100.0)
    }

    func testConvertRoomTemperatureFahrenheit() {
        let result = TemperatureConverter.fahrenheitToCelsius(68)
        XCTAssertEqual(result, 20.0)
    }

    func testConvertBodyTemperatureFahrenheit() {
        let result = TemperatureConverter.fahrenheitToCelsius(98.6)
        XCTAssertEqual(result, 37.0)
    }

    func testConvertNegativeTemperatureFahrenheit() {
        let result = TemperatureConverter.fahrenheitToCelsius(-40)
        XCTAssertEqual(result, -40.0)
    }

    func testConvertVeryLowTemperatureFahrenheit() {
        let result = TemperatureConverter.fahrenheitToCelsius(-58)
        XCTAssertEqual(result, -50.0)
    }

    func testConvertVeryHighTemperatureFahrenheit() {
        let result = TemperatureConverter.fahrenheitToCelsius(122)
        XCTAssertEqual(result, 50.0)
    }

    func testConvertDecimalFahrenheit() {
        let result = TemperatureConverter.fahrenheitToCelsius(77.9)
        XCTAssertEqual(result, 25.5, accuracy: 0.01)
    }

    func testConvertSmallNegativeDecimalFahrenheit() {
        let result = TemperatureConverter.fahrenheitToCelsius(12.1)
        XCTAssertEqual(result, -11.055555555555555, accuracy: 0.01)
    }

    // MARK: - Round Trip Conversion Tests

    func testRoundTripConversionFromCelsius() {
        let original = 25.0
        let fahrenheit = TemperatureConverter.celsiusToFahrenheit(original)
        let backToCelsius = TemperatureConverter.fahrenheitToCelsius(fahrenheit)
        XCTAssertEqual(backToCelsius, original, accuracy: 0.01)
    }

    func testRoundTripConversionFromFahrenheit() {
        let original = 77.0
        let celsius = TemperatureConverter.fahrenheitToCelsius(original)
        let backToFahrenheit = TemperatureConverter.celsiusToFahrenheit(celsius)
        XCTAssertEqual(backToFahrenheit, original, accuracy: 0.01)
    }

    func testRoundTripWithNegativeValue() {
        let original = -15.0
        let fahrenheit = TemperatureConverter.celsiusToFahrenheit(original)
        let backToCelsius = TemperatureConverter.fahrenheitToCelsius(fahrenheit)
        XCTAssertEqual(backToCelsius, original, accuracy: 0.01)
    }

    func testRoundTripWithDecimalValue() {
        let original = 18.75
        let fahrenheit = TemperatureConverter.celsiusToFahrenheit(original)
        let backToCelsius = TemperatureConverter.fahrenheitToCelsius(fahrenheit)
        XCTAssertEqual(backToCelsius, original, accuracy: 0.01)
    }

    // MARK: - Extreme Value Tests

    func testConvertExtremeColdCelsius() {
        let result = TemperatureConverter.celsiusToFahrenheit(-273)
        XCTAssertEqual(result, -459.4)
    }

    func testConvertExtremeHotCelsius() {
        let result = TemperatureConverter.celsiusToFahrenheit(1000)
        XCTAssertEqual(result, 1832.0)
    }

    func testConvertExtremeColdFahrenheit() {
        let result = TemperatureConverter.fahrenheitToCelsius(-459.4)
        XCTAssertEqual(result, -273.0)
    }

    func testConvertExtremeHotFahrenheit() {
        let result = TemperatureConverter.fahrenheitToCelsius(1832)
        XCTAssertEqual(result, 1000.0, accuracy: 0.1)
    }

    // MARK: - Zero and Near-Zero Tests

    func testConvertZeroCelsius() {
        let result = TemperatureConverter.celsiusToFahrenheit(0)
        XCTAssertEqual(result, 32.0)
    }

    func testConvertZeroFahrenheit() {
        let result = TemperatureConverter.fahrenheitToCelsius(0)
        XCTAssertEqual(result, -17.777777777777778, accuracy: 0.01)
    }

    func testConvertSmallPositiveValue() {
        let result = TemperatureConverter.celsiusToFahrenheit(0.5)
        XCTAssertEqual(result, 32.9)
    }

    func testConvertSmallNegativeValue() {
        let result = TemperatureConverter.celsiusToFahrenheit(-0.5)
        XCTAssertEqual(result, 31.1)
    }

    // MARK: - Precision Tests

    func testConversionPrecision() {
        let temperatures = [0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0]

        for celsius in temperatures {
            let fahrenheit = TemperatureConverter.celsiusToFahrenheit(celsius)
            let expected = (celsius * 9 / 5) + 32
            XCTAssertEqual(fahrenheit, expected, accuracy: 0.0001)
        }
    }

    func testInverseConversionPrecision() {
        let temperatures = [32.0, 50.0, 68.0, 86.0, 104.0, 122.0, 140.0]

        for fahrenheit in temperatures {
            let celsius = TemperatureConverter.fahrenheitToCelsius(fahrenheit)
            let expected = (fahrenheit - 32) * 5 / 9
            XCTAssertEqual(celsius, expected, accuracy: 0.0001)
        }
    }

    // MARK: - Weather Scenario Tests

    func testAntarcticTemperature() {
        let result = TemperatureConverter.celsiusToFahrenheit(-89)
        XCTAssertEqual(result, -128.2)
    }

    func testDeathValleyTemperature() {
        let result = TemperatureConverter.celsiusToFahrenheit(56.7)
        XCTAssertEqual(result, 134.06)
    }

    func testAverageGlobalTemperature() {
        let result = TemperatureConverter.celsiusToFahrenheit(15)
        XCTAssertEqual(result, 59.0)
    }

    func testTypicalSummerDay() {
        let result = TemperatureConverter.celsiusToFahrenheit(28)
        XCTAssertEqual(result, 82.4)
    }

    func testTypicalWinterDay() {
        let result = TemperatureConverter.celsiusToFahrenheit(-10)
        XCTAssertEqual(result, 14.0)
    }
}
