//
//  RestaurantCollectionViewController.swift
//  TasteMap
//
//  Created by Kevin McNeish on 9/14/24.
//

import UIKit

class RestaurantCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, RestaurantEditDelegate {
    
    var restaurants = [RestaurantEntity]()
    var isEditingMode = false
    var traitChangesObserver: NSObjectProtocol?
    
    @IBOutlet weak var btnLocation: UIButton!
    @IBOutlet weak var restaurantCollectionView: UICollectionView!
    @IBOutlet weak var btnAdd: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add observers for app background and foreground events
       NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
       NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        restaurantCollectionView.dataSource = self
        restaurantCollectionView.delegate = self
        
        // Register for trait changes
        traitChangesObserver = traitCollection.observe(\.verticalSizeClass, options: [.new]) { [weak self] _, change in
            guard let self = self else { return }
            self.restaurantCollectionView.collectionViewLayout.invalidateLayout()
        }
        self.restaurants = Restaurant.shared.getAllEntities()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        // Unregister trait change observer
        if let observer = traitChangesObserver {
            NotificationCenter.default.removeObserver(observer)
        }
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
            self.restaurantCollectionView.reloadData()
        }
    }
    
    // Stop updating location, but only if it's currently active
    func stopUpdatingLocation() {
        guard Location.shared.isUpdatingLocation else { return }  // Check the Location object's isUpdatingLocation flag
        
        Location.shared.stopUpdatingLocation()
    }
    
    @IBAction func editButtonTapped(_ sender: Any) {
        // Toggle edit mode
        self.isEditingMode.toggle()

        // Reload collection to show/hide delete buttons
        self.restaurantCollectionView.reloadData()
    }
    
    @objc func deleteButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        let restaurantToDelete = restaurants[index]
        
        // Remove the restaurant entity from the list
        restaurants.remove(at: index)
        
        // Delete the entity from the data source
        let result = Restaurant.shared.deleteEntityAndSave(restaurantToDelete)
        
        if result.state == .saveComplete {
            restaurantCollectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
        }
        else
        {
            // Handle save errors
            let alert = UIAlertController(title: "Delete Error", message: "Failed to delete the restaurant. Please try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddRestaurantSegue", let editVC = segue.destination as? RestaurantEditTableViewController {
            editVC.delegate = self
            editVC.isNewRestaurant = true
        }
        else if segue.identifier == "EditRestaurantSegue", let editVC = segue.destination as? RestaurantEditTableViewController, let selectedRestaurant = sender as? RestaurantEntity {
            // Pass the selected RestaurantEntity to the edit view controller
            editVC.restaurantEntity = selectedRestaurant
            editVC.delegate = self
            editVC.isNewRestaurant = false
        }
    }
    
    @objc func cellTapped(_ sender: UITapGestureRecognizer) {
        
        if self.isEditingMode {
            return // Prevent navigation when in edit mode
        }
        
        if let tappedCell = sender.view as? UICollectionViewCell,
           let indexPath = restaurantCollectionView.indexPath(for: tappedCell) {
            let selectedRestaurant = restaurants[indexPath.row]
            // Perform the segue to RestaurantEditTableViewController
            performSegue(withIdentifier: "EditRestaurantSegue", sender: selectedRestaurant)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // Get the selected restaurant entity
        let selectedRestaurant = restaurants[indexPath.row]
        
        // Trigger the segue and pass the selected restaurant entity
        performSegue(withIdentifier: "EditRestaurantSegue", sender: selectedRestaurant)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.restaurants.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "RestaurantCell",
            for: indexPath) as! RestaurantCell
                    
        // Configure the cell
        let restaurantEntity = restaurants[indexPath.row]
        
        // Add a tap gesture recognizer to the cell
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped(_:)))
        cell.addGestureRecognizer(tapGesture)
        
        // Get the distance from the current location
        var distanceText: String? = nil
        if let latitude = restaurantEntity.latitude,
            let longitude = restaurantEntity.longitude {
            distanceText = Location.shared.distanceFromCurrentLocation(to: latitude, longitude: longitude)
        }
        
        // Set cuisine and distance information
        let cuisineText = restaurantEntity.cuisine?.name
        let combinedText = [cuisineText, distanceText].compactMap { $0 }.joined(separator: " - ")
        cell.lblCuisine.text = combinedText
        
        cell.lblName.text = restaurantEntity.name
        cell.lblAddress.text = restaurantEntity.fullAddress
        cell.lblNeighborhood.text = restaurantEntity.neighborhood
        
        let (statusText, isOpen) = Restaurant.shared.getOperatingHoursText(hours: restaurantEntity.hours)
                    
        // Get the operating hours text
        let attributedString = NSMutableAttributedString(string: statusText, attributes: [.foregroundColor: UIColor.label])
        
        // Apply color to the first word based on whether the restaurant is open or closed
        if let isOpen = isOpen {
            let firstWordRange = (statusText as NSString).range(of: statusText.components(separatedBy: " ")[0])
            let darkerGreenColor = UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0) // Darker green
            let statusColor: UIColor = isOpen ? darkerGreenColor : UIColor.red
            attributedString.addAttribute(.foregroundColor, value: statusColor, range: firstWordRange)
        }
        
        // Set the attributed string to the label
        cell.lblHours.attributedText = attributedString
        
        // Add delete button only if in editing mode
        if isEditingMode {
            let deleteButton = UIButton(type: .system)
            deleteButton.setTitle("Delete", for: .normal)
            deleteButton.setTitleColor(.red, for: .normal)
            deleteButton.frame = CGRect(x: cell.bounds.width - 80, y: cell.bounds.height - 40, width: 70, height: 30)
            deleteButton.tag = indexPath.row
            deleteButton.addTarget(self, action: #selector(deleteButtonTapped(_:)), for: .touchUpInside)
            cell.addSubview(deleteButton)
        }
        else {
            // Remove existing delete buttons
            for subview in cell.subviews where subview is UIButton {
                subview.removeFromSuperview()
            }
        }
        
        // Fetch the photos from the restaurant and its related meals
        var photos = [Data]()
        
        // Add the restaurant photo if available
        if let restaurantPhoto = restaurantEntity.photo {
            photos.append(restaurantPhoto)
        }
        
        // Add photos from related meals
        let meals = Meal.shared.getMeals(for: restaurantEntity)
        for meal in meals {
            if let mealPhoto = meal.photo {
                photos.append(mealPhoto)
            }
        }
        
        // Pass the photos to the cell's internal collection view
        cell.photos = photos
        cell.photoCollectionView.reloadData() // Reload the internal collection view
                    
        return cell
    }
    
    // UICollectionViewDelegateFlowLayout method
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width // Full width of the collection view
        let height: CGFloat = 310.0 // Fixed height for your cell
        
        return CGSize(width: width, height: height)
    }

    // Handle layout invalidation on orientation changes (viewWillTransition)
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Invalidate layout on orientation change
        coordinator.animate(alongsideTransition: { context in
            self.restaurantCollectionView.collectionViewLayout.invalidateLayout()
        }, completion: nil)
    }

    func didAddNewRestaurant(_ restaurant: RestaurantEntity) {
        if let index = self.restaurants.firstIndex(where: { $0.id == restaurant.id }) {
            // Update the existing restaurant
            self.restaurants[index] = restaurant
        }
        else {
            // Add new meal
            self.restaurants.append(restaurant)
        }
        self.restaurantCollectionView.reloadData()
    }
}

