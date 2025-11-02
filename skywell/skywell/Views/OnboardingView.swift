//
//  OnboardingView.swift
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

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var credentials: [WeatherProviderCredential]

    @StateObject private var viewModel: OnboardingViewModel
    @State private var showAddProvider = false

    init() {
        let locationManager = LocationManager()
        let preferencesManager = UserPreferencesManager(modelContext: ModelContext(try! ModelContainer(for: UserPreferences.self)))

        _viewModel = StateObject(wrappedValue: OnboardingViewModel(
            locationManager: locationManager,
            preferencesManager: preferencesManager
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                // Step Content
                stepContent
                    .transition(.opacity)

                Spacer()

                // Navigation Buttons
                navigationButtons
            }
            .padding()
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $viewModel.showAddProvider) {
            AddProviderSheet(isPresented: $viewModel.showAddProvider, onAdd: handleAddProvider)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .onChange(of: viewModel.isOnboardingComplete) { complete, _ in
            if complete {
                // Onboarding is complete, view will be replaced by ContentView
            }
        }
    }

    @ViewBuilder
    var stepContent: some View {
        switch viewModel.currentStep {
        case .welcome:
            welcomeStep

        case .locationPermission:
            locationStep

        case .apiKeySetup:
            apiKeyStep

        case .completion:
            completionStep
        }
    }

    var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue)

            Text(viewModel.getCurrentStepTitle())
                .font(.title)
                .fontWeight(.bold)

            Text(viewModel.getCurrentStepDescription())
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }

    var locationStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text(viewModel.getCurrentStepTitle())
                .font(.title)
                .fontWeight(.bold)

            Text(viewModel.getCurrentStepDescription())
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            if viewModel.isLocationPermissionGranted() {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Location access granted")
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else {
                Button(action: {
                    viewModel.requestLocationPermission()
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Request Location Access")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
    }

    var apiKeyStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "key.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)

            Text(viewModel.getCurrentStepTitle())
                .font(.title)
                .fontWeight(.bold)

            Text(viewModel.getCurrentStepDescription())
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            if credentials.isEmpty {
                Button(action: { viewModel.showAddProvider = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Weather Provider")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(credentials, id: \.id) { credential in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(credential.providerName)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }

    var completionStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text(viewModel.getCurrentStepTitle())
                .font(.title)
                .fontWeight(.bold)

            Text(viewModel.getCurrentStepDescription())
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }

    var navigationButtons: some View {
        HStack(spacing: 12) {
            if viewModel.currentStep != .welcome {
                Button(action: { viewModel.previousStep() }) {
                    Text("Back")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
            }

            if viewModel.currentStep != .completion {
                Button(action: { viewModel.advanceStep() }) {
                    Text(viewModel.currentStep == .apiKeySetup ? "Complete" : "Next")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.canProceedFromCurrentStep() ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!viewModel.canProceedFromCurrentStep())
            } else {
                Button(action: { viewModel.skipOnboarding() }) {
                    Text("Finish")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }

            if viewModel.currentStep != .completion {
                Button(action: { viewModel.skipOnboarding() }) {
                    Text("Skip")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
            }
        }
    }

    private func handleAddProvider(name: String, apiKey: String) {
        let credential = WeatherProviderCredential(providerName: name, keychainKey: UUID().uuidString)

        do {
            try KeychainManager.shared.save(apiKey, for: credential.keychainKey)
            modelContext.insert(credential)

            // Update viewModel's API key status
            viewModel.hasApiKey = true
        } catch {
            viewModel.errorMessage = "Failed to save provider: \(error.localizedDescription)"
            viewModel.showError = true
        }
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: WeatherProviderCredential.self, inMemory: true)
}
