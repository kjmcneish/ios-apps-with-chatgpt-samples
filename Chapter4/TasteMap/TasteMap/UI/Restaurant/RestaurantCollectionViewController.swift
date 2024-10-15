//
//  RestaurantCollectionViewController.swift
//  TasteMap
//
//  Created by Kevin McNeish on 9/14/24.
//

import UIKit

class RestaurantCollectionViewController: UIViewController {
    @IBOutlet weak var btnLocation: UIButton!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add observers for app background and foreground events
       NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
       NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.startUpdatingLocation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.stopUpdatingLocation() // Stop updates when the view disappears
    }
    
    @objc func appDidEnterBackground() {
        self.stopUpdatingLocation()  // Stop  updates when the app enters the background
    }

    @objc func appDidBecomeActive() {
        self.startUpdatingLocation()
    }
    
    // Start updating location, but only if it's not already active
    func startUpdatingLocation() {
        guard !Location.shared.isUpdatingLocation else { return }  // Check the Location object's isUpdatingLocation flag
        
        Location.shared.startUpdatingLocation { location, error in
            if let location = location, let city = location.city, let country = location.country {
                self.btnLocation.setTitle("\(city), \(country)", for: .normal)
            } else {
                // Handle the case where city or country is not available
                self.btnLocation.setTitle("Location not available", for: .normal)
            }
        }
    }
    
    // Stop updating location, but only if it's currently active
    func stopUpdatingLocation() {
        guard Location.shared.isUpdatingLocation else { return }  // Check the Location object's isUpdatingLocation flag
        
        Location.shared.stopUpdatingLocation()
    }
}

