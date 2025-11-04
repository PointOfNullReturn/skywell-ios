//
//  ContentViewModel.swift
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
import Combine
import SwiftData

/// ViewModel for ContentView
///
/// Manages:
/// - Location acquisition and updates
/// - Weather data fetching and display
/// - Temperature unit conversion for display
/// - Error handling and user feedback
class ContentViewModel: ObservableObject {
    // MARK: - Published Properties (for SwiftUI reactivity)

    @Published var currentWeather: Weather? {
        didSet {
            updateDisplayTemperature()
        }
    }
    @Published var displayTemperature: String = "—"
    @Published var displayTemperatureUnit: String = "°C"
    @Published var locationCity: String?
    @Published var isLoading = false
    @Published var hasLoadedWeather = false
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - Dependencies

    private let locationManager: LocationManager
    private var weatherService: WeatherService
    private var preferencesManager: UserPreferencesManager?
    private var modelContext: ModelContext?
    private let keychainManager: KeychainManager

    // MARK: - Internal State

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        locationManager: LocationManager,
        weatherService: WeatherService,
        keychainManager: KeychainManager = .shared
    ) {
        self.locationManager = locationManager
        self.weatherService = weatherService
        self.keychainManager = keychainManager

        setupBindings()
    }

    /// Configure the user preferences manager once the shared context is available
    /// - Parameter preferencesManager: Manager backed by the shared SwiftData context
    func configure(preferencesManager: UserPreferencesManager, modelContext: ModelContext) {
        self.preferencesManager = preferencesManager
        self.modelContext = modelContext
    }

    /// Initialize the active weather provider with its API key from Keychain
    /// Call this after the ViewModel is initialized and ready
    func initializeActiveProvider() {
        self.configureActiveProvider()
    }

    // MARK: - Setup

    private func setupBindings() {
        // Observe latitude updates
        locationManager.$latitude
            .combineLatest(locationManager.$longitude)
            .filter { $0 != nil && $1 != nil }
            .sink { [weak self] latitude, longitude in
                if let lat = latitude, let lon = longitude {
                    self?.fetchWeather(latitude: lat, longitude: lon)
                }
            }
            .store(in: &cancellables)

        // Observe city name updates
        locationManager.$city
            .sink { [weak self] city in
                self?.locationCity = city
            }
            .store(in: &cancellables)

        // Observe unit preference changes
        NotificationCenter.default.publisher(for: NSNotification.Name("UserPreferencesChanged"))
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.refreshPreferences()
                    self.updateDisplayTemperature()
                }
            }
            .store(in: &cancellables)

        // Observe active provider changes
        NotificationCenter.default.publisher(for: NSNotification.Name("ActiveProviderChanged"))
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.refreshPreferences()
                    self.configureActiveProvider()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Provider Configuration

    /// Configure the active weather provider with its API key from Keychain
    func configureActiveProvider() {
        guard let preferences = preferencesManager?.getPreferences() else {
            return
        }

        guard let activeProviderId = preferences.activeProviderId else {
            handleError("No weather provider configured")
            return
        }

        guard let providerCredentials = try? fetchCredential(for: activeProviderId) else {
            handleError("Weather provider credentials not found")
            return
        }

        do {
            let apiKey = try keychainManager.retrieve(for: providerCredentials.keychainKey)
            let provider = OpenWeatherAPIAdapter(apiKey: apiKey)
            self.weatherService = WeatherService(provider: provider, keychainManager: keychainManager)
            // Clear any previous error when provider is successfully configured
            self.errorMessage = nil
            self.showError = false
        } catch {
            handleError("Failed to retrieve API key for provider")
        }
    }

    // MARK: - Location Management

    /// Request location access and begin location updates
    func requestLocation() {
        locationManager.requestLocation()
    }

    /// Check if location access is denied
    func isLocationDenied() -> Bool {
        locationManager.permissionDenied
    }

    /// Get current location error message
    func getLocationError() -> String? {
        locationManager.locationError
    }

    // MARK: - Weather Management

    /// Fetch weather for given coordinates
    /// - Parameters:
    ///   - latitude: Latitude coordinate
    ///   - longitude: Longitude coordinate
    func fetchWeather(latitude: Double, longitude: Double) {
        isLoading = true

        weatherService.fetchWeather(latitude: latitude, longitude: longitude) { [weak self] weather in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let weather = weather {
                    self?.currentWeather = weather
                    self?.hasLoadedWeather = true
                } else {
                    self?.handleError("Failed to fetch weather data")
                    self?.hasLoadedWeather = false
                }
            }
        }
    }

    /// Manually refresh weather data and location
    func refreshWeather() {
        // Request fresh location update (respecting distance filter)
        requestLocation()

        // Also fetch weather with current coordinates if available
        if let latitude = locationManager.latitude, let longitude = locationManager.longitude {
            fetchWeather(latitude: latitude, longitude: longitude)
        } else {
            handleError("Location not available")
        }
    }

    // MARK: - Display Formatting

    /// Update the display temperature string based on unit preference
    private func updateDisplayTemperature() {
        guard let weather = currentWeather else {
            displayTemperature = "—"
            return
        }

        let unitPreference = preferencesManager?.getUnitPreference() ?? .metric
        let tempValue: Double

        if unitPreference == .imperial {
            displayTemperatureUnit = "°F"
            tempValue = TemperatureConverter.celsiusToFahrenheit(weather.temperature)
        } else {
            displayTemperatureUnit = "°C"
            tempValue = weather.temperature
        }

        // Format to 1 decimal place
        displayTemperature = String(format: "%.1f", tempValue)
    }

    /// Refresh cached preferences state if available
    private func refreshPreferences() {
        _ = preferencesManager?.getPreferences()
    }

    private func fetchCredential(for id: String) throws -> WeatherProviderCredential {
        guard let modelContext else {
            throw NSError(domain: "ContentViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Persistence unavailable"])
        }
        var descriptor = FetchDescriptor<WeatherProviderCredential>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        if let credential = try modelContext.fetch(descriptor).first {
            return credential
        }
        throw NSError(domain: "ContentViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Credential missing"])
    }

    /// Get formatted weather condition
    func getWeatherCondition() -> String {
        currentWeather?.condition ?? "No data"
    }

    /// Get formatted location name
    func getLocationName() -> String {
        if let city = locationCity {
            return city
        }
        if let latitude = locationManager.latitude, let longitude = locationManager.longitude {
            return String(format: "%.2f°, %.2f°", latitude, longitude)
        }
        return "Unknown location"
    }

    /// Get humidity value
    func getHumidity() -> String {
        if let weather = currentWeather {
            return "\(weather.humidity)%"
        }
        return "—"
    }

    /// Get wind speed value
    func getWindSpeed() -> String {
        if let weather = currentWeather {
            return String(format: "%.1f m/s", weather.windSpeed)
        }
        return "—"
    }

    // MARK: - Error Handling

    /// Handle errors by displaying them to the user
    /// - Parameter message: Error message to display
    private func handleError(_ message: String) {
        errorMessage = message
        showError = true
    }

    /// Cancel all active subscriptions
    deinit {
        cancellables.removeAll()
    }
}
