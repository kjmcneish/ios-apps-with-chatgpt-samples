//
//  Meal.swift
//  TasteMap
//
//  Created by Kevin McNeish on 9/11/24.
//

import Foundation

private let mealSharedInstance = Meal<MealEntity>()

public class Meal<T: MealEntity>: BusinessObject<T> {
    
    // Singleton instance for shared access
    static var shared: Meal<MealEntity> { return mealSharedInstance }
    
    // Fetch meals associated with a specific restaurant
    public func getMeals(for restaurant: RestaurantEntity) -> [MealEntity] where T == MealEntity {
        let restaurantId = restaurant.id

        let predicate = #Predicate<MealEntity> { meal in
            meal.restaurant.id == restaurantId
        }

        return self.getEntities(sortBy: nil, filterBy: predicate)
    }

    // Override checkRulesForEntity to implement meal-specific rules
    open override func checkRulesForEntity(_ entity: T) -> String? {
        
        if entity.name.isEmpty {
            return "Meal name cannot be empty"
        }
        
        return nil
    }
}
