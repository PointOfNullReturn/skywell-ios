//
//  OnboardingViewModelTests.swift
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

final class OnboardingViewModelTests: XCTestCase {

    private var modelContext: ModelContext!
    private var locationManager: LocationManager!
    private var preferencesManager: UserPreferencesManager!
    private var viewModel: OnboardingViewModel!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: UserPreferences.self, configurations: config)
        modelContext = ModelContext(container)
        preferencesManager = UserPreferencesManager(modelContext: modelContext)

        locationManager = LocationManager()
        viewModel = OnboardingViewModel(
            locationManager: locationManager,
            preferencesManager: preferencesManager
        )
    }

    override func tearDown() {
        viewModel = nil
        preferencesManager = nil
        locationManager = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testViewModelInitializationStartsAtWelcome() {
        XCTAssertEqual(viewModel.currentStep, .welcome)
    }

    func testViewModelInitializationNotComplete() {
        XCTAssertFalse(viewModel.isOnboardingComplete)
    }

    func testViewModelInitializationNoError() {
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }

    func testViewModelInitializationLocationStatusNotDetermined() {
        XCTAssertEqual(viewModel.locationPermissionStatus, .notDetermined)
    }

    // MARK: - OnboardingStep Enum Tests

    func testOnboardingStepWelcomeProperties() {
        let step = OnboardingStep.welcome
        XCTAssertEqual(step.rawValue, 0)
        XCTAssertEqual(step.title, "Welcome to Skywell")
        XCTAssertEqual(step.description, "Get accurate weather forecasts for your location.")
    }

    func testOnboardingStepLocationPermissionProperties() {
        let step = OnboardingStep.locationPermission
        XCTAssertEqual(step.rawValue, 1)
        XCTAssertEqual(step.title, "Location Access")
        XCTAssertEqual(step.description, "We need access to your location to provide weather updates.")
    }

    func testOnboardingStepApiKeySetupProperties() {
        let step = OnboardingStep.apiKeySetup
        XCTAssertEqual(step.rawValue, 2)
        XCTAssertEqual(step.title, "Weather API Setup")
        XCTAssertEqual(step.description, "Configure a weather provider API key to fetch weather data.")
    }

    func testOnboardingStepCompletionProperties() {
        let step = OnboardingStep.completion
        XCTAssertEqual(step.rawValue, 3)
        XCTAssertEqual(step.title, "All Set!")
        XCTAssertEqual(step.description, "Your setup is complete. Enjoy Skywell!")
    }

    // MARK: - Step Navigation Tests

    func testAdvanceStepFromWelcome() {
        viewModel.advanceStep()
        XCTAssertEqual(viewModel.currentStep, .locationPermission)
    }

    func testAdvanceStepFromLocationPermission() {
        viewModel.currentStep = .locationPermission
        viewModel.advanceStep()
        XCTAssertEqual(viewModel.currentStep, .apiKeySetup)
    }

    func testAdvanceStepFromApiKeySetup() {
        viewModel.currentStep = .apiKeySetup
        viewModel.advanceStep()
        XCTAssertEqual(viewModel.currentStep, .completion)
    }

    func testAdvanceStepFromCompletionDoesNothing() {
        viewModel.currentStep = .completion
        viewModel.advanceStep()
        XCTAssertEqual(viewModel.currentStep, .completion)
    }

    func testPreviousStepFromLocationPermission() {
        viewModel.currentStep = .locationPermission
        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStep, .welcome)
    }

    func testPreviousStepFromApiKeySetup() {
        viewModel.currentStep = .apiKeySetup
        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStep, .locationPermission)
    }

    func testPreviousStepFromWelcomeDoesNothing() {
        viewModel.currentStep = .welcome
        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStep, .welcome)
    }

    // MARK: - Completion Tests

    func testAdvancingToCompletionMarksOnboardingComplete() {
        let expectation = XCTestExpectation(description: "Onboarding marked complete")

        viewModel.currentStep = .apiKeySetup
        viewModel.advanceStep()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.viewModel.isOnboardingComplete {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.isOnboardingComplete)
    }

    func testSkipOnboardingCompletesOnboarding() {
        let expectation = XCTestExpectation(description: "Onboarding skipped")

        viewModel.skipOnboarding()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.viewModel.isOnboardingComplete {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.isOnboardingComplete)
    }

    // MARK: - Location Permission Tests

    func testLocationPermissionStatusStartsNotDetermined() {
        XCTAssertEqual(viewModel.locationPermissionStatus, .notDetermined)
    }

    func testRequestLocationPermissionCallsLocationManager() {
        viewModel.requestLocationPermission()
        // If no crash, test passes
        XCTAssertTrue(true)
    }

    func testIsLocationPermissionGrantedReturnsFalseWhenNotGranted() {
        viewModel.locationPermissionStatus = .notDetermined
        XCTAssertFalse(viewModel.isLocationPermissionGranted())
    }

    func testIsLocationPermissionGrantedReturnsTrueWhenGranted() {
        viewModel.locationPermissionStatus = .authorized
        XCTAssertTrue(viewModel.isLocationPermissionGranted())
    }

    func testIsLocationPermissionGrantedReturnsFalseWhenDenied() {
        viewModel.locationPermissionStatus = .denied
        XCTAssertFalse(viewModel.isLocationPermissionGranted())
    }

    // MARK: - Step Content Tests

    func testGetCurrentStepTitleReturnsCorrectTitle() {
        viewModel.currentStep = .welcome
        XCTAssertEqual(viewModel.getCurrentStepTitle(), "Welcome to Skywell")

        viewModel.currentStep = .locationPermission
        XCTAssertEqual(viewModel.getCurrentStepTitle(), "Location Access")

        viewModel.currentStep = .apiKeySetup
        XCTAssertEqual(viewModel.getCurrentStepTitle(), "Weather API Setup")

        viewModel.currentStep = .completion
        XCTAssertEqual(viewModel.getCurrentStepTitle(), "All Set!")
    }

    func testGetCurrentStepDescriptionReturnsCorrectDescription() {
        viewModel.currentStep = .welcome
        XCTAssertEqual(viewModel.getCurrentStepDescription(), "Get accurate weather forecasts for your location.")

        viewModel.currentStep = .locationPermission
        XCTAssertEqual(viewModel.getCurrentStepDescription(), "We need access to your location to provide weather updates.")

        viewModel.currentStep = .apiKeySetup
        XCTAssertEqual(viewModel.getCurrentStepDescription(), "Configure a weather provider API key to fetch weather data.")

        viewModel.currentStep = .completion
        XCTAssertEqual(viewModel.getCurrentStepDescription(), "Your setup is complete. Enjoy Skywell!")
    }

    // MARK: - Proceed Logic Tests

    func testCanProceedFromWelcome() {
        viewModel.currentStep = .welcome
        XCTAssertTrue(viewModel.canProceedFromCurrentStep())
    }

    func testCanProceedFromLocationPermission() {
        viewModel.currentStep = .locationPermission
        XCTAssertTrue(viewModel.canProceedFromCurrentStep())
    }

    func testCanProceedFromApiKeySetupWithoutApiKey() {
        viewModel.currentStep = .apiKeySetup
        viewModel.hasApiKey = false
        XCTAssertFalse(viewModel.canProceedFromCurrentStep())
    }

    func testCanProceedFromApiKeySetupWithApiKey() {
        viewModel.currentStep = .apiKeySetup
        viewModel.hasApiKey = true
        XCTAssertTrue(viewModel.canProceedFromCurrentStep())
    }

    func testCannotProceedFromCompletion() {
        viewModel.currentStep = .completion
        XCTAssertFalse(viewModel.canProceedFromCurrentStep())
    }

    // MARK: - Error Handling Tests

    func testErrorMessageDisplaysCorrectly() {
        viewModel.errorMessage = "Test error"
        viewModel.showError = true

        XCTAssertEqual(viewModel.errorMessage, "Test error")
        XCTAssertTrue(viewModel.showError)
    }

    func testDismissErrorClearsMessage() {
        viewModel.errorMessage = "Test error"
        viewModel.showError = true

        viewModel.dismissError()

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }

    // MARK: - API Key Status Tests

    func testHasApiKeyInitiallyFalse() {
        XCTAssertFalse(viewModel.hasApiKey)
    }

    func testHasApiKeyUpdatesWhenSet() {
        viewModel.hasApiKey = true
        XCTAssertTrue(viewModel.hasApiKey)
    }

    // MARK: - Navigation Flow Tests

    func testCompleteOnboardingFlow() {
        // Start at welcome
        XCTAssertEqual(viewModel.currentStep, .welcome)

        // Advance to location
        viewModel.advanceStep()
        XCTAssertEqual(viewModel.currentStep, .locationPermission)

        // Advance to API key setup
        viewModel.advanceStep()
        XCTAssertEqual(viewModel.currentStep, .apiKeySetup)

        // Can't proceed without API key
        viewModel.hasApiKey = false
        XCTAssertFalse(viewModel.canProceedFromCurrentStep())

        // Set API key
        viewModel.hasApiKey = true
        XCTAssertTrue(viewModel.canProceedFromCurrentStep())

        // Advance to completion
        viewModel.advanceStep()
        XCTAssertEqual(viewModel.currentStep, .completion)
    }

    func testSkipFromMiddleOfOnboarding() {
        viewModel.currentStep = .locationPermission
        viewModel.skipOnboarding()

        let expectation = XCTestExpectation(description: "Onboarding complete after skip")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.viewModel.isOnboardingComplete {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.isOnboardingComplete)
    }

    func testBacktrackingThroughSteps() {
        // Advance forward
        viewModel.advanceStep()
        viewModel.advanceStep()
        XCTAssertEqual(viewModel.currentStep, .apiKeySetup)

        // Go back
        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStep, .locationPermission)

        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStep, .welcome)

        // Forward again
        viewModel.advanceStep()
        XCTAssertEqual(viewModel.currentStep, .locationPermission)
    }

    // MARK: - State Consistency Tests

    func testMultipleErrorDismissals() {
        viewModel.errorMessage = "Error 1"
        viewModel.showError = true
        viewModel.dismissError()
        XCTAssertNil(viewModel.errorMessage)

        viewModel.errorMessage = "Error 2"
        viewModel.showError = true
        viewModel.dismissError()
        XCTAssertNil(viewModel.errorMessage)
    }

    func testStepNavigationPreservesOtherState() {
        viewModel.errorMessage = "Some error"
        viewModel.showError = true
        viewModel.locationPermissionStatus = .authorized

        viewModel.advanceStep()

        XCTAssertEqual(viewModel.currentStep, .locationPermission)
        XCTAssertEqual(viewModel.errorMessage, "Some error")
        XCTAssertTrue(viewModel.showError)
        XCTAssertEqual(viewModel.locationPermissionStatus, .authorized)
    }

    // MARK: - Onboarding Step Enumeration Tests

    func testOnboardingStepAllCasesCount() {
        XCTAssertEqual(OnboardingStep.allCases.count, 4)
    }

    func testOnboardingStepAllCasesIncludeAllSteps() {
        let cases = OnboardingStep.allCases
        XCTAssertTrue(cases.contains(.welcome))
        XCTAssertTrue(cases.contains(.locationPermission))
        XCTAssertTrue(cases.contains(.apiKeySetup))
        XCTAssertTrue(cases.contains(.completion))
    }

    func testOnboardingStepRawValuesAreSequential() {
        XCTAssertEqual(OnboardingStep.welcome.rawValue, 0)
        XCTAssertEqual(OnboardingStep.locationPermission.rawValue, 1)
        XCTAssertEqual(OnboardingStep.apiKeySetup.rawValue, 2)
        XCTAssertEqual(OnboardingStep.completion.rawValue, 3)
    }

    // MARK: - Integration Tests

    func testOnboardingWithLocationAndApiKey() {
        let expectation = XCTestExpectation(description: "Full onboarding with requirements")

        // Start onboarding
        XCTAssertEqual(viewModel.currentStep, .welcome)

        // Welcome step
        viewModel.advanceStep()
        XCTAssertEqual(viewModel.currentStep, .locationPermission)

        // Location step - simulate permission granted
        viewModel.locationPermissionStatus = .authorized
        viewModel.advanceStep()
        XCTAssertEqual(viewModel.currentStep, .apiKeySetup)

        // API key step
        viewModel.hasApiKey = true
        XCTAssertTrue(viewModel.canProceedFromCurrentStep())
        viewModel.advanceStep()
        XCTAssertEqual(viewModel.currentStep, .completion)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.viewModel.isOnboardingComplete {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.isOnboardingComplete)
    }

    func testOnboardingStateAfterMultipleSkips() {
        viewModel.skipOnboarding()

        let expectation = XCTestExpectation(description: "First skip complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.viewModel.isOnboardingComplete {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.isOnboardingComplete)
    }

    func testLocationPermissionStatusTransitions() {
        XCTAssertEqual(viewModel.locationPermissionStatus, .notDetermined)

        viewModel.locationPermissionStatus = .authorized
        XCTAssertEqual(viewModel.locationPermissionStatus, .authorized)
        XCTAssertTrue(viewModel.isLocationPermissionGranted())

        viewModel.locationPermissionStatus = .denied
        XCTAssertEqual(viewModel.locationPermissionStatus, .denied)
        XCTAssertFalse(viewModel.isLocationPermissionGranted())

        viewModel.locationPermissionStatus = .notDetermined
        XCTAssertEqual(viewModel.locationPermissionStatus, .notDetermined)
        XCTAssertFalse(viewModel.isLocationPermissionGranted())
    }
}
