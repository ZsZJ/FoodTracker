//
//  ViewController.swift
//  FoodTracker
//
//  Created by Joey Lim on 02/04/2019.
//  Copyright © 2019 Joey Lim. All rights reserved.
//

import UIKit
import os.log
import CoreLocation
import SwiftyJSON

class MealViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate {
    
    //MARK: Properties
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var photoImageView: UIImageView! 
    @IBOutlet weak var ratingControl: RatingControl!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var ingredientsLabel: UILabel!
    @IBOutlet weak var recipeField: UITextView!
    
    
    /*
     This value is either passed by `MealTableViewController` in `prepare(for:sender)`
     or constructed as a part of adding a new meal
    */
    var meal: Meal?
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Handle the text field's user input through delegate callbacks.
        nameTextField.delegate = self
        
        // Check settings for dark theme key
        if UserDefaults.standard.bool(forKey: SettingsBundleHelper.SettingsBundleKeys.DarkTheme) {
            self.view.backgroundColor = UIColor.gray
            locationLabel.textColor = UIColor.white
        }
        else {
            self.view.backgroundColor = UIColor.white
            locationLabel.textColor = UIColor.black
        }
        
        // Handle the label user tap to change location
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapFunction))
        locationLabel.isUserInteractionEnabled = true
        locationLabel.addGestureRecognizer(tap)
        
        // #Location For use when the app is open & in the background
        locationManager.requestAlwaysAuthorization()
        
        // #Location For use when app is open
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Setup views if editing an existing Meal.
        if let meal = meal {
            navigationItem.title = meal.name
            nameTextField.text = meal.name
            photoImageView.image = meal.photo
            ratingControl.rating = meal.rating
            locationLabel.text = meal.location
        }
        
        // Code when adding new meal
        if CLLocationManager.locationServicesEnabled() && !(meal != nil) {
            // Hide the ingredients / recipe fields
            ingredientsLabel.isHidden = true
            recipeField.isHidden = true
            
            // Start updating location to get the first location
            locationManager.startUpdatingLocation()
        }
        // Code when editing existing meal
        else {
            
            // Get the ingredients from existing meal in API CALL
            getIngredients()
        }
        
        // Enable the Save button only if the text field has a valid Meal name.
        updateSaveButtonState()
    }
    
    // Get the ingredients for dish
    func getIngredients() {
        
        // Fetch from api, the first result of dishes
        APIManager.sharedInstance.getDishWithName(dishName: meal!.name.replacingOccurrences(of: " ", with: "%20"), onSuccess: { json in
            DispatchQueue.main.async {
                
                // Get the recipe id from the dish
                let recipeId = String(describing: json["recipes"][0]["recipe_id"])
                
                // Next call to get the ingredients of the dish
                APIManager.sharedInstance.getRecipeWithDishId(dishId: recipeId, onSuccess: { json in DispatchQueue.main.async {
                    
                    let ingredients = JSON(json["recipe"]["ingredients"])
                    
                    // Loop through ingredients array and append to text view
                    for (_, ingredient) in ingredients {
                        self.recipeField?.text += String(describing: ingredient)
                        self.recipeField?.text += "\n"
                    }
                    
                    }}, onFailure: { error in
                        let alert = UIAlertController(title: "Error", message: "Network error", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                        self.show(alert, sender: nil)
                })
            }
        }, onFailure: { error in
            let alert = UIAlertController(title: "Error", message: "Network error", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self.show(alert, sender: nil)
        })
    }
    
    // Delegate location manager did update
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let location = locations.first {
            
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                // Process response
                self.processResponse(withPlacemarks: placemarks, error: error)
            }
            
        }
    }
    
    // Show location is disabled pop up message
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if(status == CLAuthorizationStatus.denied) {
            showLocationDisabledPopUp()
        }
    }
    
    // Location is disabled pop up
    func showLocationDisabledPopUp() {
        let alertController = UIAlertController(title: "Background Location Access Disabled", message: "In order to know where you eat this dish we need your location", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let openAction = UIAlertAction(title: "Open Settings", style: .default) {
            (action) in  if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        alertController.addAction(openAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    //MARK: UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        // Disable the Save button while editing
        saveButton.isEnabled = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Hide Keyboard
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        updateSaveButtonState()
        navigationItem.title = textField.text
    }
    
    //MARK: UIImagePickerControllerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        // Dismiss the picker if the user canceled.
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // The info dictionary may contain multiple representation of the image. You want to use the original.
        guard let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        
        // Set photoImageView to display the selected image.
        photoImageView.image = selectedImage
        
        // Dismiss the picker.
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: Navigation
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        let isPresentingInAddMealMode = presentingViewController is UINavigationController
        
        if isPresentingInAddMealMode {
            dismiss(animated: true, completion: nil)
        }
        else if let owningNavigationController = navigationController {
            owningNavigationController.popViewController(animated: true)
        }
        else {
            fatalError("The MealViewController is not inside a navigation controller.")
        }
        
        
    }
    
    // This method lets you configure a view controller before it's presented
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        // Configure the destination view controller only when the save button is pressed.
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
        
        let name = nameTextField.text ?? ""
        let photo = photoImageView.image
        let rating = ratingControl.rating
        let location = locationLabel.text ?? ""
        
        // Set the meal to be passed to MealTableViewController after unwind segue.
        meal = Meal(name: name, photo: photo, rating: rating, location: location )
    }
    
    //MARK: Actions
    @IBAction func selectImageFromPhotoLibrary(_ sender: UITapGestureRecognizer) {
        
        // Hide Keyboard
        nameTextField.resignFirstResponder()
        
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()
        
        // Only allow photos to be picked, not taken.
        imagePickerController.sourceType = .photoLibrary
        
        // Make sure ViewController is notified when the user picks an image
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        locationManager.startUpdatingLocation()
    }
    
    //MARK: Private methods
    private func updateSaveButtonState() {
        
        // Disable the Save button if the text field is empty.
        let text = nameTextField.text ?? ""
        saveButton.isEnabled = !text.isEmpty
    }
    
    // Process the placemark location response
    private func processResponse(withPlacemarks placemarks: [CLPlacemark]?, error: Error?) {
        
        if let error = error {
            print("Unable to Reverse Geocode Location (\(error))")
            locationLabel.text = "Unable to Find Address for Location"
            
        } else {
            
            // Placemark found, set location label to location name
            if let placemarks = placemarks, let placemark = placemarks.first {
                locationLabel.text =
                    placemark.thoroughfare! + " " +
                    placemark.subThoroughfare! + ", " +
                    placemark.locality! + ", " +
                    placemark.country!
                locationManager.stopUpdatingLocation()
            } else {
                locationLabel.text = "No Matching Addresses Found"
            }
        }
    }
}
