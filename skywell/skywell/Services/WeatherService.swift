//
//  WeatherService.swift
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

/// Application Service: Orchestrates weather data retrieval
///
/// Coordinates between the UI and weather data providers (adapters).
/// Accepts an injected WeatherProvider to decouple from specific implementations.
class WeatherService {
    private let provider: WeatherProvider
    private let keychainManager: KeychainManager

    init(provider: WeatherProvider, keychainManager: KeychainManager = .shared) {
        self.provider = provider
        self.keychainManager = keychainManager
    }

    /// Fetch weather for given coordinates using the configured provider
    ///
    /// All requests are made using metric units (international standard).
    /// Unit conversion for display should be handled at the presentation layer.
    ///
    /// - Parameters:
    ///   - latitude: Geographic latitude (-90 to 90)
    ///   - longitude: Geographic longitude (-180 to 180)
    ///   - completion: Callback with optional Weather result
    func fetchWeather(
        latitude: Double,
        longitude: Double,
        completion: @escaping (Weather?) -> Void
    ) {
        let request = WeatherRequest(latitude: latitude, longitude: longitude)

        Task {
            do {
                let weather = try await provider.fetchWeather(request)
                DispatchQueue.main.async {
                    completion(weather)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}
