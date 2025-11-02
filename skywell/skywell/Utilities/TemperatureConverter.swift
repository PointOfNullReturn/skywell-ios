//
//  TemperatureConverter.swift
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

/// Utility for converting temperatures between Celsius and Fahrenheit
///
/// All API responses provide temperatures in Celsius (metric).
/// This converter handles display-layer unit conversions for the UI.
struct TemperatureConverter {

    /// Convert Celsius to Fahrenheit
    /// - Parameter celsius: Temperature in Celsius
    /// - Returns: Temperature in Fahrenheit
    /// - Formula: (C × 9/5) + 32
    static func celsiusToFahrenheit(_ celsius: Double) -> Double {
        (celsius * 9 / 5) + 32
    }

    /// Convert Fahrenheit to Celsius
    /// - Parameter fahrenheit: Temperature in Fahrenheit
    /// - Returns: Temperature in Celsius
    /// - Formula: (F - 32) × 5/9
    static func fahrenheitToCelsius(_ fahrenheit: Double) -> Double {
        (fahrenheit - 32) * 5 / 9
    }
}
