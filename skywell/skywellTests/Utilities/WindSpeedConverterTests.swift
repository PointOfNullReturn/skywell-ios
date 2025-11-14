//
//  WindSpeedConverterTests.swift
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

final class WindSpeedConverterTests: XCTestCase {

    // MARK: - Meters per Second to Miles per Hour Tests

    func testConvertZeroWindSpeed() {
        let result = WindSpeedConverter.metersPerSecondToMilesPerHour(0)
        XCTAssertEqual(result, 0.0, accuracy: 0.01)
    }

    func testConvertLightBreeze() {
        // 2.5 m/s (light breeze)
        let result = WindSpeedConverter.metersPerSecondToMilesPerHour(2.5)
        XCTAssertEqual(result, 5.59, accuracy: 0.01)
    }

    func testConvertGentleBreeze() {
        // 5.5 m/s (gentle breeze)
        let result = WindSpeedConverter.metersPerSecondToMilesPerHour(5.5)
        XCTAssertEqual(result, 12.30, accuracy: 0.01)
    }

    func testConvertModerateWind() {
        // 10 m/s (fresh breeze)
        let result = WindSpeedConverter.metersPerSecondToMilesPerHour(10)
        XCTAssertEqual(result, 22.37, accuracy: 0.01)
    }

    func testConvertStrongWind() {
        // 20 m/s (strong wind)
        let result = WindSpeedConverter.metersPerSecondToMilesPerHour(20)
        XCTAssertEqual(result, 44.74, accuracy: 0.01)
    }

    func testConvertHurricaneForce() {
        // 33 m/s (hurricane force)
        let result = WindSpeedConverter.metersPerSecondToMilesPerHour(33)
        XCTAssertEqual(result, 73.82, accuracy: 0.01)
    }

    // MARK: - Miles per Hour to Meters per Second Tests

    func testReverseConversionZero() {
        let result = WindSpeedConverter.milesPerHourToMetersPerSecond(0)
        XCTAssertEqual(result, 0.0, accuracy: 0.01)
    }

    func testReverseConversionLightBreeze() {
        // 5.59 mph (light breeze)
        let result = WindSpeedConverter.milesPerHourToMetersPerSecond(5.59)
        XCTAssertEqual(result, 2.5, accuracy: 0.01)
    }

    func testReverseConversionModerateWind() {
        // 22.37 mph (fresh breeze)
        let result = WindSpeedConverter.milesPerHourToMetersPerSecond(22.37)
        XCTAssertEqual(result, 10.0, accuracy: 0.01)
    }

    func testReverseConversionHurricane() {
        // 73.82 mph (hurricane force)
        let result = WindSpeedConverter.milesPerHourToMetersPerSecond(73.82)
        XCTAssertEqual(result, 33.0, accuracy: 0.01)
    }

    // MARK: - Round Trip Conversion Tests

    func testRoundTripConversion() {
        let originalSpeed = 15.5
        let mph = WindSpeedConverter.metersPerSecondToMilesPerHour(originalSpeed)
        let backToMs = WindSpeedConverter.milesPerHourToMetersPerSecond(mph)
        XCTAssertEqual(backToMs, originalSpeed, accuracy: 0.001)
    }

    func testRoundTripConversionVeryLowSpeed() {
        let originalSpeed = 0.5
        let mph = WindSpeedConverter.metersPerSecondToMilesPerHour(originalSpeed)
        let backToMs = WindSpeedConverter.milesPerHourToMetersPerSecond(mph)
        XCTAssertEqual(backToMs, originalSpeed, accuracy: 0.001)
    }

    func testRoundTripConversionHighSpeed() {
        let originalSpeed = 50.0
        let mph = WindSpeedConverter.metersPerSecondToMilesPerHour(originalSpeed)
        let backToMs = WindSpeedConverter.milesPerHourToMetersPerSecond(mph)
        XCTAssertEqual(backToMs, originalSpeed, accuracy: 0.001)
    }

    // MARK: - Decimal Precision Tests

    func testDecimalPrecision() {
        let result = WindSpeedConverter.metersPerSecondToMilesPerHour(7.3)
        // 7.3 m/s = 16.3296 mph
        XCTAssertEqual(result, 16.33, accuracy: 0.01)
    }

    func testDecimalPrecisionVeryPrecise() {
        let result = WindSpeedConverter.metersPerSecondToMilesPerHour(3.14159)
        // 3.14159 m/s ≈ 7.029 mph
        XCTAssertEqual(result, 7.03, accuracy: 0.01)
    }
}
