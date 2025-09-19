//
//  ProductRecipeIdsExample.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/18/25.
//

import Foundation
import SwiftData

// Example showing how to access and use recipe IDs stored in products
class ProductRecipeIdsExample {
    
    /// Example of how to access recipe IDs from a product
    func accessRecipeIdsFromProduct(product: Product) {
        // Check if the product has recipe IDs
        if let recipeIds = product.recipeIds, !recipeIds.isEmpty {
            print("🍽️ Product '\(product.title)' has \(recipeIds.count) recipe IDs:")
            for (index, recipeId) in recipeIds.enumerated() {
                print("  \(index + 1). Recipe ID: \(recipeId)")
            }
            
            // You can now use these IDs to fetch full recipe details
            // when the user wants to see recipes for this product
        } else {
            print("❌ Product '\(product.title)' has no recipe IDs")
        }
    }
    
    /// Example of how to use recipe IDs in a SwiftUI view
    func swiftUIExample() {
        /*
        // In your SwiftUI view:
        @Environment(\.modelContext) private var modelContext
        @Query private var products: [Product]
        @State private var recipeViewModel = RandomRecipeViewModel()
        
        // Display products with their recipe counts
        ForEach(products) { product in
            VStack {
                Text(product.title)
                
                if let recipeIds = product.recipeIds, !recipeIds.isEmpty {
                    Text("\(recipeIds.count) recipes available")
                        .foregroundColor(.green)
                    
                    // Button to fetch full recipe details
                    Button("View Recipes") {
                        // Use the first recipe ID as an example
                        if let firstRecipeId = recipeIds.first {
                            Task {
                                await recipeViewModel.fetchFullRecipeDetails(recipeId: firstRecipeId)
                            }
                        }
                    }
                } else {
                    Text("No recipes found")
                        .foregroundColor(.gray)
                }
            }
        }
        */
    }
    
    /// Example of how to search for recipes using all products
    func searchRecipesFromAllProducts(products: [Product]) {
        // Collect all recipe IDs from all products
        var allRecipeIds: [Int] = []
        
        for product in products {
            if let recipeIds = product.recipeIds {
                allRecipeIds.append(contentsOf: recipeIds)
            }
        }
        
        // Remove duplicates
        let uniqueRecipeIds = Array(Set(allRecipeIds))
        
        print("🍽️ Found \(uniqueRecipeIds.count) unique recipe IDs across all products:")
        print("Recipe IDs: \(uniqueRecipeIds)")
        
        // You can now use these IDs to fetch recipe details
        // or display them in your UI
    }
    
    /// Example showing the benefits of storing recipe IDs locally
    func benefitsExample() {
        /*
        Benefits of storing recipe IDs in Product model:
        
        1. OFFLINE ACCESS:
           - Recipe IDs are stored locally with SwiftData
           - No need to search again when viewing products
           - Works even without internet connection
        
        2. FAST LOADING:
           - Recipe IDs are immediately available
           - No API calls needed to show recipe count
           - Better user experience
        
        3. EFFICIENT API USAGE:
           - Recipe search happens only once when product is added
           - Full recipe details fetched only when needed
           - Saves API quota and improves performance
        
        4. PERSISTENT DATA:
           - Recipe IDs persist across app sessions
           - No need to re-search for recipes
           - Data is synced with CloudKit if enabled
        */
    }
}
