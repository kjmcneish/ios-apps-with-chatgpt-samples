//
//  Cuisine.swift
//  TasteMap
//
//  Created by Kevin McNeish on 8/22/24.
//

import Foundation

private let cb = Cuisine<CuisineEntity>()

public class Cuisine<T: CuisineEntity> : BusinessObject<T> {
		
	static var shared : Cuisine<CuisineEntity> { return cb }
	
	// Create a new CuisineEntity and return it
	public func createCuisine(name: String) -> T {
		
		return CuisineEntity(name: name) as! T
	}
	
	// Create a new CuisineEntity, save it and return the save result
	public func addCuisine(name: String) -> (state: SaveResult, message: String?) {
		
		let cuisineEntity = self.createCuisine(name: name)
		self.modelContext.insert(cuisineEntity)
		let saveResult = self.saveEntity(cuisineEntity)
		return saveResult
	}
    
    public func getAllCuisines() -> [T] {
        let sortDescriptor = SortDescriptor(\T.name, order: .forward) // Sort by 'name' in ascending order
        return self.getEntities(sortBy: [sortDescriptor], filterBy: nil)
    }
}
