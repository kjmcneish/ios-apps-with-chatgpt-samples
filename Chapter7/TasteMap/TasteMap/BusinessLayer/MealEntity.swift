//
//  MealEntity.swift
//  TasteMap
//
//  Created by Kevin McNeish on 8/21/24.
//
//

import Foundation
import SwiftData


@Model public class MealEntity {
	
	#Unique<MealEntity>([\.id], [\.name])
	
    public var id: UUID
    var name: String
    var comment: String?
    var photo: Data?
    var dateTime: Date
    var rating: Double? = 0.0
    var type: String?
    var restaurant: RestaurantEntity
    public init(dateTime: Date = Date(), id: UUID = UUID(), name: String = "", photo: Data? = nil, comment: String? = nil, restaurant: RestaurantEntity? = RestaurantEntity()) {
        self.id = id
        self.name = name
        self.dateTime = dateTime
        self.photo = photo
        self.comment = comment
        self.restaurant = restaurant!
    }
    
}
