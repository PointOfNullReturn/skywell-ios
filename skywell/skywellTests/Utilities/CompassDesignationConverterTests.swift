//
//  CompassDesignationConverterTests.swift
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

final class CompassDesignationConverterTests: XCTestCase {

    // MARK: - Cardinal Direction Tests

    func testCardinalDirections() {
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 0), "N")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 45), "NE")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 90), "E")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 135), "SE")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 180), "S")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 225), "SW")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 270), "W")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 315), "NW")
    }

    // MARK: - North Boundary Tests

    func testNorthBoundaries() {
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 0), "N")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 360), "N")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 22), "N")  // Just before NE threshold
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 23), "NE") // Just after NE threshold
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 337), "NW") // Just before N threshold
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 338), "N")  // Just after N threshold
    }

    // MARK: - Within Sector Tests

    func testWithinSectors() {
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 10), "N")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 50), "NE")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 100), "E")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 150), "SE")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 190), "S")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 240), "SW")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 280), "W")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 320), "NW")
    }

    // MARK: - Transition Boundary Tests

    func testNorthToNortheastTransition() {
        // N to NE transition (at 22.5°)
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 22), "N")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 23), "NE")
    }

    func testNortheastToEastTransition() {
        // NE to E transition (at 67.5°)
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 67), "NE")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 68), "E")
    }

    func testEastToSoutheastTransition() {
        // E to SE transition (at 112.5°)
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 112), "E")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 113), "SE")
    }

    func testSoutheastToSouthTransition() {
        // SE to S transition (at 157.5°)
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 157), "SE")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 158), "S")
    }

    func testSouthToSouthwestTransition() {
        // S to SW transition (at 202.5°)
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 202), "S")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 203), "SW")
    }

    func testSouthwestToWestTransition() {
        // SW to W transition (at 247.5°)
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 247), "SW")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 248), "W")
    }

    func testWestToNorthwestTransition() {
        // W to NW transition (at 292.5°)
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 292), "W")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 293), "NW")
    }

    func testNorthwestToNorthTransition() {
        // NW to N transition (at 337.5°)
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 337), "NW")
        XCTAssertEqual(CompassDesignationConverter.compassBearing(from: 338), "N")
    }
}
