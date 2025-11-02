//
//  WeatherRequest.swift
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

/// Domain model for weather requests
///
/// Encapsulates geographic coordinates for weather lookups.
/// All requests use metric units (international standard) at the API level.
/// Unit conversion for display is handled at the presentation layer.
struct WeatherRequest {
    let latitude: Double
    let longitude: Double
}
