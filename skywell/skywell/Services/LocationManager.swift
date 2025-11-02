//
//  LocationManager.swift
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
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var city: String? = nil
    @Published var latitude: Double? = nil
    @Published var longitude: Double? = nil
    @Published var locationError: String? = nil
    @Published var permissionDenied: Bool = false
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        checkAuthorization()
    }

    func requestLocation() {
        checkAuthorization()
        locationManager.requestLocation()
    }

    private func checkAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            permissionDenied = true
            locationError = "Location permission denied. Please enable location access in settings."
        case .authorizedAlways, .authorizedWhenInUse:
            permissionDenied = false
        @unknown default:
            permissionDenied = true
            locationError = "Unknown location authorization status."
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }

        // Update coordinates
        DispatchQueue.main.async {
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
        }

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.locationError = "Failed to get city: \(error.localizedDescription)"
                }
                return
            }
            if let city = placemarks?.first?.locality {
                DispatchQueue.main.async {
                    self?.city = city
                }
            } else {
                DispatchQueue.main.async {
                    self?.locationError = "City not found."
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = "Location error: \(error.localizedDescription)"
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkAuthorization()
        if !permissionDenied {
            locationManager.requestLocation()
        }
    }
}
