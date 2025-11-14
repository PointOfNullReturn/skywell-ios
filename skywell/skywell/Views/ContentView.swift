//
//  ContentView.swift
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
import SwiftUI
import SwiftData
import CoreLocation

struct ContentView: View {
    // MARK: - Dependencies & Queries

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var preferences: [UserPreferences]
    @Query private var credentials: [WeatherProviderCredential]

    // MARK: - View State

    @StateObject private var viewModel: ContentViewModel
    @State private var navigateToSettings: Bool = false
    @State private var hasConfiguredViewModel = false

    init(viewModel: ContentViewModel = ContentView.makeDefaultViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    /// Determines whether onboarding should appear before the main weather view.
    private var shouldShowOnboarding: Bool {
        guard let preferences = preferences.first else { return true }
        return preferences.hasCompletedOnboarding == false
    }

    // MARK: - Root View

    var body: some View {
        if shouldShowOnboarding {
            OnboardingView()
        } else {
            weatherView
        }
    }

    /// Primary weather screen shown once onboarding has been completed.
    var weatherView: some View {
        NavigationStack {
            VStack {
                Text(viewModel.getLocationName())
                    .font(.largeTitle)
                weatherContent
                Spacer()
            }
            .onAppear {
                configureViewModelIfNeeded()
                guard !isRunningInPreview else { return }
                viewModel.initializeActiveProvider()
                viewModel.requestLocation()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { navigateToSettings = true }) {
                        Image(systemName: "gearshape")
                            .imageScale(.large)
                            .accessibilityLabel("Settings")
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToSettings) {
                SettingsView()
            }
            .alert(isPresented: $viewModel.showError) {
                Alert(title: Text("Error"), message: Text(viewModel.errorMessage ?? "An error occurred."), dismissButton: .default(Text("OK")))
            }
        }
        .background {
            backgroundGradient
                .ignoresSafeArea()
        }
    }

    /// Region responsible for swapping between loading, error, and weather states.
    var weatherContent: some View {
        if viewModel.showError {
            return AnyView(
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    Text("Unable to Fetch Weather")
                        .font(.headline)
                    Text(viewModel.errorMessage ?? "An error occurred")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    Button(action: { viewModel.refreshWeather() }) {
                        Text("Try Again")
                            .padding(8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }
            )
        } else if viewModel.isLoading {
            return AnyView(ProgressView())
        } else if viewModel.currentWeather != nil {
            return AnyView(weatherCard
                .opacity(viewModel.hasLoadedWeather ? 1 : 0)
                .animation(.easeIn(duration: 0.3), value: viewModel.hasLoadedWeather)
            )
        } else {
            return AnyView(
                VStack(spacing: 12) {
                    Image(systemName: "location.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    Text("Waiting for Location")
                        .font(.headline)
                    Text("Fetching your location to get weather…")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            )
        }
    }

    /// Card summarizing current conditions, secondary metrics, and refresh control.
    var weatherCard: some View {
        VStack(spacing: 8) {
            ///Text(viewModel.getLocationName())
             ///   .font(.title)
            Text("\(viewModel.displayTemperature)°\(viewModel.displayTemperatureUnit.replacingOccurrences(of: "°", with: ""))")
                .font(.title2)
            if viewModel.getFeelsLike() != "—" {
                Text("Feels like \(viewModel.getFeelsLike())")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Text(viewModel.getWeatherCondition())
                .font(.headline)
            if let weather = viewModel.currentWeather, let icon = weather.icon {
                AsyncImage(url: URL(string: "https://openweathermap.org/img/wn/\(icon)@2x.png")) { image in
                    image.resizable().frame(width: 50, height: 50)
                } placeholder: {
                    ProgressView()
                }
            }
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Humidity")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(viewModel.getHumidity())
                        .font(.headline)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Wind Speed")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(viewModel.getWindSpeed())
                        .font(.headline)
                }
            }
            .padding(.top, 8)
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Wind Direction")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(viewModel.getWindDirection())
                        .font(.headline)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Wind Gust")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(viewModel.getWindGust())
                        .font(.headline)
                }
            }
            .padding(.top, 8)
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Pressure")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(viewModel.getPressure())
                        .font(.headline)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Cloud Cover")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(viewModel.getCloudCover())
                        .font(.headline)
                }
            }
            .padding(.top, 8)
            Button(action: { viewModel.refreshWeather() }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
            }
            .padding(.top, 12)
        }
        .padding()
    }
    
    @ViewBuilder
    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(red: 0.1, green: 0.1, blue: 0.15), Color(red: 0.05, green: 0.05, blue: 0.1)]
                : [Color(red: 0.4, green: 0.7, blue: 1.0), Color(red: 0.6, green: 0.8, blue: 1.0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Helpers

    private func configureViewModelIfNeeded() {
        guard !hasConfiguredViewModel else { return }

        let preferencesManager = UserPreferencesManager(modelContext: modelContext)
        viewModel.configure(preferencesManager: preferencesManager, modelContext: modelContext)
        hasConfiguredViewModel = true
    }

    /// Default view model used when one is not injected (including previews).
    private static func makeDefaultViewModel() -> ContentViewModel {
        ContentViewModel(
            locationManager: LocationManager(),
            weatherService: WeatherService(provider: OpenWeatherAPIAdapter(apiKey: "")),
            keychainManager: .shared
        )
    }

    /// Convenience flag for disabling side-effects when SwiftUI previews run.
    private var isRunningInPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

#Preview("Configured Weather Card") {
    ContentView(viewModel: .preview)
        .modelContainer(ContentViewPreviewData.makeContainer())
}

// MARK: - Preview Support

private enum ContentViewPreviewData {
    static func makeContainer() -> ModelContainer {
        // In-memory container so previews can render without touching disk or network.
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: WeatherProviderCredential.self,
            UserPreferences.self,
            configurations: configuration
        )

        let context = ModelContext(container)
        let credential = WeatherProviderCredential(providerName: "OpenWeatherMap", keychainKey: "preview-key")
        context.insert(credential)
        let preferences = UserPreferences(activeProviderId: credential.id, hasCompletedOnboarding: true)
        context.insert(preferences)
        try? context.save()
        return container
    }
}

extension ContentViewModel {
    /// Convenience instance with seeded weather/location data for Canvas previews.
    static var preview: ContentViewModel {
        let previewLocationManager = LocationManager()
        // Seed a stable city for Canvas previews.
        previewLocationManager.city = "Seattle"
        previewLocationManager.latitude = 47.6062
        previewLocationManager.longitude = -122.3321

        let viewModel = ContentViewModel(
            locationManager: previewLocationManager,
            weatherService: WeatherService(provider: OpenWeatherAPIAdapter(apiKey: "")),
            keychainManager: .shared
        )

        viewModel.currentWeather = Weather(
            city: "Seattle",
            condition: "Partly Cloudy",
            icon: "02d",
            temperature: 18.0,
            feelsLike: 17.0,
            pressure: 1013,
            humidity: 72,
            windSpeed: 4.5,
            windSpeedDegree: 225,
            windGust: 6.2,
            cloudCover: 40
        )
        viewModel.showError = false
        viewModel.isLoading = false
        return viewModel
    }
}
