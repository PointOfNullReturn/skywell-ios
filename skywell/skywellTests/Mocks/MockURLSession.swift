//
//  MockURLSession.swift
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

/// Protocol for mocking URLSession-like behavior
protocol URLSessionProtocol {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

/// Extend URLSession to conform to the protocol
extension URLSession: URLSessionProtocol {}

/// Mock URLSession for testing network requests without actual HTTP calls
class MockURLSessionImpl: URLSessionProtocol {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    var lastURL: URL?
    var callCount = 0

    func data(from url: URL) async throws -> (Data, URLResponse) {
        callCount += 1
        lastURL = url

        if let error = mockError {
            throw error
        }

        guard let data = mockData else {
            throw URLError(.badServerResponse)
        }

        guard let response = mockResponse else {
            throw URLError(.badServerResponse)
        }

        return (data, response)
    }
}

/// Factory for creating mock HTTP responses
struct MockHTTPResponse {
    static func success(statusCode: Int = 200) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://api.openweathermap.org/data/2.5/weather")!,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        ) ?? HTTPURLResponse()
    }

    static func error(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://api.openweathermap.org/data/2.5/weather")!,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        ) ?? HTTPURLResponse()
    }
}

/// Sample valid OpenWeatherMap API response
struct MockWeatherResponses {
    static let validResponse = """
    {
        "coord": {"lon": -74.006, "lat": 40.7128},
        "weather": [
            {
                "id": 800,
                "main": "Clear",
                "description": "clear sky",
                "icon": "01d"
            }
        ],
        "main": {
            "temp": 22.5,
            "feels_like": 21.0,
            "temp_min": 20.0,
            "temp_max": 25.0,
            "pressure": 1013,
            "humidity": 65
        },
        "wind": {
            "speed": 5.5,
            "deg": 230
        },
        "clouds": {"all": 0},
        "dt": 1699000000,
        "sys": {
            "type": 2,
            "id": 2019646,
            "country": "US",
            "sunrise": 1698960000,
            "sunset": 1698999600
        },
        "timezone": -18000,
        "id": 5128581,
        "name": "New York",
        "cod": 200
    }
    """.data(using: .utf8) ?? Data()

    static let missingIconResponse = """
    {
        "coord": {"lon": -74.006, "lat": 40.7128},
        "weather": [
            {
                "id": 800,
                "main": "Clear",
                "description": "clear sky"
            }
        ],
        "main": {
            "temp": 22.5,
            "feels_like": 21.0,
            "temp_min": 20.0,
            "temp_max": 25.0,
            "pressure": 1013,
            "humidity": 65
        },
        "wind": {"speed": 5.5, "deg": 230},
        "clouds": {"all": 0},
        "dt": 1699000000,
        "sys": {
            "type": 2,
            "id": 2019646,
            "country": "US",
            "sunrise": 1698960000,
            "sunset": 1698999600
        },
        "timezone": -18000,
        "id": 5128581,
        "name": "New York",
        "cod": 200
    }
    """.data(using: .utf8) ?? Data()

    static let invalidJSON = "{ invalid json }".data(using: .utf8) ?? Data()

    static let lowTemperatureResponse = """
    {
        "weather": [{"main": "Snow", "description": "light snow", "icon": "13d"}],
        "main": {
            "temp": -15.0,
            "humidity": 85
        },
        "wind": {"speed": 12.0, "deg": 180},
        "name": "Anchorage",
        "cod": 200
    }
    """.data(using: .utf8) ?? Data()

    static let highTemperatureResponse = """
    {
        "weather": [{"main": "Hot", "description": "very hot", "icon": "01d"}],
        "main": {
            "temp": 48.0,
            "humidity": 25
        },
        "wind": {"speed": 2.0, "deg": 90},
        "name": "Death Valley",
        "cod": 200
    }
    """.data(using: .utf8) ?? Data()
}
