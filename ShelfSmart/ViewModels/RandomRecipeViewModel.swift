//
//  RandomRecipeViewModel.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/16/25.
//

import Foundation
import SwiftData

// Wrapper for Spoonacular random recipe API response
struct RandomRecipeResponse: Codable {
    let recipes: [Recipe]
}

@Observable
class RandomRecipeViewModel {
    // Separate arrays for better organization and performance
    var selectedMealTypes: [String] = []
    var selectedCuisines: [String] = []
    var selectedDiets: [String] = []
    var selectedIntolerances: [String] = []
    
    var isLoading = false
    var errorMessage : String?
    var searchSuccess = false
    var id : Int?
    var fetchedRecipe: SDRecipe?
    
    // Properties for find by ingredients functionality
    var foundRecipeIds: [Int] = []
    var foundRecipeSummaries: [FindByIngredientsRecipe] = []
    var ingredientsSearchSuccess = false
    
    /// Computed property that combines all selected tags if needed
    var allSelectedTags: [String] {
        return selectedMealTypes + selectedCuisines + selectedDiets + selectedIntolerances
    }
    
    // MARK: - Cuisine Management
    func addCuisine (cuisine : Cuisine){
        if !selectedCuisines.contains(cuisine.apiValue) {
            selectedCuisines.append(cuisine.apiValue)
        }
    }
    
    func removeCuisine (cuisine : Cuisine){
        selectedCuisines.removeAll(where: {$0 == cuisine.apiValue})
    }
    
    // MARK: - Diet Management
    func addDiet (diet : Diet){
        if !selectedDiets.contains(diet.apiValue) {
            selectedDiets.append(diet.apiValue)
        }
    }
    
    func removeDiet (diet : Diet){
        selectedDiets.removeAll(where: {$0 == diet.apiValue})
    }
    
    // MARK: - Intolerance Management
    func addIntolerance (intolerance : Intolerances){
        if !selectedIntolerances.contains(intolerance.apiValue) {
            selectedIntolerances.append(intolerance.apiValue)
        }
    }
    
    func removeIntolerance (intolerance : Intolerances){
        selectedIntolerances.removeAll(where: {$0 == intolerance.apiValue})
    }
    
    // MARK: - Meal Type Management
    func addMealType (mealType : MealType ){
        if !selectedMealTypes.contains(mealType.apiValue) {
            selectedMealTypes.append(mealType.apiValue)
        }
    }
    
    func removeMealType (mealType : MealType){
        selectedMealTypes.removeAll(where: {$0 == mealType.apiValue})
    }
    
    // MARK: - Utility Functions
    
    /// Clears all selected filters
    func clearAllSelections() {
        selectedMealTypes.removeAll()
        selectedCuisines.removeAll()
        selectedDiets.removeAll()
        selectedIntolerances.removeAll()
        print("🧹 All selections cleared")
    }
    
    /// Returns true if any filters are selected
    var hasAnySelections: Bool {
        return !selectedMealTypes.isEmpty || !selectedCuisines.isEmpty || 
               !selectedDiets.isEmpty || !selectedIntolerances.isEmpty
    }
    
    /// Returns the total count of all selections
    var totalSelectionCount: Int {
        return selectedMealTypes.count + selectedCuisines.count + 
               selectedDiets.count + selectedIntolerances.count
    }
    
    func getAPIKey() -> String? {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let apiKey = plist["API_KEY"] as? String else {
            return nil
        }
        print(apiKey)
        return apiKey
    }
    
    func completelyRandomRecipe() async {
        // Prevent duplicate calls if already loading
        if isLoading {
            print("⚠️ Already loading recipe, skipping duplicate call")
            return
        }
        
        // Set initial loading state
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            searchSuccess = false
            fetchedRecipe = nil
        }
        
        print("🔍 Searching for random recipe")
        
        do {
            // Get and validate API key
            guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
                print("❌ Error: API key is nil or empty")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "API key not configured. Please check your configuration."
                }
                return
            }
            
            print("✅ API key retrieved successfully")
            
            // Build URL with query parameters
            guard var urlComponents = URLComponents(string: "https://api.spoonacular.com/recipes/random") else {
                print("❌ Error: Failed to create URL components")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid API URL configuration"
                }
                return
            }
            
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "apiKey", value: apiKey),
                URLQueryItem(name: "number", value: "1") // Ensure we get exactly 1 recipe
            ]
            
            // Add include tags if any are selected (use combined tags)
            if hasAnySelections {
                let tagsString = allSelectedTags.joined(separator: ",")
                queryItems.append(URLQueryItem(name: "include-tags", value: tagsString))
                print("🏷️ Including tags: \(tagsString)")
            }
            
            urlComponents.queryItems = queryItems
            
            guard let url = urlComponents.url else {
                print("❌ Error: Failed to create final URL")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to construct API request URL"
                }
                return
            }
            
            print("🌐 Making request to: \(url.absoluteString)")
            
            // Make API request
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Error: Invalid response type")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid server response"
                }
                return
            }
            
            print("📡 Response status code: \(httpResponse.statusCode)")
            
            // Handle HTTP error status codes
            switch httpResponse.statusCode {
            case 200...299:
                print("✅ Successful response")
            case 401:
                print("❌ Unauthorized: Invalid API key")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid API key. Please check your configuration."
                }
                return
            case 402:
                print("❌ Payment required: API quota exceeded")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "API quota exceeded. Please try again later."
                }
                return
            case 403:
                print("❌ Forbidden: Access denied")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Access denied. Please check your API permissions."
                }
                return
            case 404:
                print("❌ Not found: Invalid endpoint")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "API endpoint not found. Please try again."
                }
                return
            case 429:
                print("❌ Too many requests: Rate limit exceeded")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Rate limit exceeded. Please wait before trying again."
                }
                return
            case 500...599:
                print("❌ Server error: \(httpResponse.statusCode)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Server error. Please try again later."
                }
                return
            default:
                print("❌ Unexpected status code: \(httpResponse.statusCode)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Unexpected error occurred. Please try again."
                }
                return
            }
            
            print("📦 Received data size: \(data.count) bytes")
            
            // Validate data is not empty
            guard !data.isEmpty else {
                print("❌ Error: Empty response data")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Empty response from server"
                }
                return
            }
            
            // Parse JSON response
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(RandomRecipeResponse.self, from: data)
            
            print("✅ Successfully decoded API response")
            
            // Validate we received recipes
            guard !apiResponse.recipes.isEmpty else {
                print("⚠️ No recipes found in response")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "No recipes found matching your criteria. Please try different filters."
                }
                return
            }
            
            // Get the first (and should be only) recipe
            let recipe = apiResponse.recipes[0]
            print("🍽️ Recipe found: \(recipe.title)")
            print("🆔 Recipe ID: \(recipe.id)")
            
            // Convert to SwiftData model (but don't save to context)
            let sdRecipe = SDRecipe(from: recipe)
            
            print("✅ Successfully converted to SwiftData model")
            
            // Update UI on main actor
            await MainActor.run {
                fetchedRecipe = sdRecipe
                id = recipe.id
                isLoading = false
                searchSuccess = true
                errorMessage = nil
                print("🎉 Recipe fetch completed successfully!")
            }
            
        } catch let decodingError as DecodingError {
            print("❌ JSON Decoding Error: \(decodingError)")
            
            // Provide more specific decoding error messages
            let decodingMessage: String
            switch decodingError {
            case .dataCorrupted:
                decodingMessage = "Corrupted data received from server"
            case .keyNotFound(let key, _):
                decodingMessage = "Missing required field: \(key.stringValue)"
            case .typeMismatch(let type, _):
                decodingMessage = "Invalid data type received: expected \(type)"
            case .valueNotFound(let type, _):
                decodingMessage = "Missing required value of type: \(type)"
            @unknown default:
                decodingMessage = "Failed to parse server response"
            }
            
            await MainActor.run {
                isLoading = false
                errorMessage = decodingMessage
            }
            
        } catch let urlError as URLError {
            print("❌ Network Error: \(urlError)")
            print("❌ Network Error Code: \(urlError.code.rawValue)")
            
            // Provide user-friendly network error messages
            let networkMessage: String
            switch urlError.code {
            case .notConnectedToInternet:
                networkMessage = "No internet connection. Please check your network settings."
            case .timedOut:
                networkMessage = "Request timed out. Please try again."
            case .cannotFindHost:
                networkMessage = "Cannot reach server. Please check your connection."
            case .networkConnectionLost:
                networkMessage = "Network connection lost. Please try again."
            case .dnsLookupFailed:
                networkMessage = "DNS lookup failed. Please check your internet connection."
            default:
                networkMessage = "Network error occurred. Please try again."
            }
            
            await MainActor.run {
                isLoading = false
                errorMessage = networkMessage
            }
            
        } catch {
            print("❌ Unexpected Error: \(error)")
            print("❌ Error Type: \(type(of: error))")
            print("❌ Error Description: \(error.localizedDescription)")
            
            await MainActor.run {
                isLoading = false
                errorMessage = "An unexpected error occurred. Please try again."
            }
        }
    }
    
    /// Clears the currently fetched recipe and resets search state
    func clearFetchedRecipe() {
        fetchedRecipe = nil
        searchSuccess = false
        errorMessage = nil
        id = nil
    }
    
    /// Saves the currently fetched recipe to SwiftData context
    func saveFetchedRecipe(to modelContext: ModelContext) {
        guard let recipe = fetchedRecipe else {
            errorMessage = "No recipe to save"
            return
        }
        
        do {
            modelContext.insert(recipe)
            try modelContext.save()
            print("✅ Recipe saved to SwiftData successfully")
        } catch {
            print("❌ Failed to save recipe: \(error)")
            errorMessage = "Failed to save recipe: \(error.localizedDescription)"
        }
    }
    
    /// Fetches a custom random recipe based on user-selected filters
    /// Uses the separate arrays for better performance and clarity
    func customRandomRecipe() async {
        // Prevent duplicate calls if already loading
        if isLoading {
            print("⚠️ Already loading recipe, skipping duplicate call")
            return
        }
        
        // Set initial loading state
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            searchSuccess = false
            fetchedRecipe = nil
        }
        
        print("🔍 Searching for custom random recipe with filters:")
        print("   Meal Types: \(selectedMealTypes)")
        print("   Cuisines: \(selectedCuisines)")
        print("   Diets: \(selectedDiets)")
        print("   Intolerances: \(selectedIntolerances)")
        
        do {
            // Get and validate API key
            guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
                print("❌ Error: API key is nil or empty")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "API key not configured. Please check your configuration."
                }
                return
            }
            
            print("✅ API key retrieved successfully")
            
            // Build URL with query parameters
            guard var urlComponents = URLComponents(string: "https://api.spoonacular.com/recipes/complexSearch") else {
                print("❌ Error: Failed to create URL components")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid API URL configuration"
                }
                return
            }
            
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "apiKey", value: apiKey),
                URLQueryItem(name: "number", value: "1"), // Ensure we get exactly 1 recipe
                URLQueryItem(name: "sort", value: "random")
            ]
            
            // Add meal type parameter (use 'type' for Spoonacular API)
            if !selectedMealTypes.isEmpty {
                let mealTypesString = selectedMealTypes.joined(separator: ",")
                queryItems.append(URLQueryItem(name: "type", value: mealTypesString))
                print("🍽️ Adding meal types: \(mealTypesString)")
            }
            
            // Add cuisine parameter
            if !selectedCuisines.isEmpty {
                let cuisinesString = selectedCuisines.joined(separator: ",")
                queryItems.append(URLQueryItem(name: "cuisine", value: cuisinesString))
                print("🌍 Adding cuisines: \(cuisinesString)")
            }
            
            // Add diet parameter
            if !selectedDiets.isEmpty {
                let dietsString = selectedDiets.joined(separator: ",")
                queryItems.append(URLQueryItem(name: "diet", value: dietsString))
                print("🥗 Adding diets: \(dietsString)")
            }
            
            // Add intolerances parameter (use 'excludeIngredients' for Spoonacular API)
            if !selectedIntolerances.isEmpty {
                let intolerancesString = selectedIntolerances.joined(separator: ",")
                queryItems.append(URLQueryItem(name: "excludeIngredients", value: intolerancesString))
                print("🚫 Adding intolerances: \(intolerancesString)")
            }
            
            urlComponents.queryItems = queryItems
            
            guard let url = urlComponents.url else {
                print("❌ Error: Failed to create final URL")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to construct API request URL"
                }
                return
            }
            
            print("🌐 Making request to: \(url.absoluteString)")
            
            // Make API request
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Error: Invalid response type")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid server response"
                }
                return
            }
            
            print("📡 Response status code: \(httpResponse.statusCode)")
            
            // Handle HTTP error status codes
            switch httpResponse.statusCode {
            case 200...299:
                print("✅ Successful response")
            case 401:
                print("❌ Unauthorized: Invalid API key")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid API key. Please check your configuration."
                }
                return
            case 402:
                print("❌ Payment required: API quota exceeded")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "API quota exceeded. Please try again later."
                }
                return
            case 403:
                print("❌ Forbidden: Access denied")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Access denied. Please check your API permissions."
                }
                return
            case 404:
                print("❌ Not found: Invalid endpoint")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "API endpoint not found. Please try again."
                }
                return
            case 429:
                print("❌ Too many requests: Rate limit exceeded")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Rate limit exceeded. Please wait before trying again."
                }
                return
            case 500...599:
                print("❌ Server error: \(httpResponse.statusCode)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Server error. Please try again later."
                }
                return
            default:
                print("❌ Unexpected status code: \(httpResponse.statusCode)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Unexpected error occurred. Please try again."
                }
                return
            }
            
            print("📦 Received data size: \(data.count) bytes")
            
            // Validate data is not empty
            guard !data.isEmpty else {
                print("❌ Error: Empty response data")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Empty response from server"
                }
                return
            }
            
            // Parse JSON response
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(ComplexSearchRecipeResponse.self, from: data)
            
            print("✅ Successfully decoded API response")
            
            
            // Validate we received recipes
            guard !apiResponse.results.isEmpty else {
                print("⚠️ No recipes found in response")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "No recipes found matching your criteria. Please try different filters."
                }
                return
            }
            
            // Get the first (and should be only) recipe
            let searchResult = apiResponse.results[0]
            print("🍽️ Recipe found: \(searchResult.title)")
            print("🆔 Recipe ID: \(searchResult.id)")
            
            // Validate that we have a valid recipe ID
            guard searchResult.id > 0 else {
                print("❌ Invalid recipe ID: \(searchResult.id)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid recipe data received. Please try again."
                }
                return
            }
            
            print("✅ Valid recipe ID confirmed, fetching complete recipe details...")
            
            // Fetch complete recipe details using the ID
            await fetchCompleteRecipeById(id: searchResult.id)
            
        } catch let decodingError as DecodingError {
            print("❌ JSON Decoding Error: \(decodingError)")
            
            // Provide more specific decoding error messages
            let decodingMessage: String
            switch decodingError {
            case .dataCorrupted:
                decodingMessage = "Corrupted data received from server"
            case .keyNotFound(let key, _):
                decodingMessage = "Missing required field: \(key.stringValue)"
            case .typeMismatch(let type, _):
                decodingMessage = "Invalid data type received: expected \(type)"
            case .valueNotFound(let type, _):
                decodingMessage = "Missing required value of type: \(type)"
            @unknown default:
                decodingMessage = "Failed to parse server response"
            }
            
            await MainActor.run {
                isLoading = false
                errorMessage = decodingMessage
            }
            
        } catch let urlError as URLError {
            print("❌ Network Error: \(urlError)")
            print("❌ Network Error Code: \(urlError.code.rawValue)")
            
            // Provide user-friendly network error messages
            let networkMessage: String
            switch urlError.code {
            case .notConnectedToInternet:
                networkMessage = "No internet connection. Please check your network settings."
            case .timedOut:
                networkMessage = "Request timed out. Please try again."
            case .cannotFindHost:
                networkMessage = "Cannot reach server. Please check your connection."
            case .networkConnectionLost:
                networkMessage = "Network connection lost. Please try again."
            case .dnsLookupFailed:
                networkMessage = "DNS lookup failed. Please check your internet connection."
            default:
                networkMessage = "Network error occurred. Please try again."
            }
            
            await MainActor.run {
                isLoading = false
                errorMessage = networkMessage
            }
            
        } catch {
            print("❌ Unexpected Error: \(error)")
            print("❌ Error Type: \(type(of: error))")
            print("❌ Error Description: \(error.localizedDescription)")
            
            await MainActor.run {
                isLoading = false
                errorMessage = "An unexpected error occurred. Please try again."
            }
        }
    }
    
    /// Fetches complete recipe details by ID from Spoonacular API
    /// This is called after getting a recipe ID from complexSearch to get full recipe details
    private func fetchCompleteRecipeById(id: Int) async {
        print("🔍 Fetching complete recipe details for ID: \(id)")
        
        do {
            // Get API key
            guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
                print("❌ Error: API key is nil or empty")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "API key not configured. Please check your configuration."
                }
                return
            }
            
            // Build URL for recipe information endpoint
            guard var urlComponents = URLComponents(string: "https://api.spoonacular.com/recipes/\(id)/information") else {
                print("❌ Error: Failed to create URL components")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid API URL configuration"
                }
                return
            }
            
            urlComponents.queryItems = [
                URLQueryItem(name: "apiKey", value: apiKey),
                URLQueryItem(name: "includeNutrition", value: "false") // Set to true if you want nutrition data
            ]
            
            guard let url = urlComponents.url else {
                print("❌ Error: Failed to create final URL")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to construct API request URL"
                }
                return
            }
            
            print("🌐 Making request to: \(url.absoluteString)")
            
            // Make API request
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Error: Invalid response type")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid server response"
                }
                return
            }
            
            print("📡 Response status code: \(httpResponse.statusCode)")
            
            // Handle HTTP error status codes
            switch httpResponse.statusCode {
            case 200...299:
                print("✅ Successful response")
            case 401:
                print("❌ Unauthorized: Invalid API key")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid API key. Please check your configuration."
                }
                return
            case 402:
                print("❌ Payment required: API quota exceeded")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "API quota exceeded. Please try again later."
                }
                return
            case 404:
                print("❌ Recipe not found")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Recipe not found. Please try a different search."
                }
                return
            case 429:
                print("❌ Too many requests: Rate limit exceeded")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Rate limit exceeded. Please wait before trying again."
                }
                return
            case 500...599:
                print("❌ Server error: \(httpResponse.statusCode)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Server error. Please try again later."
                }
                return
            default:
                print("❌ Unexpected status code: \(httpResponse.statusCode)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Unexpected error occurred. Please try again."
                }
                return
            }
            
            print("📦 Received data size: \(data.count) bytes")
            
            // Validate data is not empty
            guard !data.isEmpty else {
                print("❌ Error: Empty response data")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Empty response from server"
                }
                return
            }
            
            // Parse JSON response - the recipe information endpoint returns a single Recipe object
            let decoder = JSONDecoder()
            let recipe = try decoder.decode(Recipe.self, from: data)
            
            print("✅ Successfully decoded complete recipe")
            print("🍽️ Complete recipe: \(recipe.title)")
            print("🥘 Ingredients count: \(recipe.extendedIngredients?.count ?? 0)")
            print("📋 Has instructions: \(recipe.analyzedInstructions?.isEmpty == false || recipe.instructions?.isEmpty == false)")
            
            // Convert to SwiftData model
            let sdRecipe = SDRecipe(from: recipe)
            
            print("✅ Successfully converted to SDRecipe model")
            
            // Update UI on main actor
            await MainActor.run {
                fetchedRecipe = sdRecipe
                self.id = recipe.id
                isLoading = false
                searchSuccess = true
                errorMessage = nil
                print("🎉 Complete recipe fetch completed successfully!")
                
                // Clear all selections after successful recipe fetch
                clearAllSelections()
                print("🧹 Cleared all selections after successful recipe fetch")
            }
            
        } catch let decodingError as DecodingError {
            print("❌ JSON Decoding Error: \(decodingError)")
            
            let decodingMessage: String
            switch decodingError {
            case .dataCorrupted:
                decodingMessage = "Corrupted data received from server"
            case .keyNotFound(let key, _):
                decodingMessage = "Missing required field: \(key.stringValue)"
            case .typeMismatch(let type, _):
                decodingMessage = "Invalid data type received: expected \(type)"
            case .valueNotFound(let type, _):
                decodingMessage = "Missing required value of type: \(type)"
            @unknown default:
                decodingMessage = "Failed to parse server response"
            }
            
            await MainActor.run {
                isLoading = false
                errorMessage = decodingMessage
            }
            
        } catch let urlError as URLError {
            print("❌ Network Error: \(urlError)")
            
            let networkMessage: String
            switch urlError.code {
            case .notConnectedToInternet:
                networkMessage = "No internet connection. Please check your network settings."
            case .timedOut:
                networkMessage = "Request timed out. Please try again."
            case .cannotFindHost:
                networkMessage = "Cannot reach server. Please check your connection."
            case .networkConnectionLost:
                networkMessage = "Network connection lost. Please try again."
            case .dnsLookupFailed:
                networkMessage = "DNS lookup failed. Please check your internet connection."
            default:
                networkMessage = "Network error occurred. Please try again."
            }
            
            await MainActor.run {
                isLoading = false
                errorMessage = networkMessage
            }
            
        } catch {
            print("❌ Unexpected Error: \(error)")
            print("❌ Error Type: \(type(of: error))")
            print("❌ Error Description: \(error.localizedDescription)")
            
            await MainActor.run {
                isLoading = false
                errorMessage = "An unexpected error occurred. Please try again."
            }
        }
    }
    
    // MARK: - Find Recipes by Ingredients (Simplified)
    
    /// Searches for recipe IDs using ingredients from products
    /// Returns only recipe IDs and basic info - full details fetched separately when needed
    /// - Parameter ingredients: Array of ingredient names to search for
    func findRecipeIdsByIngredients(ingredients: [String]) async {
        // Prevent duplicate calls if already loading
        if isLoading {
            print("⚠️ Already loading recipes, skipping duplicate call")
            return
        }
        
        // Set initial loading state
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            ingredientsSearchSuccess = false
            foundRecipeIds = []
            foundRecipeSummaries = []
        }
        
        print("🔍 Searching for recipe IDs with ingredients: \(ingredients)")
        
        do {
            // Get and validate API key
            guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
                print("❌ Error: API key is nil or empty")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "API key not configured. Please check your configuration."
                }
                return
            }
            
            print("✅ API key retrieved successfully")
            
            // Build URL with query parameters
            guard var urlComponents = URLComponents(string: "https://api.spoonacular.com/recipes/findByIngredients") else {
                print("❌ Error: Failed to create URL components")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid API URL configuration"
                }
                return
            }
            
            // Join ingredients with commas as required by the API
            let ingredientsString = ingredients.joined(separator: ",")
            
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "apiKey", value: apiKey),
                URLQueryItem(name: "ingredients", value: ingredientsString),
                URLQueryItem(name: "number", value: "3"), // Limit to 3 recipes as requested
                URLQueryItem(name: "ignorePantry", value: "true") // Ignore pantry items as requested
            ]
            
            urlComponents.queryItems = queryItems
            
            guard let url = urlComponents.url else {
                print("❌ Error: Failed to create final URL")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to construct API request URL"
                }
                return
            }
            
            print("🌐 Making request to: \(url.absoluteString)")
            
            // Make API request
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Error: Invalid response type")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid server response"
                }
                return
            }
            
            print("📡 Response status code: \(httpResponse.statusCode)")
            
            // Handle HTTP error status codes
            switch httpResponse.statusCode {
            case 200...299:
                print("✅ Successful response")
            case 401:
                print("❌ Unauthorized: Invalid API key")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid API key. Please check your configuration."
                }
                return
            case 402:
                print("❌ Payment required: API quota exceeded")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "API quota exceeded. Please try again later."
                }
                return
            case 403:
                print("❌ Forbidden: Access denied")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Access denied. Please check your API permissions."
                }
                return
            case 404:
                print("❌ Not found: Invalid endpoint")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "API endpoint not found. Please try again."
                }
                return
            case 429:
                print("❌ Too many requests: Rate limit exceeded")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Rate limit exceeded. Please wait before trying again."
                }
                return
            case 500...599:
                print("❌ Server error: \(httpResponse.statusCode)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Server error. Please try again later."
                }
                return
            default:
                print("❌ Unexpected status code: \(httpResponse.statusCode)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Unexpected error occurred. Please try again."
                }
                return
            }
            
            print("📦 Received data size: \(data.count) bytes")
            
            // Validate data is not empty
            guard !data.isEmpty else {
                print("❌ Error: Empty response data")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Empty response from server"
                }
                return
            }
            
            // Parse JSON response - the findByIngredients endpoint returns an array of FindByIngredientsRecipe
            let decoder = JSONDecoder()
            let recipes = try decoder.decode([FindByIngredientsRecipe].self, from: data)
            
            print("✅ Successfully decoded API response")
            print("🍽️ Found \(recipes.count) recipes")
            
            // Extract recipe IDs and basic info
            let recipeIds = recipes.map { $0.id }
            
            // Update UI on main actor
            await MainActor.run {
                foundRecipeIds = recipeIds
                foundRecipeSummaries = recipes
                isLoading = false
                ingredientsSearchSuccess = true
                errorMessage = nil
                print("🎉 Recipe ID search completed successfully!")
                print("📋 Recipe IDs: \(recipeIds)")
            }
            
        } catch let decodingError as DecodingError {
            print("❌ JSON Decoding Error: \(decodingError)")
            
            // Provide more specific decoding error messages
            let decodingMessage: String
            switch decodingError {
            case .dataCorrupted:
                decodingMessage = "Corrupted data received from server"
            case .keyNotFound(let key, _):
                decodingMessage = "Missing required field: \(key.stringValue)"
            case .typeMismatch(let type, _):
                decodingMessage = "Invalid data type received: expected \(type)"
            case .valueNotFound(let type, _):
                decodingMessage = "Missing required value of type: \(type)"
            @unknown default:
                decodingMessage = "Failed to parse server response"
            }
            
            await MainActor.run {
                isLoading = false
                errorMessage = decodingMessage
            }
            
        } catch let urlError as URLError {
            print("❌ Network Error: \(urlError)")
            print("❌ Network Error Code: \(urlError.code.rawValue)")
            
            // Provide user-friendly network error messages
            let networkMessage: String
            switch urlError.code {
            case .notConnectedToInternet:
                networkMessage = "No internet connection. Please check your network settings."
            case .timedOut:
                networkMessage = "Request timed out. Please try again."
            case .cannotFindHost:
                networkMessage = "Cannot reach server. Please check your connection."
            case .networkConnectionLost:
                networkMessage = "Network connection lost. Please try again."
            case .dnsLookupFailed:
                networkMessage = "DNS lookup failed. Please check your internet connection."
            default:
                networkMessage = "Network error occurred. Please try again."
            }
            
            await MainActor.run {
                isLoading = false
                errorMessage = networkMessage
            }
            
        } catch {
            print("❌ Unexpected Error: \(error)")
            print("❌ Error Type: \(type(of: error))")
            print("❌ Error Description: \(error.localizedDescription)")
            
            await MainActor.run {
                isLoading = false
                errorMessage = "An unexpected error occurred. Please try again."
            }
        }
    }
    
    /// Searches for recipe IDs using ingredients from a list of products
    /// - Parameter products: Array of Product objects to extract ingredients from
    func findRecipeIdsFromProducts(products: [Product]) async {
        // Extract ingredients from products
        var ingredients: [String] = []
        
        for product in products {
            // Use breadcrumbs if available, otherwise use title
            if let breadcrumbs = product.breadcrumbs, !breadcrumbs.isEmpty {
                ingredients.append(contentsOf: breadcrumbs)
            } else {
                // Fallback to using the product title as an ingredient
                ingredients.append(product.title)
            }
        }
        
        // Remove duplicates and filter out empty strings
        let uniqueIngredients = Array(Set(ingredients.filter { !$0.isEmpty }))
        
        print("🥘 Extracted ingredients from products: \(uniqueIngredients)")
        
        // Search for recipe IDs with these ingredients
        await findRecipeIdsByIngredients(ingredients: uniqueIngredients)
    }
    
    /// Clears the found recipe IDs and resets search state
    func clearFoundRecipeIds() {
        foundRecipeIds = []
        foundRecipeSummaries = []
        ingredientsSearchSuccess = false
        errorMessage = nil
    }
    
    /// Fetches full recipe details for a specific recipe ID
    /// Call this only when user wants to see full details
    /// - Parameter recipeId: The ID of the recipe to fetch full details for
    func fetchFullRecipeDetails(recipeId: Int) async {
        print("🔍 Fetching full details for recipe ID: \(recipeId)")
        
        // Use the existing fetchCompleteRecipeById function
        await fetchCompleteRecipeById(id: recipeId)
    }
}

