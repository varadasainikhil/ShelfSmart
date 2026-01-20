//
//  ModelContainerFactory.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 1/19/26.
//  Extracted from ShelfSmartApp.swift for better separation of concerns.
//

import Foundation
import SwiftData

/// Factory for creating and configuring the SwiftData ModelContainer
/// Handles schema definition, CloudKit configuration, and fallback strategies
enum ModelContainerFactory {
    
    // MARK: - Schema Definition
    
    /// Complete schema including all SwiftData models
    static var fullSchema: Schema {
        Schema([
            // Spoonacular Products
            GroupedProducts.self,
            Product.self,
            Credit.self,
            SDRecipe.self,
            SDAnalyzedInstructions.self,
            SDSteps.self,
            SDStepIngredient.self,
            SDEquipment.self,
            SDIngredients.self,
            SDMeasures.self,
            SDMeasure.self,

            // OFFA Products
            GroupedOFFAProducts.self,
            LSProduct.self,
            LSIngredient.self,
            LSNutriments.self,
            LSNutriscoreData.self,
            LSNutriscoreComponents.self,
            LSNutrientComponent.self,
            SDOFFARecipe.self,
            SDOFFAAnalyzedInstructions.self,
            SDOFFASteps.self,
            SDOFFAStepIngredient.self,
            SDOFFAEquipment.self,
            SDOFFAIngredients.self,
            SDOFFAMeasures.self,
            SDOFFAMeasure.self
        ])
    }
    
    /// Minimal schema for emergency fallback
    static var minimalSchema: Schema {
        Schema([
            // Spoonacular Products (minimal)
            GroupedProducts.self,
            Product.self,
            Credit.self,
            SDRecipe.self,

            // OFFA Products (minimal)
            GroupedOFFAProducts.self,
            LSProduct.self,
            SDOFFARecipe.self
        ])
    }
    
    // MARK: - Container Creation
    
    /// Creates the primary ModelContainer with CloudKit sync enabled
    /// - Returns: A configured ModelContainer
    /// - Throws: An error if container creation fails
    static func createPersistentContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: fullSchema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .automatic
        )
        
        return try ModelContainer(for: fullSchema, configurations: [configuration])
    }
    
    /// Creates an in-memory container as fallback when persistent storage fails
    /// - Returns: An in-memory ModelContainer
    /// - Throws: An error if container creation fails
    static func createInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: fullSchema,
            isStoredInMemoryOnly: true
        )
        
        return try ModelContainer(for: fullSchema, configurations: [configuration])
    }
    
    /// Creates an emergency fallback container with minimal schema
    /// - Returns: A minimal in-memory ModelContainer
    /// - Throws: An error if container creation fails
    static func createEmergencyContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: minimalSchema,
            isStoredInMemoryOnly: true
        )
        
        return try ModelContainer(for: minimalSchema, configurations: [configuration])
    }
    
    // MARK: - Factory Method
    
    /// Creates a ModelContainer with automatic fallback strategy
    /// Attempts: Persistent -> In-Memory -> Emergency -> Fatal Error
    /// - Returns: A ModelContainer configured with the best available storage
    static func createWithFallback() -> ModelContainer {
        // Attempt 1: Persistent storage with CloudKit
        do {
            let container = try createPersistentContainer()
            print("✅ ModelContainer created with persistent storage and CloudKit sync")
            return container
        } catch {
            logContainerError(error, attempt: "persistent")
        }
        
        // Attempt 2: In-memory storage
        do {
            let container = try createInMemoryContainer()
            print("⚠️ Falling back to in-memory storage - data will not persist!")
            return container
        } catch {
            logContainerError(error, attempt: "in-memory")
        }
        
        // Attempt 3: Emergency minimal schema
        do {
            let container = try createEmergencyContainer()
            print("⚠️ Using emergency fallback container with minimal schema")
            return container
        } catch {
            logContainerError(error, attempt: "emergency")
        }
        
        // Fatal: All attempts failed
        fatalError("Critical system error: Unable to initialize data storage. Please reinstall the app.")
    }
    
    // MARK: - Error Logging
    
    private static func logContainerError(_ error: Error, attempt: String) {
        print("❌ Failed to create \(attempt) ModelContainer: \(error)")
        print("❌ Error details: \(error.localizedDescription)")
        
        if let nsError = error as NSError? {
            print("❌ Error domain: \(nsError.domain)")
            print("❌ Error code: \(nsError.code)")
            print("❌ Error userInfo: \(nsError.userInfo)")
            
            if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                print("❌ Underlying error: \(underlyingError.localizedDescription)")
                print("❌ Underlying error domain: \(underlyingError.domain)")
                print("❌ Underlying error code: \(underlyingError.code)")
            }
        }
    }
}
