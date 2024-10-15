//
//  MealCollectionViewController.swift
//  TasteMap
//
//  Created by Kevin McNeish on 9/10/24.
//

import UIKit

private let reuseIdentifier = "MealCell"

class MealCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, MealEditDelegate {
    
    var restaurantEntity: RestaurantEntity?
    var meals = [MealEntity]()
    var isEditingMode = false
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    // Placeholder view for when there are no meals
    let noMealsLabel: UILabel = {
        let label = UILabel()
        label.text = "No meals available"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = restaurantEntity?.name
        
        // Setup the placeholder label
        self.view.addSubview(noMealsLabel)
        NSLayoutConstraint.activate([
            noMealsLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            noMealsLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
        
        self.loadMealsForRestaurant()
    }
    
    @IBAction func editButtonTapped(_ sender: Any) {
       // Toggle edit mode
       self.isEditingMode.toggle()

       // Reload collection to show/hide delete buttons
        self.collectionView.reloadData()
    }
    
    @objc func deleteButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        let mealToDelete = meals[index]
        
        // Remove the restaurant entity from the list
        meals.remove(at: index)
        
        // Delete the entity from the data source
        let result = Meal.shared.deleteEntityAndSave(mealToDelete)
        
        if result.state == .saveComplete {
            collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
            // Show/hide the placeholder view
            noMealsLabel.isHidden = !meals.isEmpty
        }
        else
        {
            // Handle save errors
            let alert = UIAlertController(title: "Delete Error", message: "Failed to delete the meal. Please try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    func loadMealsForRestaurant() {
        guard let restaurant = restaurantEntity else {
            print("Error: No restaurant entity found.")
            return
        }
        
        // Fetch meals associated with the restaurant using the business object
        meals = Meal.shared.getMeals(for: restaurant)
        
        // Reload the collection view to display the fetched meals
        collectionView.reloadData()
        
        // Show/hide the placeholder view
        noMealsLabel.isHidden = !meals.isEmpty
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Check if the segue identifier matches the AddMealSegue
        if segue.identifier == "AddMealSegue" {
            // Get the destination view controller
            if let mealEditVC = segue.destination as? MealEditTableViewController {
                // Pass the restaurant entity to the MealEditTableViewController
                mealEditVC.restaurantEntity = self.restaurantEntity
                mealEditVC.delegate = self
            }
        }
        else if segue.identifier == "EditMealSegue", let editVC = segue.destination as? MealEditTableViewController, let selectedMeal = sender as? MealEntity {
            // Pass the selected MealEntity to the edit view controller
            editVC.mealEntity = selectedMeal
            editVC.delegate = self
            editVC.isNewMeal = false
        }
    }

    // MARK: UICollectionViewDataSource
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // Get the selected restaurant entity
        let selectedMeal = meals[indexPath.row]
        
        // Trigger the segue and pass the selected restaurant entity
        performSegue(withIdentifier: "EditMealSegue", sender: selectedMeal)
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return meals.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? MealCell else {
            return UICollectionViewCell()
        }
                
        let meal = meals[indexPath.item]
        
        // Set the meal name
        cell.lblMealName.text = meal.name
        
        // Use the pre-configured dateFormatter
        cell.lblDate.text = dateFormatter.string(from: meal.dateTime)
        
        // Set the meal image if available
        if let mealPhoto = meal.photo {
            cell.imgMeal.image = UIImage(data: mealPhoto)
        }
        else {
            cell.imgMeal.image = UIImage(named: "DefaultMeal")
        }
        
        // Set the description or comments
        cell.lblComments.text = meal.comment ?? "No description available"
        
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
        
        return cell
    }

    // UICollectionViewDelegateFlowLayout method
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Full width of the collection view
        let width = collectionView.bounds.width
        let height: CGFloat = 180.0 // Fixed height
        
        return CGSize(width: width, height: height)
    }

    func didAddNewMeal(_ meal: MealEntity) {
        if let index = self.meals.firstIndex(where: { $0.id == meal.id }) {
            // Update the existing meal
            self.meals[index] = meal
        }
        else {
            // Add new meal
            self.meals.append(meal)
        }
        self.collectionView.reloadData()
        noMealsLabel.isHidden = !meals.isEmpty
    }
}
