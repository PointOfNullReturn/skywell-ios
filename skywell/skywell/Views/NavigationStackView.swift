//
//  NavigationStackView.swift
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

struct NavigationStackView: View {
    @State private var showingSettings = false
    var body: some View {
        NavigationStack {
            Text("Hello, World!")
                .navigationTitle("Demo Navigation")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gearshape")
                                .imageScale(.large)
                                .accessibilityLabel("Settings")
                        }
                    }
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
        }
    }
}

#Preview {
    NavigationStackView()
}
