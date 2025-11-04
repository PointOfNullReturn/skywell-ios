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

import SwiftUI
import SwiftData
import CoreLocation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    @Query private var credentials: [WeatherProviderCredential]

    @StateObject private var viewModel = ContentViewModel(
        locationManager: LocationManager(),
        weatherService: WeatherService(provider: OpenWeatherAPIAdapter(apiKey: "")),
        keychainManager: .shared
    )
    @State private var navigateToSettings: Bool = false
    @State private var hasConfiguredViewModel = false

    private var shouldShowOnboarding: Bool {
        guard let preferences = preferences.first else { return true }
        return preferences.hasCompletedOnboarding == false
    }

    var body: some View {
        if shouldShowOnboarding {
            OnboardingView()
        } else {
            weatherView
        }
    }

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
    }

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

    var weatherCard: some View {
        VStack(spacing: 8) {
            Text(viewModel.getLocationName())
                .font(.title)
            Text("\(viewModel.displayTemperature)°\(viewModel.displayTemperatureUnit.replacingOccurrences(of: "°", with: ""))")
                .font(.title2)
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

    private func configureViewModelIfNeeded() {
        guard !hasConfiguredViewModel else { return }

        let preferencesManager = UserPreferencesManager(modelContext: modelContext)
        viewModel.configure(preferencesManager: preferencesManager, modelContext: modelContext)
        hasConfiguredViewModel = true
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WeatherProviderCredential.self, UserPreferences.self], inMemory: true)
}
