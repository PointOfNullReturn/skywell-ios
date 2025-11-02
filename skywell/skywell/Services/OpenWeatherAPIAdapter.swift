//
//  OpenWeatherAPIAdapter.swift
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

/// Infrastructure Adapter: OpenWeatherMap API implementation
///
/// Implements the WeatherProvider protocol to fetch weather data
/// from OpenWeatherMap API using coordinates.
final class OpenWeatherAPIAdapter: WeatherProvider {
    let name = "openweatherapi"
    private let apiKey: String
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func supports(_ req: WeatherRequest) -> Bool {
        return true
    }

    func fetchWeather(_ req: WeatherRequest) async throws -> Weather {
        // Always use metric units (international standard) at the API level
        // Unit conversion for display is handled at the presentation layer
        let urlString = "\(baseURL)?lat=\(req.latitude)&lon=\(req.longitude)&appid=\(apiKey)&units=metric"

        guard let url = URL(string: urlString) else {
            throw OpenWeatherError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OpenWeatherError.invalidResponse
        }

        let decoder = JSONDecoder()
        let openWeatherResponse = try decoder.decode(OpenWeatherResponse.self, from: data)

        return Weather(
            city: openWeatherResponse.name,
            temperature: openWeatherResponse.main.temp,
            condition: openWeatherResponse.weather.first?.main ?? "Unknown",
            windSpeed: openWeatherResponse.wind.speed,
            humidity: openWeatherResponse.main.humidity,
            icon: openWeatherResponse.weather.first?.icon
        )
    }
}

// MARK: - OpenWeatherMap API Response Models

private struct OpenWeatherResponse: Codable {
    let name: String
    let main: Main
    let weather: [WeatherElement]
    let wind: Wind
}

private struct Main: Codable {
    let temp: Double
    let humidity: Int
}

private struct WeatherElement: Codable {
    let main: String
    let description: String
    let icon: String
}

private struct Wind: Codable {
    let speed: Double
}

// MARK: - Error Types

enum OpenWeatherError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from OpenWeatherMap"
        case .decodingError:
            return "Failed to decode weather data"
        }
    }
}
