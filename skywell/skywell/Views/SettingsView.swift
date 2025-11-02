//
//  SettingsView.swift
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

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var credentials: [WeatherProviderCredential]

    @StateObject private var viewModel = SettingsViewModel()
    @State private var hasConfiguredViewModel = false

    var body: some View {
        NavigationStack {
            Form {
                // Active Provider Section
                Section(header: Text("Active Weather Provider")) {
                    if credentials.isEmpty {
                        Text("No providers configured")
                            .foregroundColor(.gray)
                    } else {
                        Picker("Provider", selection: Binding(
                            get: { viewModel.currentPreferences.activeProviderId ?? "" },
                            set: { newValue in
                                viewModel.updateActiveProvider(newValue)
                            }
                        )) {
                            ForEach(credentials, id: \.id) { credential in
                                Text(credential.providerName)
                                    .tag(credential.id)
                            }
                        }
                    }
                }

                // Unit Preference Section
                Section(header: Text("Temperature Units")) {
                    Picker("Units", selection: Binding(
                        get: { viewModel.currentPreferences.unitPreference },
                        set: { newValue in
                            viewModel.updateUnitPreference(newValue)
                        }
                    )) {
                        Text("Metric (°C)").tag(UnitPreference.metric)
                        Text("Imperial (°F)").tag(UnitPreference.imperial)
                    }
                }

                // Color Scheme Section
                Section(header: Text("Appearance")) {
                    Picker("Color Scheme", selection: Binding(
                        get: { viewModel.currentPreferences.colorScheme },
                        set: { newValue in
                            viewModel.updateColorScheme(newValue)
                        }
                    )) {
                        Text("Light").tag(ColorScheme.light)
                        Text("Dark").tag(ColorScheme.dark)
                        Text("System Default").tag(ColorScheme.system)
                    }
                }

                // Configured Providers Section
                Section(header: Text("Configured Providers")) {
                    if credentials.isEmpty {
                        Text("No providers added yet")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(credentials, id: \.id) { credential in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(credential.providerName)
                                        .font(.headline)
                                    Text("Added: \(credential.createdDate.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Button(action: { viewModel.deleteProvider(credential) }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }

                // Add Provider Section
                Section {
                    Button(action: { viewModel.showAddProvider = true }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Weather Provider")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $viewModel.showAddProvider) {
            AddProviderSheet(isPresented: $viewModel.showAddProvider, onAdd: viewModel.addProvider)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .onAppear {
            configureViewModelIfNeeded()
        }
    }

    private func configureViewModelIfNeeded() {
        if hasConfiguredViewModel {
            viewModel.refreshPreferences()
            return
        }

        let preferencesManager = UserPreferencesManager(modelContext: modelContext)
        viewModel.configure(preferencesManager: preferencesManager, modelContext: modelContext)
        hasConfiguredViewModel = true
    }

}

struct AddProviderSheet: View {
    @Binding var isPresented: Bool
    let onAdd: (String, String) -> Void

    @State private var selectedProvider = "openweatherapi"
    @State private var apiKey = ""

    let availableProviders = [
        ("openweatherapi", "OpenWeatherMap")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Provider")) {
                    Picker("Select Provider", selection: $selectedProvider) {
                        ForEach(availableProviders, id: \.0) { id, name in
                            Text(name).tag(id)
                        }
                    }
                }

                Section(header: Text("API Key")) {
                    SecureField("Enter API Key", text: $apiKey)
                }

                Section {
                    Button(action: submitForm) {
                        HStack {
                            Spacer()
                            Text("Add Provider")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(apiKey.isEmpty)
                }
            }
            .navigationTitle("Add Weather Provider")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func submitForm() {
        let providerName = availableProviders.first(where: { $0.0 == selectedProvider })?.1 ?? selectedProvider
        onAdd(providerName, apiKey)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [WeatherProviderCredential.self, UserPreferences.self], inMemory: true)
}
