import UIKit
import SwiftUI

protocol RestaurantEditDelegate: AnyObject {
    func didAddNewRestaurant(_ restaurant: RestaurantEntity)
}

class RestaurantEditTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    // MARK: - Properties
    var restaurantEntity = RestaurantEntity()
    var isNewRestaurant = true
    weak var delegate: RestaurantEditDelegate?
    
    let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    // MARK: - Outlets
    @IBOutlet weak var imgRestaurant: UIImageView!
    @IBOutlet var openButtons: [UIButton]!
    @IBOutlet var closeButtons: [UIButton]!
    @IBOutlet var swtDays: [UISwitch]!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnDone: UIButton!
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var lblCuisine: UILabel!
    @IBOutlet weak var txtPhone: UITextField!
    @IBOutlet weak var txtNeighborhood: UITextField!
    @IBOutlet weak var txtStreet: UITextField!
    @IBOutlet weak var txtPostalCode: UITextField!
    @IBOutlet weak var txtCity: UITextField!
    @IBOutlet weak var lblCountry: UILabel!
    @IBOutlet weak var txtLatitude: UITextField!
    @IBOutlet weak var txtLongitude: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var lastSelectedButton: UIButton?
    var pickerIsVisible = false

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    func setupView() {
        btnDone.isEnabled = false
        
        // Transform day switches
        swtDays.forEach { $0.transform = CGAffineTransform(scaleX: 0.75, y: 0.75) }
        
        // Populate restaurant details if it's not new
        if isNewRestaurant {
            ensureHoursArrayIsComplete()
        }
        else {
            self.title = restaurantEntity.name
            populateUIFromEntity()
        }
        
        setupMinusAccessoryView()
    }

    // MARK: - UI Population
    func populateUIFromEntity() {
        btnCancel.isHidden = true
        btnDone.isHidden = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneTapped))
        
        if let imageData = restaurantEntity.photo {
            imgRestaurant.image = UIImage(data: imageData)
        }
        btnDone.isEnabled = true
        txtName.text = restaurantEntity.name
        lblCuisine.text = restaurantEntity.cuisine?.name
        txtPhone.text = restaurantEntity.phone
        txtNeighborhood.text = restaurantEntity.neighborhood
        txtStreet.text = restaurantEntity.address
        txtPostalCode.text = restaurantEntity.postalCode
        txtCity.text = restaurantEntity.city
        lblCountry.text = restaurantEntity.country
        txtLatitude.text = "\(restaurantEntity.latitude ?? 0)"
        txtLongitude.text = "\(restaurantEntity.longitude ?? 0)"
        
        if restaurantEntity.hours == nil || restaurantEntity.hours?.count == 0 {
            // Hours haven't been specified for the restaurant yet
            self.ensureHoursArrayIsComplete()
        }
        else {
            populateOperatingHours()
        }
    }

    // MARK: - Operating Hours Population
    func populateOperatingHours() {
        for (index, switchControl) in swtDays.enumerated() {
            if let operatingHours = restaurantEntity.hours?.first(where: { $0.dayOfWeek == Int16(index + 1) }) {
                setupButton(openButton: openButtons[index], closeButton: closeButtons[index], operatingHours: operatingHours)
                switchControl.isOn = (operatingHours.openTime != nil || operatingHours.closingTime != nil)
            }
            else {
                switchControl.isOn = false
                setButtonsToClosed(openButton: openButtons[index], closeButton: closeButtons[index])
            }
        }
    }

    func setupButton(openButton: UIButton, closeButton: UIButton, operatingHours: OperatingHoursEntity) {
        if let openTime = operatingHours.openTime {
            openButton.setTitle(timeFormatter.string(from: openTime), for: .normal)
        }
        else {
            if openButton.isEnabled {
                openButton.setTitle("Opens", for: .normal)
            }
            else {
                openButton.setTitle("Closed", for: .normal)
            }
        }
        
        if let closeTime = operatingHours.closingTime {
            closeButton.setTitle(timeFormatter.string(from: closeTime), for: .normal)
        }
        else {
            if closeButton.isEnabled {
                closeButton.setTitle("Closes", for: .normal)
            }
            else {
                closeButton.setTitle("Closed", for: .normal)
            }
        }
    }

    func setButtonsToClosed(openButton: UIButton, closeButton: UIButton) {
        openButton.setTitle("Closed", for: .normal)
        closeButton.setTitle("Closed", for: .normal)
    }

    // MARK: - Minus Button Accessory for Latitude/Longitude
    func setupMinusAccessoryView() {
        txtLatitude.keyboardType = .decimalPad
        txtLongitude.keyboardType = .decimalPad
        let accessoryView = createMinusAccessoryView()
        txtLatitude.inputAccessoryView = accessoryView
        txtLongitude.inputAccessoryView = accessoryView
    }

    func createMinusAccessoryView() -> UIView {
        let accessoryView = UIToolbar()
        accessoryView.sizeToFit()
        
        let minusButton = UIBarButtonItem(title: "-", style: .plain, target: self, action: #selector(addMinusSign))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        accessoryView.items = [flexibleSpace, minusButton, flexibleSpace]
        return accessoryView
    }

    @objc func addMinusSign() {
        if let currentText = txtLatitude.isFirstResponder ? txtLatitude.text : txtLongitude.text {
            let updatedText = currentText.hasPrefix("-") ? String(currentText.dropFirst()) : "-" + currentText
            if txtLatitude.isFirstResponder {
                txtLatitude.text = updatedText
            }
            else if txtLongitude.isFirstResponder {
                txtLongitude.text = updatedText
            }
        }
    }
    
    // MARK: - Text Field Change Handling
    @IBAction func nameEditingChanged(_ sender: Any) {
        btnDone.isEnabled = !(txtName.text?.isEmpty ?? true)
    }
    
    // MARK: - Location Handling
    @IBAction func getCurrentLocation(_ sender: Any) {
        let location = Location.shared.locationEntity
        txtStreet.text = location?.address
        txtCity.text = location?.city
        txtPostalCode.text = location?.postalCode
        lblCountry.text = location?.country
        txtLatitude.text = String(format: "%.5f", location?.latitude ?? 0)
        txtLongitude.text = String(format: "%.5f", location?.longitude ?? 0)
    }

    // MARK: - Helper Methods
    func ensureHoursArrayIsComplete() {
        if restaurantEntity.hours == nil {
            restaurantEntity.hours = []
        }

        for dayIndex in 1...7 {
            if restaurantEntity.hours?.first(where: { $0.dayOfWeek == Int16(dayIndex) }) == nil {
                let newHours = OperatingHoursEntity(dayOfWeek: Int16(dayIndex), openTime: nil, closingTime: nil)
                restaurantEntity.hours?.append(newHours)
            }
        }
        restaurantEntity.hours?.sort(by: { $0.dayOfWeek ?? 0 < $1.dayOfWeek ?? 0 })
    }
    
    func updateOperatingHours() {
        for (index, switchControl) in swtDays.enumerated() {
            if let operatingHours = restaurantEntity.hours?.first(where: { $0.dayOfWeek == Int16(index + 1) }), switchControl.isOn {
                operatingHours.openTime = timeFormatter.date(from: openButtons[index].title(for: .normal) ?? "")
                operatingHours.closingTime = timeFormatter.date(from: closeButtons[index].title(for: .normal) ?? "")
            }
        }
    }
    
    // MARK: - Navigation
    func scrollToBottom() {
        let lastSectionIndex = tableView.numberOfSections - 1
        if lastSectionIndex >= 0 {
            let lastRowIndex = tableView.numberOfRows(inSection: lastSectionIndex) - 1
            if lastRowIndex >= 0 {
                let lastIndexPath = IndexPath(row: lastRowIndex, section: lastSectionIndex)
                tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: true)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 2 {
            // Present the CuisineSelectionView
            let cuisineSelectionView = CuisineSelectionView(
                cuisines: Cuisine.shared.getAllCuisines(),
                currentCuisine: restaurantEntity.cuisine,
                onCuisineSelected: { selectedCuisine in
                    self.lblCuisine.text = selectedCuisine.name
                    self.restaurantEntity.cuisine = selectedCuisine
                }
            )

            let hostingController = UIHostingController(rootView: cuisineSelectionView)
            present(hostingController, animated: true, completion: nil)

            // Deselect the row with animation after a slight delay
            tableView.deselectRow(at: indexPath, animated: true)
        }
        else if indexPath.section == 0 && indexPath.row == 7 {
            // Find the current selected country based on the stored country name or fallback to the first country
            let currentCountry: Locale.Region?

            if let countryName = restaurantEntity.country, !countryName.isEmpty {
                // If restaurantEntity.country is set, find the matching Locale.Region
                currentCountry = Locale.Region.isoRegions.first {
                    let localizedCountryName = Locale.current.localizedString(forRegionCode: $0.identifier)
                    return localizedCountryName == countryName
                }
            } else {
                // If restaurantEntity.country is not set, fallback to the first region
                currentCountry = Locale.Region.isoRegions.first
            }

            let countrySelectionView = CountrySelectionView(
                currentCountry: currentCountry, // Pass the Locale.Region of the current country
                onCountrySelected: { selectedCountryName in
                    // Update the label and entity with the selected country's name
                    self.lblCountry.text = selectedCountryName
                    self.restaurantEntity.country = selectedCountryName
                }
            )

            let hostingController = UIHostingController(rootView: countrySelectionView)
            present(hostingController, animated: true, completion: nil)

            // Deselect the row with animation after a slight delay
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Check if the segue is the MealsSegue
        if segue.identifier == "MealsSegue" {
            // Ensure the destination is the correct view controller
            if let mealsCollectionViewController = segue.destination as? MealCollectionViewController {
                // Pass the restaurant entity to the MealsViewController
                mealsCollectionViewController.restaurantEntity = self.restaurantEntity
            }
        }
    }

    // MARK: - Button Action Handling
    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneTapped(_ sender: UIButton) {
        // Validate and save restaurant entity
        restaurantEntity.name = txtName.text!
        restaurantEntity.dateTimeCreated = Date()
        restaurantEntity.phone = txtPhone.text
        restaurantEntity.neighborhood = txtNeighborhood.text
        restaurantEntity.address = txtStreet.text
        restaurantEntity.city = txtCity.text
        restaurantEntity.postalCode = txtPostalCode.text
        restaurantEntity.latitude = Double(txtLatitude.text ?? "0")
        restaurantEntity.longitude = Double(txtLongitude.text ?? "0")

        // Update operating hours based on switches and buttons
        updateOperatingHours()

        let result = Restaurant.shared.insertEntity(restaurantEntity)
        if result.state == .saveComplete {
            self.delegate?.didAddNewRestaurant(restaurantEntity)
        }

        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: true)
        }
        else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func selectPhotoTapped(_ sender: Any) {
        let actionSheet = UIAlertController(title: "Select Photo", message: "Choose a photo from your gallery or take a new one", preferredStyle: .actionSheet)

        // Option to take a photo
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        }))

        // Option to select from photo library
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
            self.openPhotoLibrary()
        }))

        // Cancel action
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        // Present the action sheet
        self.present(actionSheet, animated: true, completion: nil)
    }

    // Open photo library
    func openPhotoLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
        } else {
            print("Photo Library not available")
        }
    }

    // Open camera
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true, completion: nil)
        } else {
            print("Camera not available")
        }
    }

    // Handle the selected image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            imgRestaurant.image = selectedImage
            
            // Save the image as Data and store it in the restaurantEntity.photo property
            if let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
                restaurantEntity.photo = imageData
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }

    // Handle cancellation
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func daySwitchToggled(_ sender: UISwitch) {
        // Determine which switch was toggled using its index in the collection
        guard let switchIndex = swtDays.firstIndex(of: sender) else { return }
        
        // Access the corresponding "Open" and "Close" buttons using the same index
        let openButton = openButtons[switchIndex]
        let closeButton = closeButtons[switchIndex]
        
        // Check the state of the switch
        if sender.isOn {
            // Enable the buttons and restore their time text (if applicable)
            openButton.isEnabled = true
            closeButton.isEnabled = true

            // Safely unwrap the operating hours entity
            if let operatingHours = restaurantEntity.hours?.first(where: { $0.dayOfWeek == Int16(switchIndex + 1) }) {
                setupButton(openButton: openButton, closeButton: closeButton, operatingHours: operatingHours)
            }
        }
        else {
            // Disable the buttons and set their titles to "Closed"
            openButton.isEnabled = false
            closeButton.isEnabled = false
            setButtonsToClosed(openButton: openButton, closeButton: closeButton)
        }
    }

    @IBAction func timeButtonTapped(_ sender: UIButton) {
        // Dismiss the keyboard if it's open
        view.endEditing(true)
        
        // Step 1: Reset the color of the previous button
        lastSelectedButton?.tintColor = UIColor.label
        
        // Step 2: Check if the same button was tapped (and if so, hide the picker)
        if sender == lastSelectedButton {
            lastSelectedButton = nil  // Deselect the button
            pickerIsVisible = !pickerIsVisible
        }
        else {
            pickerIsVisible = true
            // Step 3: Update the newly selected button's color to accent color
            sender.tintColor = UIColor.accent
        }
        
        let selectedButtonTag = sender.tag
        let isOpenTime = selectedButtonTag % 2 != 0  // Odd tags are for open time, even for close time
        let selectedDayIndex = (selectedButtonTag - 1) / 2  // Day index, from 0 (Sunday) to 6 (Saturday)

        // Step 4: Fetch the previously stored open and close times separately
        var previousOpenTime: Date? = nil
        var previousCloseTime: Date? = nil

        // Fetch the time for the currently selected day (open or close)
        if let operatingHours = restaurantEntity.hours?.first(where: { $0.dayOfWeek == Int16(selectedDayIndex + 1) }) {
            if isOpenTime, let openTime = operatingHours.openTime {
                // Set picker to the open time if available
                datePicker.setDate(openTime, animated: true)
                previousOpenTime = openTime
            }
            else if !isOpenTime, let closeTime = operatingHours.closingTime {
                // Set picker to the close time if available
                datePicker.setDate(closeTime, animated: true)
                previousCloseTime = closeTime
            }
            else {
                // No time set for this button yet, fetch the last selected times for either open or close
                if let lastSelectedButtonTag = lastSelectedButton?.tag, lastSelectedButtonTag != sender.tag {
                    let lastDayIndex = (lastSelectedButtonTag - 1) / 2  // Day index for last selected button
                    if let lastOperatingHours = restaurantEntity.hours?.first(where: { $0.dayOfWeek == Int16(lastDayIndex + 1) }) {
                        previousOpenTime = lastOperatingHours.openTime
                        previousCloseTime = lastOperatingHours.closingTime
                    }
                }
                
                // Assign the previous open or close time based on the current button tapped
                if isOpenTime, let previousOpenTime = previousOpenTime {
                    // Set the date picker and button title to the previous open time
                    datePicker.setDate(previousOpenTime, animated: true)
                    sender.setTitle(timeFormatter.string(from: previousOpenTime), for: .normal)
                    
                    // Update the open time in the restaurantEntity for this day
                    if let operatingHours = restaurantEntity.hours?.first(where: { $0.dayOfWeek == Int16(selectedDayIndex + 1) }) {
                        operatingHours.openTime = previousOpenTime
                    }
                }
                else if !isOpenTime, let previousCloseTime = previousCloseTime {
                    // Set the date picker and button title to the previous close time
                    datePicker.setDate(previousCloseTime, animated: true)
                    sender.setTitle(timeFormatter.string(from: previousCloseTime), for: .normal)
                    
                    // Update the close time in the restaurantEntity for this day
                    if let operatingHours = restaurantEntity.hours?.first(where: { $0.dayOfWeek == Int16(selectedDayIndex + 1) }) {
                        operatingHours.closingTime = previousCloseTime
                    }
                }
                else {
                    // No previous time, leave the date picker unchanged
                    print("No previous time to set.")
                }
            }
        }

        lastSelectedButton = sender  // Update the reference to the new button
        
        tableView.beginUpdates()
        tableView.endUpdates()
        self.scrollToBottom()
    }
    
    @IBAction func timePickerValueChanged(_ sender: UIDatePicker) {

        // Ensure the last selected button is valid
        guard let selectedButtonTag = lastSelectedButton?.tag else { return }

        // Format the selected time as a string
        let formattedTime = timeFormatter.string(from: sender.date)

        // Update the title of the last selected button with the new formatted time
        lastSelectedButton?.setTitle(formattedTime, for: .normal)

        // Determine if the button is for open or close based on the tag number
        let isOpenTime = selectedButtonTag % 2 != 0  // Odd tags are for open time, even tags for close time
        let selectedDayIndex = (selectedButtonTag - 1) / 2  // Day index, from 0 (Sunday) to 6 (Saturday)

        // Update the corresponding OperatingHoursEntity in the restaurantEntity.hours array
        if let operatingHours = restaurantEntity.hours?.first(where: { $0.dayOfWeek == Int16(selectedDayIndex + 1) }) {
            if isOpenTime {
                operatingHours.openTime = sender.date  // Update open time
            } else {
                operatingHours.closingTime = sender.date  // Update close time
            }
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Assuming the DatePicker is in row 7 (after the Saturday row) in section 1
        if indexPath.section == 1 && indexPath.row == 7 {
            return pickerIsVisible ? 216 : 0  // Toggle between showing and hiding the picker
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
}
