# Skywell iOS

A modern iOS weather application with OpenWeatherMap integration and customizable user preferences including dark mode support and unit selection.

## Features

- **Weather Provider Integration**: OpenWeatherMap adapter with extensible architecture for additional providers
- **Dark Mode Support**: Choose between light, dark, or system default appearance
- **Unit Preferences**: Switch between metric (°C) and imperial (°F) temperature units
- **Location-Based Weather**: Automatic location detection and weather updates
- **Provider Management**: Add and manage weather provider credentials
- **Persistent Preferences**: All user settings are stored locally using SwiftData
- **Comprehensive Testing**: Full test coverage with unit, integration, and UI tests

## Requirements

- iOS 15.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

### Setup

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd skywell-ios
   ```

2. Generate the Xcode project:
   ```bash
   cd skywell
   xcodebuild -createWorkspace skywell.xcworkspace -addWorkspaceItem skywell.xcodeproj
   ```

   Or, open the project directly in Xcode:
   ```bash
   open skywell/skywell.xcodeproj
   ```
   Xcode will automatically generate necessary build artifacts on first open.

3. Configure your Apple Developer Team ID:
   - Open the project in Xcode
   - Select the "skywell" target
   - Go to Signing & Capabilities
   - Select your team in the Team dropdown
   - Xcode will automatically configure code signing

4. Build and run the project on a simulator or device

### Building from Command Line

```bash
# Build the project
xcodebuild build -scheme skywell -destination 'platform=iOS Simulator,name=iPhone 16'

# Run tests
xcodebuild test -scheme skywell -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Architecture

The app follows MVVM architecture with:

- **Models**: Data structures for weather, preferences, and credentials
- **ViewModels**: Business logic and state management
- **Views**: SwiftUI-based user interface
- **Services**: Weather API adapters, location services, and persistence
- **Utilities**: Helper functions for temperature conversion and data formatting

### Key Components

- **UserPreferencesManager**: Manages user settings (units, color scheme, active provider)
- **WeatherService**: Orchestrates weather data fetching from configured providers
- **KeychainManager**: Secure storage for API credentials
- **LocationManager**: Handles location permissions and updates

## Testing

The project includes comprehensive test coverage:

- **Unit Tests**: Test individual components in isolation
- **Integration Tests**: Test interactions between services
- **UI Tests**: Test user workflows and interface behavior

Run tests with:
```bash
xcodebuild test -scheme skywell -destination 'platform=iOS Simulator,name=iPhone 16'
```

## User Preferences

### Temperature Units
- Metric (Celsius)
- Imperial (Fahrenheit)

### Appearance
- Light Mode
- Dark Mode
- System Default (follows device settings)

### Weather Providers
- Add multiple provider credentials
- Switch between configured providers
- Provider-specific API keys stored securely

## License

This project is provided as-is without warranty.
