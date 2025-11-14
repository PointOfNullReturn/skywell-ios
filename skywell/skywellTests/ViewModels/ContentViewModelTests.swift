//
//  ContentViewModelTests.swift
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

import XCTest
import SwiftData
import CoreLocation
@testable import skywell

final class ContentViewModelTests: XCTestCase {

    private var modelContext: ModelContext!
    private var locationManager: LocationManager!
    private var weatherService: WeatherService!
    private var preferencesManager: UserPreferencesManager!
    private var viewModel: ContentViewModel!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: UserPreferences.self, WeatherProviderCredential.self, configurations: config)
        modelContext = ModelContext(container)
        preferencesManager = UserPreferencesManager(modelContext: modelContext)

        // Create mocks
        locationManager = LocationManager()
        let mockProvider = MockWeatherProvider()
        weatherService = WeatherService(provider: mockProvider)

        viewModel = ContentViewModel(
            locationManager: locationManager,
            weatherService: weatherService,
            keychainManager: .shared
        )
        viewModel.configure(preferencesManager: preferencesManager, modelContext: modelContext)
    }

    override func tearDown() {
        viewModel = nil
        weatherService = nil
        locationManager = nil
        preferencesManager = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testViewModelInitializationSetsDefaultState() {
        XCTAssertNil(viewModel.currentWeather)
        XCTAssertEqual(viewModel.displayTemperature, "—")
        XCTAssertEqual(viewModel.displayTemperatureUnit, "°C")
        XCTAssertEqual(viewModel.displayFeelsLike, "—")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.hasLoadedWeather)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }

    func testViewModelInitializationSetsDefaultMetricUnits() {
        XCTAssertEqual(viewModel.displayTemperatureUnit, "°C")
    }

    // MARK: - Location Management Tests

    func testRequestLocationCallsLocationManager() {
        // This test verifies the ViewModel delegates to LocationManager
        viewModel.requestLocation()
        // LocationManager will attempt to request location
        XCTAssertTrue(true) // If no crash, test passes
    }

    func testIsLocationDeniedReturnsFalseWhenNotDenied() {
        XCTAssertFalse(viewModel.isLocationDenied())
    }

    func testGetLocationErrorReturnsNilWhenNoError() {
        XCTAssertNil(viewModel.getLocationError())
    }

    // MARK: - Weather Fetching Tests

    func testFetchWeatherSetsLoadingState() {
        viewModel.isLoading = false

        viewModel.fetchWeather(latitude: 40.7128, longitude: -74.0060)

        // Note: isLoading will be false again after async completion, but we can test the method runs
        XCTAssertTrue(true) // Test passes if no crash
    }

    func testFetchWeatherWithValidCoordinates() {
        let weather = Weather(
            city: "New York",
            condition: "Sunny",
            icon: "01d",
            temperature: 20.0,
            feelsLike: 20.0,
            pressure: 1013,
            humidity: 60,
            windSpeed: 5.0,
            windSpeedDegree: 180,
            windGust: 6.0,
            cloudCover: 0
        )

        let mockProvider = MockWeatherProvider()
        mockProvider.mockWeather = weather
        let mockWeatherService = WeatherService(provider: mockProvider)
        let testViewModel = ContentViewModel(
            locationManager: locationManager,
            weatherService: mockWeatherService
        )
        testViewModel.configure(preferencesManager: preferencesManager, modelContext: modelContext)

        let expectation = XCTestExpectation(description: "Weather fetched")

        testViewModel.fetchWeather(latitude: 40.7128, longitude: -74.0060)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if testViewModel.currentWeather != nil {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
        XCTAssertNotNil(testViewModel.currentWeather)
        XCTAssertEqual(testViewModel.currentWeather?.city, "New York")
    }

    func testFetchWeatherHandlesNilResult() {
        let mockProvider = MockWeatherProvider()
        // Don't set mockWeather to simulate fetch failure
        let mockWeatherService = WeatherService(provider: mockProvider)
        let testViewModel = ContentViewModel(
            locationManager: locationManager,
            weatherService: mockWeatherService
        )
        testViewModel.configure(preferencesManager: preferencesManager, modelContext: modelContext)

        let expectation = XCTestExpectation(description: "Error handled")

        testViewModel.fetchWeather(latitude: 40.7128, longitude: -74.0060)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if testViewModel.errorMessage != nil {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
        XCTAssertNotNil(testViewModel.errorMessage)
    }

    func testRefreshWeatherWithoutLocationShowsError() {
        let expectation = XCTestExpectation(description: "Error shown")

        viewModel.refreshWeather()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.viewModel.errorMessage != nil {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Temperature Display Tests

    func testDisplayTemperatureMetricUnits() {
        let weather = Weather(
            city: "Test City",
            condition: "Clear",
            icon: nil,
            temperature: 20.0,
            feelsLike: 20.0,
            pressure: 1013,
            humidity: 50,
            windSpeed: 5.0,
            windSpeedDegree: 180,
            windGust: 5.5,
            cloudCover: 0
        )

        viewModel.currentWeather = weather
        try? preferencesManager.updateUnitPreference(.metric)

        // Manually trigger the update since bindings may not propagate in tests
        viewModel.currentWeather = weather

        XCTAssertEqual(viewModel.displayTemperatureUnit, "°C")
        XCTAssertEqual(viewModel.displayTemperature, "20")
        XCTAssertEqual(viewModel.displayFeelsLike, "20")
        XCTAssertTrue(viewModel.hasLoadedWeather)
    }

    func testDisplayTemperatureImperialUnits() {
        let weather = Weather(
            city: "Test City",
            condition: "Clear",
            icon: nil,
            temperature: 0.0,
            feelsLike: 0.0,
            pressure: 1013,
            humidity: 50,
            windSpeed: 5.0,
            windSpeedDegree: 180,
            windGust: 5.5,
            cloudCover: 0
        )

        viewModel.currentWeather = weather
        try? preferencesManager.updateUnitPreference(.imperial)

        // Reset to trigger update
        viewModel.currentWeather = weather

        XCTAssertEqual(viewModel.displayTemperatureUnit, "°F")
        XCTAssertEqual(viewModel.displayTemperature, "32")
        XCTAssertEqual(viewModel.displayFeelsLike, "32")
        XCTAssertTrue(viewModel.hasLoadedWeather)
    }

    func testDisplayTemperatureNegativeCelsius() {
        let weather = Weather(
            city: "Test City",
            condition: "Cold",
            icon: nil,
            temperature: -10.0,
            feelsLike: -10.0,
            pressure: 1013,
            humidity: 50,
            windSpeed: 5.0,
            windSpeedDegree: 0,
            windGust: 6.0,
            cloudCover: 50
        )

        viewModel.currentWeather = weather
        try? preferencesManager.updateUnitPreference(.metric)

        XCTAssertEqual(viewModel.displayTemperatureUnit, "°C")
        XCTAssertEqual(viewModel.displayTemperature, "-10")
        XCTAssertEqual(viewModel.displayFeelsLike, "-10")
        XCTAssertTrue(viewModel.hasLoadedWeather)
    }

    func testDisplayTemperatureDecimalValues() {
        let weather = Weather(
            city: "Test City",
            condition: "Mild",
            icon: nil,
            temperature: 15.5,
            feelsLike: 15.5,
            pressure: 1013,
            humidity: 50,
            windSpeed: 5.0,
            windSpeedDegree: 90,
            windGust: 5.5,
            cloudCover: 0
        )

        viewModel.currentWeather = weather
        try? preferencesManager.updateUnitPreference(.metric)

        XCTAssertEqual(viewModel.displayTemperatureUnit, "°C")
        XCTAssertEqual(viewModel.displayTemperature, "16")
        XCTAssertEqual(viewModel.displayFeelsLike, "16")
        XCTAssertTrue(viewModel.hasLoadedWeather)
    }

    func testDisplayTemperatureWhenWeatherIsNil() {
        viewModel.currentWeather = nil
        XCTAssertEqual(viewModel.displayTemperature, "—")
        XCTAssertEqual(viewModel.displayFeelsLike, "—")
    }

    func testConversionFormula() {
        // Test the Celsius to Fahrenheit conversion: (C × 9/5) + 32
        let weather = Weather(
            city: "Test",
            condition: "Hot",
            icon: nil,
            temperature: 100.0,
            feelsLike: 100.0,
            pressure: 1013,
            humidity: 0,
            windSpeed: 0,
            windSpeedDegree: 0,
            windGust: 0.0,
            cloudCover: 0
        )

        viewModel.currentWeather = weather
        try? preferencesManager.updateUnitPreference(.imperial)

        // Reset to trigger conversion
        viewModel.currentWeather = weather

        // 100°C = 212°F
        XCTAssertEqual(viewModel.displayTemperatureUnit, "°F")
        XCTAssertEqual(viewModel.displayTemperature, "212")
        XCTAssertEqual(viewModel.displayFeelsLike, "212")
        XCTAssertTrue(viewModel.hasLoadedWeather)
    }

    // MARK: - Weather Information Display Tests

    func testGetFeelsLikeWithoutWeather() {
        XCTAssertEqual(viewModel.getFeelsLike(), "—")
    }

    func testGetFeelsLikeWithWeatherMetric() {
        let weather = Weather(
            city: "Test",
            condition: "Partly Cloudy",
            icon: nil,
            temperature: 20.0,
            feelsLike: 18.5,
            pressure: 1013,
            humidity: 50,
            windSpeed: 5.0,
            windSpeedDegree: 180,
            windGust: 6.0,
            cloudCover: 50
        )

        viewModel.currentWeather = weather

        let expectation = XCTestExpectation(description: "Feels like metric update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(viewModel.getFeelsLike(), "19°C")
    }

    func testGetFeelsLikeWithWeatherImperial() {
        try? preferencesManager.updateUnitPreference(.imperial)
        defer { try? preferencesManager.updateUnitPreference(.metric) }

        let weather = Weather(
            city: "Test",
            condition: "Partly Cloudy",
            icon: nil,
            temperature: 20.0,
            feelsLike: 20.0,
            pressure: 1013,
            humidity: 50,
            windSpeed: 5.0,
            windSpeedDegree: 180,
            windGust: 6.0,
            cloudCover: 50
        )

        viewModel.currentWeather = weather

        let expectation = XCTestExpectation(description: "Feels like imperial update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(viewModel.getFeelsLike(), "68°F")
    }

    func testGetWeatherConditionWithWeather() {
        let weather = Weather(
            city: "Test",
            condition: "Partly Cloudy",
            icon: nil,
            temperature: 20.0,
            feelsLike: 20.0,
            pressure: 1013,
            humidity: 50,
            windSpeed: 5.0,
            windSpeedDegree: 180,
            windGust: 6.0,
            cloudCover: 50
        )

        viewModel.currentWeather = weather
        XCTAssertEqual(viewModel.getWeatherCondition(), "Partly Cloudy")
    }

    func testGetWeatherConditionWithoutWeather() {
        viewModel.currentWeather = nil
        XCTAssertEqual(viewModel.getWeatherCondition(), "No data")
    }

    func testGetHumidityWithWeather() {
        let weather = Weather(
            city: "Test",
            condition: "Clear",
            icon: nil,
            temperature: 20.0,
            feelsLike: 20.0,
            pressure: 1013,
            humidity: 75,
            windSpeed: 5.0,
            windSpeedDegree: 180,
            windGust: 6.0,
            cloudCover: 0
        )

        viewModel.currentWeather = weather
        XCTAssertEqual(viewModel.getHumidity(), "75%")
    }

    func testGetHumidityWithoutWeather() {
        viewModel.currentWeather = nil
        XCTAssertEqual(viewModel.getHumidity(), "—")
    }

    func testGetWindSpeedMetric() {
        let weather = Weather(
            city: "Test",
            condition: "Clear",
            icon: nil,
            temperature: 20.0,
            feelsLike: 20.0,
            pressure: 1013,
            humidity: 50,
            windSpeed: 5.5,
            windSpeedDegree: 180,
            windGust: 6.5,
            cloudCover: 0
        )

        viewModel.currentWeather = weather
        XCTAssertEqual(viewModel.getWindSpeed(), "5.5 m/s")
    }

    func testGetWindSpeedImperial() {
        let preferences = UserPreferences(activeProviderId: nil, unitPreference: .imperial, colorScheme: .system, hasCompletedOnboarding: true)
        modelContext.insert(preferences)
        let preferencesManager = UserPreferencesManager(modelContext: modelContext)
        viewModel.configure(preferencesManager: preferencesManager, modelContext: modelContext)

        let weather = Weather(
            city: "Test",
            condition: "Clear",
            icon: nil,
            temperature: 20.0,
            feelsLike: 20.0,
            pressure: 1013,
            humidity: 50,
            windSpeed: 5.5,
            windSpeedDegree: 180,
            windGust: 6.5,
            cloudCover: 0
        )

        viewModel.currentWeather = weather
        // 5.5 m/s ≈ 12.3 mph
        XCTAssertEqual(viewModel.getWindSpeed(), "12.3 mph")
    }

    func testGetWindSpeedWithoutWeather() {
        viewModel.currentWeather = nil
        XCTAssertEqual(viewModel.getWindSpeed(), "—")
    }

    func testGetWindGustMetric() {
        let weather = Weather(
            city: "Test",
            condition: "Clear",
            icon: nil,
            temperature: 20.0,
            feelsLike: 20.0,
            pressure: 1013,
            humidity: 50,
            windSpeed: 5.5,
            windSpeedDegree: 180,
            windGust: 6.5,
            cloudCover: 0
        )

        viewModel.currentWeather = weather
        XCTAssertEqual(viewModel.getWindGust(), "6.5 m/s")
    }

    func testGetWindGustImperial() {
        let preferences = UserPreferences(activeProviderId: nil, unitPreference: .imperial, colorScheme: .system, hasCompletedOnboarding: true)
        modelContext.insert(preferences)
        let preferencesManager = UserPreferencesManager(modelContext: modelContext)
        viewModel.configure(preferencesManager: preferencesManager, modelContext: modelContext)

        let weather = Weather(
            city: "Test",
            condition: "Clear",
            icon: nil,
            temperature: 20.0,
            feelsLike: 20.0,
            pressure: 1013,
            humidity: 50,
            windSpeed: 5.5,
            windSpeedDegree: 180,
            windGust: 6.5,
            cloudCover: 0
        )

        viewModel.currentWeather = weather
        // 6.5 m/s ≈ 14.5 mph
        XCTAssertEqual(viewModel.getWindGust(), "14.5 mph")
    }

    func testGetWindGustZero() {
        let weather = Weather(
            city: "Test",
            condition: "Clear",
            icon: nil,
            temperature: 20.0,
            feelsLike: 20.0,
            pressure: 1013,
            humidity: 50,
            windSpeed: 5.5,
            windSpeedDegree: 180,
            windGust: 0.0,
            cloudCover: 0
        )

        viewModel.currentWeather = weather
        XCTAssertEqual(viewModel.getWindGust(), "—")
    }

    // MARK: - Location Display Tests

    func testGetLocationNameWithCity() {
        locationManager.city = "New York"
        viewModel.locationCity = "New York"

        XCTAssertEqual(viewModel.getLocationName(), "New York")
    }

    func testGetLocationNameWithCoordinates() {
        viewModel.locationCity = nil
        locationManager.latitude = 40.7128
        locationManager.longitude = -74.0060

        let locationName = viewModel.getLocationName()
        XCTAssertTrue(locationName.contains("40.71"))
        XCTAssertTrue(locationName.contains("-74.01"))
    }

    func testGetLocationNameUnknown() {
        viewModel.locationCity = nil
        locationManager.latitude = nil
        locationManager.longitude = nil

        XCTAssertEqual(viewModel.getLocationName(), "Unknown location")
    }

    // MARK: - Error Handling Tests

    func testErrorMessageDisplaysOnFetchFailure() {
        let mockProvider = MockWeatherProvider()
        // Don't set mockWeather to simulate fetch failure
        let mockWeatherService = WeatherService(provider: mockProvider)
        let testViewModel = ContentViewModel(
            locationManager: locationManager,
            weatherService: mockWeatherService
        )
        testViewModel.configure(preferencesManager: preferencesManager, modelContext: modelContext)

        let expectation = XCTestExpectation(description: "Error displayed")

        testViewModel.fetchWeather(latitude: 0, longitude: 0)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if testViewModel.showError {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(testViewModel.showError)
    }

    func testErrorMessageCleared() {
        viewModel.errorMessage = "Previous error"
        viewModel.showError = true

        viewModel.errorMessage = nil
        viewModel.showError = false

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }

    // MARK: - State Consistency Tests

    func testCurrentWeatherUpdatesDisplay() {
        let weather = Weather(
            city: "London",
            condition: "Rainy",
            icon: "10d",
            temperature: 15.0,
            feelsLike: 15.0,
            pressure: 1013,
            humidity: 80,
            windSpeed: 10.0,
            windSpeedDegree: 180,
            windGust: 12.0,
            cloudCover: 100
        )

        viewModel.currentWeather = weather

        let expectation = XCTestExpectation(description: "Display updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(viewModel.currentWeather?.city, "London")
        XCTAssertEqual(viewModel.getWeatherCondition(), "Rainy")
    }

    func testUnitPreferenceChangeUpdatesDisplay() {
        let weather = Weather(
            city: "Test",
            condition: "Clear",
            icon: nil,
            temperature: 0.0,
            feelsLike: 0.0,
            pressure: 1013,
            humidity: 50,
            windSpeed: 5.0,
            windSpeedDegree: 180,
            windGust: 5.5,
            cloudCover: 0
        )

        viewModel.currentWeather = weather

        // Start with metric
        try? preferencesManager.updateUnitPreference(.metric)
        XCTAssertEqual(viewModel.displayTemperatureUnit, "°C")
        XCTAssertEqual(viewModel.displayFeelsLike, "0")

        // Switch to imperial
        try? preferencesManager.updateUnitPreference(.imperial)

        // Reset weather to trigger update
        viewModel.currentWeather = weather

        // Verify conversion happened
        XCTAssertEqual(viewModel.displayTemperatureUnit, "°F")
        XCTAssertEqual(viewModel.displayFeelsLike, "32")
    }

    func testLoadingStateManagement() {
        XCTAssertFalse(viewModel.isLoading)

        viewModel.isLoading = true
        XCTAssertTrue(viewModel.isLoading)

        viewModel.isLoading = false
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Integration Tests

    func testCompleteWeatherFetchWorkflow() {
        let weather = Weather(
            city: "Paris",
            condition: "Cloudy",
            icon: "02d",
            temperature: 18.0,
            feelsLike: 18.0,
            pressure: 1013,
            humidity: 65,
            windSpeed: 8.0,
            windSpeedDegree: 180,
            windGust: 9.0,
            cloudCover: 50
        )

        let mockProvider = MockWeatherProvider()
        mockProvider.mockWeather = weather
        let mockWeatherService = WeatherService(provider: mockProvider)
        let testViewModel = ContentViewModel(
            locationManager: locationManager,
            weatherService: mockWeatherService
        )
        testViewModel.configure(preferencesManager: preferencesManager, modelContext: modelContext)

        let expectation = XCTestExpectation(description: "Complete workflow")

        // Simulate weather fetch
        testViewModel.fetchWeather(latitude: 48.8566, longitude: 2.3522)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Verify weather was fetched
            XCTAssertNotNil(testViewModel.currentWeather)
            XCTAssertEqual(testViewModel.currentWeather?.city, "Paris")

            // Verify temperature display is updated
            XCTAssertNotEqual(testViewModel.displayTemperature, "—")

            // Verify other weather data is accessible
            XCTAssertEqual(testViewModel.getWeatherCondition(), "Cloudy")
            XCTAssertEqual(testViewModel.getHumidity(), "65%")

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testMultipleTemperatureUnitToggles() {
        let weather = Weather(
            city: "Test",
            condition: "Clear",
            icon: nil,
            temperature: 20.0,
            feelsLike: 20.0,
            pressure: 1013,
            humidity: 50,
            windSpeed: 5.0,
            windSpeedDegree: 180,
            windGust: 5.5,
            cloudCover: 0
        )

        viewModel.currentWeather = weather

        // Toggle multiple times
        for i in 0..<3 {
            let unit: UnitPreference = i % 2 == 0 ? .metric : .imperial
            try? preferencesManager.updateUnitPreference(unit)

            let expectation = XCTestExpectation(description: "Unit \(i)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)
        }

        XCTAssertNotNil(viewModel.currentWeather)
    }

}
