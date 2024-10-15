//
//  CuisineEntity.swift
//  TasteMap
//
//  Created by Kevin McNeish on 8/21/24.
//
//

import Foundation
import SwiftData


@Model public class CuisineEntity {
	
	#Unique<CuisineEntity>([\.id], [\.name])
	
    public var id: UUID
    var name: String
    @Relationship(inverse: \RestaurantEntity.cuisine) var restaurants: [RestaurantEntity]?
	public init(uuid: UUID = UUID(), name: String) {
        self.id = uuid
        self.name = name
    }
    
}
