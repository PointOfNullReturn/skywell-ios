//
//  WindSpeedConverter.swift
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

/// Utility for converting wind speed between m/s and mph
///
/// All API responses provide wind speed in m/s (metric).
/// This converter handles display-layer unit conversions for the UI.
struct WindSpeedConverter {

    /// Convert meters per second to miles per hour
    /// - Parameter metersPerSecond: Wind speed in m/s
    /// - Returns: Wind speed in mph
    /// - Formula: mph = m/s × 2.23694
    static func metersPerSecondToMilesPerHour(_ metersPerSecond: Double) -> Double {
        metersPerSecond * 2.23694
    }

    /// Convert miles per hour to meters per second
    /// - Parameter milesPerHour: Wind speed in mph
    /// - Returns: Wind speed in m/s
    /// - Formula: m/s = mph / 2.23694
    static func milesPerHourToMetersPerSecond(_ milesPerHour: Double) -> Double {
        milesPerHour / 2.23694
    }
}
