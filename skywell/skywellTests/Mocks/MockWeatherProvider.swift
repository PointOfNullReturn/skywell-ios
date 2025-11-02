//
//  MockWeatherProvider.swift
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
@testable import skywell

/// Mock implementation of WeatherProvider for testing
class MockWeatherProvider: WeatherProvider {
    let name = "mock"

    var mockWeather: Weather?
    var shouldThrow: Error?
    var supportsShouldReturn = true
    var lastRequestReceived: WeatherRequest?

    func supports(_ request: WeatherRequest) -> Bool {
        lastRequestReceived = request
        return supportsShouldReturn
    }

    func fetchWeather(_ request: WeatherRequest) async throws -> Weather {
        lastRequestReceived = request

        if let error = shouldThrow {
            throw error
        }

        guard let weather = mockWeather else {
            throw MockWeatherProviderError.noMockWeatherSet
        }

        return weather
    }
}

enum MockWeatherProviderError: Error {
    case noMockWeatherSet
}
