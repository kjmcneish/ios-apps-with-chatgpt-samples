//
//  Location.swift
//  TasteMap
//
//  Created by Kevin McNeish on 8/26/24.
//

import Foundation
import CoreLocation

protocol LocationDelegate: AnyObject {
    func didUpdateLocation(locationEntity: LocationEntity)
}

public struct LocationEntity {
    var street: String?
    var streetNumber: String?
    var city: String?
    var country: String?
    var postalCode: String?
    var latitude: Double?
    var longitude: Double?
    
    // Computed property to return full address (street and street number)
    var address: String {
        let numberPart = streetNumber ?? ""
        let streetPart = street ?? ""
        
        // Combine street number and street, if both exist
        if !numberPart.isEmpty && !streetPart.isEmpty {
            return "\(numberPart) \(streetPart)"
        }
        // Return whichever part is available (or empty string)
        return streetPart.isEmpty ? numberPart : streetPart
    }
}

public class Location: NSObject, CLLocationManagerDelegate {
    
    static let shared = Location()
	
	private let locationManager = CLLocationManager()
    public private(set) var locationEntity: LocationEntity?
    
    private var locationUpdateHandler: ((LocationEntity?, Error?) -> Void)?
    public var isUpdatingLocation = false
	
    var currentLocation: CLLocation? // Store the current location
	weak var delegate: LocationDelegate?
	
	private override init() {
		super.init()
		locationManager.delegate = self
        // Adjust accuracy and distance filter
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 50 // Only update if the device moves 50 meters
	}
    
    // Start updating location with a completion handler
    public func startUpdatingLocation(completion: @escaping (LocationEntity?, Error?) -> Void) {
        guard !isUpdatingLocation else { return }
        isUpdatingLocation = true
        locationUpdateHandler = completion
        checkAuthorizationStatus()
    }
    
    // Stop updating location
    public func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        isUpdatingLocation = false
    }
	
    // Check authorization status and request permission if necessary
    private func checkAuthorizationStatus() {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            locationUpdateHandler?(nil, NSError(domain: "LocationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Location access denied"]))
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
    
	public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		
		guard let location = locations.last else { return }
		self.currentLocation = location
		
        // Reverse geocode the location to get more details
		let geocoder = CLGeocoder()
		geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
			if let error = error {
                self?.locationUpdateHandler?(nil, error)
				return
			}

			if let placemark = placemarks?.first {
                let locationEntity = LocationEntity(
                    street: placemark.thoroughfare,
                    streetNumber: placemark.subThoroughfare,
                    city: placemark.locality,
                    country: placemark.country,
                    postalCode: placemark.postalCode,
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                
                // Persist the location entity for future access
                self?.locationEntity = locationEntity
                
                // Call the closure-based completion handler
                self?.locationUpdateHandler?(locationEntity, nil)
                
                // Notify the delegate of the updated location
                self?.delegate?.didUpdateLocation(locationEntity: locationEntity)
			}
		}
	}
    
    // CLLocationManagerDelegate method - handle authorization changes
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            locationUpdateHandler?(nil, NSError(domain: "LocationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Location access denied"]))
        default:
            break
        }
    }
    
    // CLLocationManagerDelegate method - handle errors
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationUpdateHandler?(nil, error)
    }
    
    // Return distance in Double
    public func distanceFromCurrentLocation(to latitude: Double, longitude: Double) -> Double? {
        guard let currentLocation = currentLocation else {
            print("Current location is not available")
            return nil
        }
        
        let destinationLocation = CLLocation(latitude: latitude, longitude: longitude)
        let distanceInMeters = currentLocation.distance(from: destinationLocation)
        
        return distanceInMeters
    }
	
	public func distanceFromCurrentLocation(to latitude: Double, longitude: Double) -> String? {
		guard let currentLocation = currentLocation else {
			print("Current location is not available")
			return nil
		}
		
		let destinationLocation = CLLocation(latitude: latitude, longitude: longitude)
		let distanceInMeters = currentLocation.distance(from: destinationLocation)
		
		// Determine the user's preferred measurement system
		let measurementSystem = Locale.current.measurementSystem
		
		let distanceString: String
		
		switch measurementSystem {
		case .metric:
			// Convert meters to kilometers if distance is greater than or equal to 100 meters (0.1 km)
			let distanceInKilometers = distanceInMeters / 1000
			if distanceInKilometers >= 0.1 {
				distanceString = String(format: "%.2f km", distanceInKilometers)
			} else {
				distanceString = String(format: "%.0f meters", distanceInMeters)
			}
		case .us, .uk:
			// Convert meters to miles
			let distanceInMiles = distanceInMeters / 1609.344
			if distanceInMiles >= 0.1 {
				distanceString = String(format: "%.2f miles", distanceInMiles)
			} else {
				let distanceInFeet = distanceInMiles * 5280
				distanceString = String(format: "%.0f feet", distanceInFeet)
			}
		default:
			// Fallback to metric as a safe default
			let distanceInKilometers = distanceInMeters / 1000
			if distanceInKilometers >= 0.1 {
				distanceString = String(format: "%.2f km", distanceInKilometers)
			} else {
				distanceString = String(format: "%.0f meters", distanceInMeters)
			}
		}
		
		return distanceString
	}


}
