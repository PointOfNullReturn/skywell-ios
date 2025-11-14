//
//  CompassDesignationConverter.swift
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

import Foundation

/// Utility for converting degrees to compass designations
struct CompassDesignationConverter {

    /// Convert degrees to 8-point compass bearing
    /// - Parameter degrees: Direction in degrees (0-360)
    /// - Returns: Compass bearing abbreviation (N, NE, E, SE, S, SW, W, NW)
    /// - Note: Transitions occur at 22.5° offsets (e.g., 0-22° = N, 23-67° = NE)
    static func compassBearing(from degrees: Int) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((Double(degrees) + 22.5) / 45.0) % 8
        return directions[index]
    }
}
