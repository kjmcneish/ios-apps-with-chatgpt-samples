//
//  DataPopulationManager.swift
//  TasteMap
//
//  Created by Kevin McNeish on 9/8/24.
//

import Foundation
import UIKit

class DataPopulationManager {
    
    static let shared = DataPopulationManager()
    
    func populateDataIfNeeded() {
        let hasPopulatedData = UserDefaults.standard.bool(forKey: "hasPopulatedData")
        
        if !hasPopulatedData {
            let result = self.populateData()
            if result.state == .saveComplete {
                UserDefaults.standard.set(true, forKey: "hasPopulatedData")
                print("Data populated successfully")
            } else {
                print("Data population failed: \(result.message ?? "Unknown error")")
            }
        }
    }
    
    // Method to populate cuisines and restaurants
    func populateData() -> (state: SaveResult, message: String?) {
        
        // Populate cuisines first
        let cuisineResult = self.populateCuisines()
        if cuisineResult.state == .error {
            return cuisineResult
        }
        
        // Then populate restaurants
        let restaurantResult = self.populateRestaurants()
        if restaurantResult.state == .error {
            return restaurantResult
        }
        
        return (.saveComplete, nil)
    }
    
    
    // Populate the database with a comprehensive list of cuisines
    public func populateCuisines() -> (state: SaveResult, message: String?) {
        let cuisineList = [
            "Afghan", "Albanian", "Algerian", "American", "Argentinian", "Armenian", "Asian", "Australian", "Austrian", "Bangladeshi", "Bakery",
            "Belgian", "Bolivian", "Brazilian", "British", "Brunch", "Bulgarian", "Burmese", "Cajun", "Cambodian", "Caribbean",
            "Chilean", "Chinese", "Colombian", "Coffee", "Cuban", "Cypriot", "Czech", "Danish", "Dominican", "Dutch",
            "Ecuadorian", "Egyptian", "Ethiopian", "Filipino", "Finnish", "French", "Georgian", "German", "Ghanaian",
            "Greek", "Guatemalan", "Haitian", "Hawaiian", "Honduran", "Hungarian", "Indian", "Indonesian", "International",
            "Iranian", "Iraqi", "Irish", "Israeli", "Italian", "Ivorian", "Jamaican", "Japanese", "Jewish", "Jordanian",
            "Kenyan", "Korean", "Kosovar", "Kurdish", "Laotian", "Latvian", "Lebanese", "Liberian", "Libyan",
            "Lithuanian", "Malaysian", "Maldivian", "Malian", "Maltese", "Mauritian", "Mediterranean", "Mexican",
            "Middle Eastern", "Mongolian", "Moroccan", "Nepalese", "New Zealand", "Nigerian", "Norwegian", "Pakistani",
            "Panamanian", "Paraguayan", "Peruvian", "Persian", "Polish", "Portuguese", "Puerto Rican", "Romanian", "Seafood",
            "Russian", "Salvadoran", "Saudi Arabian", "Scottish", "Senegalese", "Serbian", "Singaporean", "Slovak",
            "Somali", "South African", "Spanish", "Sri Lankan", "Sudanese", "Swedish", "Swiss", "Syrian", "Taiwanese",
            "Tajik", "Tanzanian", "Thai", "Tibetan", "Togolese", "Tunisian", "Turkish", "Ukrainian", "Uruguayan",
            "Uzbek", "Vegan", "Vegetarian", "Venezuelan", "Vietnamese", "Welsh", "Yemeni", "Zambian", "Zimbabwean"
        ]
        
        for cuisineName in cuisineList {
            let result = Cuisine.shared.addCuisine(name: cuisineName)
            if result.state == .error {
                return result
            }
        }
        
        return (.saveComplete, nil)
    }
    
    // Method to populate restaurants
    func populateRestaurants() -> (state: SaveResult, message: String?) {
        let restaurants = [
            ("Deli, Deli", 41.1515, -8.6070, "Rua Sá da Bandeira 578", "Porto", "Portugal", "4000-431", "International", "Trindade", "RestaurantDeliDeli",
             [
                (1, "09:00", "18:00"), // Sunday
                (2, "09:00", "18:00"), // Monday
                (3, "09:00", "18:00"), // Tuesday
                (4, "09:00", "18:00"), // Wednesday
                (5, "09:00", "18:00"), // Thursday
                (6, "09:00", "18:00"), // Friday
                (7, "09:00", "18:00"), // Saturday
             ]),
            ("Restaurante O Valentim", 41.1250, -8.6455, "Rua Heróis de França 263", "Matosinhos", "Portugal", "4450-159", "Portuguese", "Matosinhos", "RestaurantOValentim", [
                (1, "12:00", "23:00"), // Sunday
                (2, "12:00", "23:00"), // Monday
                (3, "12:00", "23:00"), // Tuesday
                (4, "12:00", "22:00"), // Wednesday
                (5, "12:00", "23:00"), // Thursday
                (6, "12:00", "23:00"), // Friday
                (7, "12:00", "23:00"), // Saturday
            ]),
            ("Indian Flavours", 41.1633, -8.6141, "R. da Constituição 1343", "Porto", "Portugal", "4250-167", "Indian", "Neighborhood", "RestaurantIndianFlavours", [
                (1, "11:00", "00:00"), // Sunday
                (2, "11:00", "23:00"), // Monday
                (3, "11:00", "23:00"), // Tuesday
                (4, "11:00", "23:00"), // Wednesday
                (5, "11:00", "23:00"), // Thursday
                (6, "11:00", "00:00"), // Friday
                (7, "11:00", "00:00"), // Saturday
            ])
        ]
        
        for restaurant in restaurants {
            let entity = RestaurantEntity(name: restaurant.0)
            entity.latitude = restaurant.1
            entity.longitude = restaurant.2
            entity.address = restaurant.3
            entity.city = restaurant.4
            entity.country = restaurant.5
            entity.postalCode = restaurant.6
            entity.cuisine = Cuisine.shared.getAllEntities().first { $0.name == restaurant.7 }
            entity.neighborhood = restaurant.8
            
            // Populate operating hours
            var operatingHours: [OperatingHoursEntity] = []
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            
            // Load the restaurant image from Assets.xcassets
            if let image = UIImage(named: restaurant.9) {
                entity.photo = image.jpegData(compressionQuality: 0.8)
            }
            
            for hourInfo in restaurant.10 {
                if let openTime = dateFormatter.date(from: hourInfo.1),
                   let closeTime = dateFormatter.date(from: hourInfo.2) {
                    let operatingHour = OperatingHoursEntity(dayOfWeek: Int16(hourInfo.0), openTime: openTime, closingTime: closeTime)
                    operatingHours.append(operatingHour)
                    operatingHour.restaurant = entity // Associate with the restaurant
                }
            }
            
            entity.hours = operatingHours
            
            let result = Restaurant.shared.insertEntity(entity)
            if result.state == .error {
                return result
            }
        }
        
        return (.saveComplete, nil)
    }
}

