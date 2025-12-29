//
//  LocationService.swift
//  Physio_Connect
//
//  Created by user@8 on 30/12/25.
//

import Foundation
import CoreLocation

final class LocationService: NSObject, CLLocationManagerDelegate {

    static let shared = LocationService()
    private override init() { super.init() }

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    var lastLocation: CLLocation?
    var onLocationUpdate: ((String, CLLocation?) -> Void)?

    func requestLocation() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let loc = locations.last
        lastLocation = loc

        guard let loc else {
            onLocationUpdate?("Location unavailable", nil)
            return
        }

        geocoder.reverseGeocodeLocation(loc) { [weak self] placemarks, _ in
            let city = placemarks?.first?.locality ?? "Your location"
            self?.onLocationUpdate?(city, loc)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onLocationUpdate?("Location unavailable", nil)
    }
}
