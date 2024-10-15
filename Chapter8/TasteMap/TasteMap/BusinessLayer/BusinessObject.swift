//
//  BusinessObject.swift
//  mmiOS8
//
//  Created by Kevin McNeish on 8/21/24.
//  Copyright (c) 2024 Oak Leaf Digital, Inc. All rights reserved.
//

import Foundation
import CoreData
import SwiftData

public enum SaveResult {
	case error
	case rulesBroken
	case saveComplete
}

open class SharedContextManager {
	// Shared model context for all instances
	static let sharedModelContext: ModelContext = {
		let modelContainer: ModelContainer
		do {
			modelContainer = try ModelContainer(for: RestaurantEntity.self, MealEntity.self, CuisineEntity.self)
		} catch {
			fatalError("Failed to initialize ModelContainer: \(error)")
		}
		return ModelContext(modelContainer)
	}()
}

open class BusinessObject<T: PersistentModel>
{
	// The database name
	var dbName : String = "TasteMap"
	
	// Indicates if a new copy of the embedded database should be
	// created if it doesn't already exist
	var copyDatabaseIfNotPresent : Bool = false
	
	// Returns the URL of the location of the physical database files:
	// default.store, default.store-shm, default.store-wal
	var databaseURL: URL {
		return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last!
	}
	
	// Use the shared context in all instances
	var modelContext: ModelContext {
		return SharedContextManager.sharedModelContext
	}
	
	init() {

	}
	
	// Gets all entities of the default type
	open func getAllEntities() -> [T] {
		return self.getEntities(sortBy: nil, filterBy: nil)
	}
	
	// Get all entities sorted by the descriptor and matching the predicate
	func getEntities(sortBy sortDescriptors: [SortDescriptor<T>]?, filterBy predicate: Predicate<T>?) -> [T] {
		let fetchDescriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortDescriptors ?? [])
		
		do {
			return try modelContext.fetch(fetchDescriptor)
		} catch {
			print("Fetch failed: \(error.localizedDescription)")
			return []
		}
	}
	
	// Adds an entity to the context, handling errors
	func insertEntity(_ entity: T) -> (state: SaveResult, message: String?) {
		modelContext.insert(entity)
		return saveEntities()
	}
	
	// Save changes to the specified entity
	func saveEntity(_ entity: T) -> (state: SaveResult, message: String?) {
		// Check the business rules
		if let rulesMessage = self.checkRulesForEntity(entity) {
			return (SaveResult.rulesBroken, rulesMessage)
		}
		return self.saveEntities()
	}
	
	// Saves changes to all new and updated entities
	open func saveEntities() -> (state: SaveResult, message: String?) {
		
		do {
			try modelContext.save()
			return (.saveComplete, nil)
		}
		catch let error as NSError {
			return (SaveResult.error, error.localizedDescription)
		}
	}
	
	// Mark the specified entity for deletion
    open func deleteEntityAndSave(_ entity: T) -> (state: SaveResult, message: String?) {
		self.modelContext.delete(entity)
        return saveEntities()
	}
	
	open func checkRulesForEntity(_ entity: T) -> String? {
		return nil
	}
	
	// Copies the database bundled with the app
   private func copyDatabaseIfNeeded() {
	   let path = databaseURL.path
	   let fileManager = FileManager.default
	   
	   guard !fileManager.fileExists(atPath: path),
			 let defaultStorePath = Bundle.main.path(forResource: self.dbName, ofType: "sqlite") else {
		   return
	   }
	   
	   do {
		   try fileManager.copyItem(atPath: defaultStorePath, toPath: path)
	   } catch {
		   print("Failed to copy database: \(error)")
	   }
   }
}
