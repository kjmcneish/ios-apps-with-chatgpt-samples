//
//  RestaurantEntity.swift
//  TasteMap
//
//  Created by Kevin McNeish on 8/21/24.
//
//

import Foundation
import SwiftData

@Model public class RestaurantEntity {
	
	#Unique<RestaurantEntity>([\.id], [\.name])
	
	public var id: UUID
    var name: String
	var address: String?
	var city: String?
	var country: String?
    var latitude: Double? = 0.0
    var longitude: Double? = 0.0
	var postalCode: String?
    var neighborhood: String?
    var descriptionText: String?
    var phone: String?
    var photo: Data?
    var dateTimeCreated: Date
    var rating: Double? = 0.0
    var cuisine: CuisineEntity?
	var hours: [OperatingHoursEntity]?
    
    private var noAddressSpecifiedText = "No address specified"
	
    // Computed property for the full address
    var fullAddress: String {
        var components: [String] = []
        
        if let address = address, !address.isEmpty {
            components.append(address)
        }
        if let postalCode = postalCode, !postalCode.isEmpty {
            components.append(postalCode)
        }
        if let city = city, !city.isEmpty {
            components.append(city)
        }
        if let country = country, !country.isEmpty {
            components.append(country)
        }
        
        // If no components were added, return "No address specified"
        if components.isEmpty {
            return self.noAddressSpecifiedText
        }
        
        return components.joined(separator: ", ")
    }
    
    // Computed property to check if both location and address haven't been specified
    var isLocationAndAddressMissing: Bool {
        // Check if latitude and longitude are set and valid (not 0.0)
        let hasValidCoordinates = latitude != nil && longitude != nil && latitude != 0.0 && longitude != 0.0
        // Check if fullAddress has meaningful data
        let hasValidAddress = fullAddress != self.noAddressSpecifiedText
        // Return true if both coordinates and address are missing
        return !hasValidCoordinates && !hasValidAddress
    }
	
    @Relationship(deleteRule: .cascade) var meals: [MealEntity]?
    public init(id: UUID = UUID(), dateTimeCreated: Date = Date(), name: String = "") {
        self.name = name
        self.dateTimeCreated = dateTimeCreated
        self.id = id
    }
}
