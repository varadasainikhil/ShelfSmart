//
//  RecipeIdSearchExample.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/18/25.
//

import Foundation
import SwiftData

// Example usage of the simplified recipe ID search function
class RecipeIdSearchExample {
    
    /// Example of how to search for recipe IDs using products
    /// This demonstrates the efficient approach - get IDs first, fetch details only when needed
    func exampleUsage() async {
        // Create a sample RandomRecipeViewModel
        let viewModel = RandomRecipeViewModel()
        
        // Example 1: Search with specific ingredients
        let ingredients = ["apples", "flour", "sugar", "eggs"]
        await viewModel.findRecipeIdsByIngredients(ingredients: ingredients)
        
        // Check results
        if viewModel.ingredientsSearchSuccess {
            print("Found \(viewModel.foundRecipeIds.count) recipe IDs!")
            print("Recipe IDs: \(viewModel.foundRecipeIds)")
            
            // Display basic info from summaries
            for summary in viewModel.foundRecipeSummaries {
                print("Recipe: \(summary.title)")
                print("  - Uses \(summary.usedIngredientCount) of your ingredients")
                print("  - Missing \(summary.missedIngredientCount) ingredients")
                print("  - Likes: \(summary.likes)")
            }
            
            // Only fetch full details if user wants to see a specific recipe
            if let firstRecipeId = viewModel.foundRecipeIds.first {
                print("Fetching full details for recipe ID: \(firstRecipeId)")
                await viewModel.fetchFullRecipeDetails(recipeId: firstRecipeId)
            }
        } else if let error = viewModel.errorMessage {
            print("Error: \(error)")
        }
    }
    
    /// Example of how to integrate this into a SwiftUI view
    /// This shows the efficient pattern: show basic info first, load details on demand
    func viewIntegrationExample() {
        /*
        // In your SwiftUI view:
        @State private var recipeViewModel = RandomRecipeViewModel()
        @Environment(\.modelContext) private var modelContext
        @Query private var products: [Product]
        
        // Button to search for recipe IDs
        Button("Find Recipes with My Products") {
            Task {
                await recipeViewModel.findRecipeIdsFromProducts(products: products)
            }
        }
        
        // Display recipe summaries (fast loading)
        if recipeViewModel.ingredientsSearchSuccess {
            ForEach(recipeViewModel.foundRecipeSummaries, id: \.id) { summary in
                VStack {
                    Text(summary.title)
                    Text("Uses \(summary.usedIngredientCount) of your ingredients")
                    Text("Missing \(summary.missedIngredientCount) ingredients")
                    
                    // Button to load full details only when user taps
                    Button("View Full Recipe") {
                        Task {
                            await recipeViewModel.fetchFullRecipeDetails(recipeId: summary.id)
                        }
                    }
                }
            }
        }
        
        // Display full recipe details when loaded
        if let fullRecipe = recipeViewModel.fetchedRecipe {
            // Show detailed recipe view
            Text("Full Recipe: \(fullRecipe.title)")
            // ... other detailed recipe information
        }
        */
    }
    
    /// Example showing the efficiency benefits
    func efficiencyExample() {
        /*
        Benefits of this approach:
        
        1. FAST INITIAL LOAD:
           - Only fetches basic info (ID, title, ingredient counts)
           - Much smaller response size
           - Faster network request
        
        2. ON-DEMAND DETAILS:
           - Full recipe details only loaded when user needs them
           - Saves API quota
           - Better user experience
        
        3. BETTER PERFORMANCE:
           - Initial search returns 3 recipe IDs quickly
           - User can see options immediately
           - Full details loaded only for selected recipe
        
        4. API QUOTA EFFICIENT:
           - One call to get 3 recipe IDs
           - Additional calls only when needed
           - Reduces unnecessary API usage
        */
    }
}
