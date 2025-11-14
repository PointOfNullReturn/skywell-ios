//
//  OpenWeatherOneCallAPIAdapter.swift
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

/// Infrastructure Adapter: OpenWeather One Call 3.0 API implementation
///
/// Fetches current weather conditions using the One Call endpoint.
final class OpenWeatherOneCallAPIAdapter: WeatherProvider {
    let name = "openweatheronecall"

    private let apiKey: String
    private let session: URLSession
    private let baseURL = "https://api.openweathermap.org/data/3.0/onecall"

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func supports(_ request: WeatherRequest) -> Bool {
        // One Call API supports global coordinate lookups without restriction.
        true
    }

    func fetchWeather(_ request: WeatherRequest) async throws -> Weather {
        guard let url = makeURL(for: request) else {
            throw OpenWeatherError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OpenWeatherError.invalidResponse
        }

        return try parseWeather(from: data)
    }

    /// Decode a One Call API payload into the domain Weather model.
    func parseWeather(from data: Data) throws -> Weather {
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(OneCallResponse.self, from: data)
            let current = response.current
            let condition = current.weather.first

            return Weather(
                city: displayName(from: response),
                condition: condition?.main ?? "Unknown",
                icon: condition?.icon,
                temperature: current.temp,
                feelsLike: current.feelsLike,
                pressure: current.pressure,
                humidity: current.humidity,
                windSpeed: current.windSpeed,
                windSpeedDegree: current.windDeg,
                windGust: current.windGust ?? 0.0,
                cloudCover: current.clouds
            )
        } catch {
            throw OpenWeatherError.decodingError
        }
    }

    private func makeURL(for request: WeatherRequest) -> URL? {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(request.latitude)),
            URLQueryItem(name: "lon", value: String(request.longitude)),
            URLQueryItem(name: "exclude", value: "minutely,hourly,daily,alerts"),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "appid", value: apiKey)
        ]
        return components?.url
    }

    private func displayName(from response: OneCallResponse) -> String {
        if let timezoneComponent = response.timezone.split(separator: "/").last {
            let city = timezoneComponent.replacingOccurrences(of: "_", with: " ")
            if !city.isEmpty {
                return city
            }
        }
        return String(format: "%.2f°, %.2f°", response.lat, response.lon)
    }
}

// MARK: - Response Models

private struct OneCallResponse: Decodable {
    let lat: Double
    let lon: Double
    let timezone: String
    let current: Current

    struct Current: Decodable {
        let temp: Double
        let feelsLike: Double
        let pressure: Int
        let humidity: Int
        let windSpeed: Double
        let windDeg: Int
        let windGust: Double?
        let clouds: Int
        let weather: [WeatherCondition]

        private enum CodingKeys: String, CodingKey {
            case temp
            case feelsLike = "feels_like"
            case pressure
            case humidity
            case windSpeed = "wind_speed"
            case windDeg = "wind_deg"
            case windGust = "wind_gust"
            case clouds
            case weather
        }
    }

    struct WeatherCondition: Decodable {
        let main: String
        let description: String
        let icon: String
    }
}
