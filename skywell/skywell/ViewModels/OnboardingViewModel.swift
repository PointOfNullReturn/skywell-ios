//
//  OnboardingViewModel.swift
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

/// Onboarding step in the user setup flow
enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case locationPermission = 1
    case apiKeySetup = 2
    case completion = 3

    var title: String {
        switch self {
        case .welcome:
            return "Welcome to Skywell"
        case .locationPermission:
            return "Location Access"
        case .apiKeySetup:
            return "Weather API Setup"
        case .completion:
            return "All Set!"
        }
    }

    var description: String {
        switch self {
        case .welcome:
            return "Get accurate weather forecasts for your location."
        case .locationPermission:
            return "We need access to your location to provide weather updates."
        case .apiKeySetup:
            return "Configure a weather provider API key to fetch weather data."
        case .completion:
            return "Your setup is complete. Enjoy Skywell!"
        }
    }
}

/// ViewModel for onboarding flow
///
/// Manages:
/// - Onboarding step progression
/// - Location permission handling
/// - API key configuration
/// - Completion tracking
class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties (for SwiftUI reactivity)

    @Published var currentStep: OnboardingStep = .welcome
    @Published var isOnboardingComplete = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var locationPermissionStatus: LocationStatus = .notDetermined
    @Published var hasApiKey = false
    @Published var showAddProvider = false

    // MARK: - Dependencies

    private let locationManager: LocationManager
    private let preferencesManager: UserPreferencesManager

    // MARK: - Internal State

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        locationManager: LocationManager,
        preferencesManager: UserPreferencesManager
    ) {
        self.locationManager = locationManager
        self.preferencesManager = preferencesManager

        setupBindings()
        checkApiKeyStatus()
    }

    // MARK: - Setup

    private func setupBindings() {
        // Observe location permission status
        NotificationCenter.default.publisher(for: NSNotification.Name("LocationPermissionChanged"))
            .sink { [weak self] _ in
                self?.updateLocationPermissionStatus()
            }
            .store(in: &cancellables)
    }

    // MARK: - Step Navigation

    /// Advance to the next onboarding step
    func advanceStep() {
        let nextRawValue = currentStep.rawValue + 1
        if let nextStep = OnboardingStep(rawValue: nextRawValue) {
            currentStep = nextStep

            // Mark as complete when reaching the completion step
            if currentStep == .completion {
                completeOnboarding()
            }
        }
    }

    /// Go back to the previous onboarding step
    func previousStep() {
        let previousRawValue = currentStep.rawValue - 1
        if let previousStep = OnboardingStep(rawValue: previousRawValue) {
            currentStep = previousStep
        }
    }

    /// Skip onboarding entirely
    func skipOnboarding() {
        completeOnboarding()
    }

    // MARK: - Location Handling

    /// Request location permission from user
    func requestLocationPermission() {
        locationManager.requestLocation()
        updateLocationPermissionStatus()
    }

    /// Update location permission status from LocationManager
    private func updateLocationPermissionStatus() {
        if locationManager.permissionDenied {
            locationPermissionStatus = .denied
        } else if locationManager.latitude != nil && locationManager.longitude != nil {
            locationPermissionStatus = .authorized
        } else {
            locationPermissionStatus = .notDetermined
        }
    }

    // MARK: - API Key Handling

    /// Check if any API key is configured
    private func checkApiKeyStatus() {
        let preferences = preferencesManager.getPreferences()
        hasApiKey = preferences.activeProviderId != nil
    }

    /// Get instruction text for current step
    func getCurrentStepTitle() -> String {
        currentStep.title
    }

    /// Get description text for current step
    func getCurrentStepDescription() -> String {
        currentStep.description
    }

    /// Check if location permission was granted
    func isLocationPermissionGranted() -> Bool {
        locationPermissionStatus == .authorized
    }

    /// Check if we can proceed from current step
    func canProceedFromCurrentStep() -> Bool {
        switch currentStep {
        case .welcome:
            return true
        case .locationPermission:
            // Optional: user can skip location
            return true
        case .apiKeySetup:
            // User must configure at least one API key
            return hasApiKey
        case .completion:
            return false
        }
    }

    // MARK: - Completion

    /// Mark onboarding as complete
    private func completeOnboarding() {
        isOnboardingComplete = true
    }

    // MARK: - Error Handling

    /// Handle errors by displaying them to the user
    /// - Parameter message: Error message to display
    private func handleError(_ message: String) {
        errorMessage = message
        showError = true
    }

    /// Dismiss error message
    func dismissError() {
        errorMessage = nil
        showError = false
    }

    /// Cancel all active subscriptions
    deinit {
        cancellables.removeAll()
    }
}
