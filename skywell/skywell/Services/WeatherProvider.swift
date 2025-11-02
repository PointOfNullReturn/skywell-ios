//
//  WeatherProvider.swift
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

protocol WeatherProvider {
    var name: String { get }
    func supports(_ request: WeatherRequest) -> Bool
    func fetchWeather(_ request: WeatherRequest) async throws -> Weather
}
