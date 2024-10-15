//
//  MealEditTableViewController.swift
//  TasteMap
//
//  Created by Kevin McNeish on 9/9/24.
//

import UIKit

protocol MealEditDelegate: AnyObject {
    func didAddNewMeal(_ meal: MealEntity)
}

class MealEditTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var restaurantEntity: RestaurantEntity? // restaurantEntity reference
    var mealEntity: MealEntity!
    var isNewMeal = true
    weak var delegate: MealEditDelegate?

    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnDone: UIButton!
    @IBOutlet weak var imgMeal: UIImageView!
    @IBOutlet weak var txtMealName: UITextField!
    @IBOutlet weak var tvwComments: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable the Done button initially
        self.btnDone.isEnabled = false
        
        if self.isNewMeal {
            self.mealEntity = MealEntity(restaurant: restaurantEntity)
        }
        else {
            self.title = mealEntity.name
            populateUIFromEntity()
        }
    }
    
    // MARK: - UI Population
    func populateUIFromEntity() {
        btnCancel.isHidden = true
        btnDone.isHidden = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneTapped))
        
        if let imageData = mealEntity.photo {
            imgMeal.image = UIImage(data: imageData)
        }
        btnDone.isEnabled = true
        txtMealName.text = mealEntity.name
        tvwComments.text = mealEntity.comment
        datePicker.date = mealEntity.dateTime
    }
    
    @IBAction func textFieldDidChange(_ textField: UITextField) {
        // Enable Done button if name isn’t empty
        if let name = textField.text, !name.isEmpty {
            btnDone.isEnabled = true
        }
        else {
            btnDone.isEnabled = false
        }
    }

    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneTapped(_ sender: Any) {
        
        // Save the meal using the Meal business object
        self.mealEntity.name = txtMealName.text!
        self.mealEntity.comment = tvwComments.text
        self.mealEntity.dateTime = datePicker.date

        let result = Meal.shared.insertEntity(self.mealEntity)
        
        if result.state == .saveComplete {
            self.delegate?.didAddNewMeal(mealEntity)
        }

        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: true)
        }
        else {
            dismiss(animated: true, completion: nil)
        }
    }

    
    @IBAction func addPhoto(_ sender: Any) {
        let alertController = UIAlertController(title: "Add Photo", message: "Choose a photo source", preferredStyle: .actionSheet)
                
        // Check if the camera is available
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
                self.presentImagePicker(sourceType: .camera)
            }
            alertController.addAction(cameraAction)
        }
        
        // Option to select from the photo library
        let libraryAction = UIAlertAction(title: "Photo Library", style: .default) { _ in
            self.presentImagePicker(sourceType: .photoLibrary)
        }
        alertController.addAction(libraryAction)
        
        // Cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            imgMeal.image = editedImage
            self.mealEntity?.photo = editedImage.jpegData(compressionQuality: 0.8)
        } else if let originalImage = info[.originalImage] as? UIImage {
            imgMeal.image = originalImage
            self.mealEntity?.photo = originalImage.jpegData(compressionQuality: 0.8)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 && indexPath.row == 0 {
            return 100 // Set height for the first row in the second section
        }
        return super.tableView(tableView, heightForRowAt: indexPath) // Use default height for other rows
    }
}
