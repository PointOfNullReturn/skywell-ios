//
//  skywellApp.swift
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

@main
struct skywellApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WeatherProviderCredential.self,
            UserPreferences.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var colorScheme: SwiftUI.ColorScheme?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorScheme)
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ColorSchemeChanged"))) { _ in
                    updateColorScheme()
                }
                .onAppear {
                    updateColorScheme()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func updateColorScheme() {
        let preferencesManager = UserPreferencesManager(
            modelContext: ModelContext(sharedModelContainer)
        )
        let colorSchemePreference = preferencesManager.getColorScheme()

        colorScheme = switch colorSchemePreference {
        case .light:
            .light
        case .dark:
            .dark
        case .system:
            nil
        }
    }
}
