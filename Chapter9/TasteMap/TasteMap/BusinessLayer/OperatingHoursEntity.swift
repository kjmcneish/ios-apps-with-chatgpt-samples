//
//  OperatingHoursEntity.swift
//  TasteMap
//
//  Created by Kevin McNeish on 8/31/24.
//
//

import Foundation
import SwiftData


@Model public class OperatingHoursEntity {
    var dayOfWeek: Int16? = 0
    var openTime: Date?
    var closingTime: Date?
    var restaurant: RestaurantEntity?
	
	public required init(dayOfWeek: Int16, openTime: Date?, closingTime: Date?) {
		self.dayOfWeek = dayOfWeek
		self.openTime = openTime
		self.closingTime = closingTime
	}
    
}
