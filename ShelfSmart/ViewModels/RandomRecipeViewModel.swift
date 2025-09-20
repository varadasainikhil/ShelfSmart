//
//  RandomRecipeViewModel.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/16/25.
//

import Foundation
import SwiftData

// MARK: - API Response Models
struct RandomRecipeResponse: Codable {
    let recipes: [Recipe]
}

@Observable
class RandomRecipeViewModel {
    // MARK: - Selection State
    var selectedMealTypes: [String] = []
    var selectedCuisines: [String] = []
    var selectedDiets: [String] = []
    var selectedIntolerances: [String] = []
    
    // MARK: - UI State
    var isLoading = false
    var errorMessage: String?
    var searchSuccess = false
    
    // MARK: - Recipe Data (Raw API Response - NOT SwiftData models)
    var currentRecipeId: Int?
    var currentRecipe: Recipe? // Raw API response
    var currentRecipeSummary: FindByIngredientsRecipe? // For ingredient-based searches
    
    // MARK: - Ingredient Search Results
    var foundRecipeIds: [Int] = []
    var foundRecipeSummaries: [FindByIngredientsRecipe] = []
    var ingredientsSearchSuccess = false
    
    // MARK: - Computed Properties
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
    
    /// Gets API key from Info.plist
    private func getAPIKey() -> String? {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let apiKey = plist["API_KEY"] as? String else {
            return nil
        }
        return apiKey
    }
    
    /// Sets loading state and clears previous errors
    private func setLoadingState(_ loading: Bool) async {
        await MainActor.run {
            isLoading = loading
            if loading {
                errorMessage = nil
                searchSuccess = false
            }
        }
    }
    
    /// Sets error message and stops loading
    private func setError(_ message: String) async {
        await MainActor.run {
            isLoading = false
            errorMessage = message
            searchSuccess = false
        }
    }
    
    /// Handles HTTP response status codes
    private func handleHTTPResponse(_ response: HTTPURLResponse) async -> Bool {
        switch response.statusCode {
        case 200...299:
            return true
        case 401:
            await setError("Invalid API key. Please check your configuration.")
        case 402:
            await setError("API quota exceeded. Please try again later.")
        case 403:
            await setError("Access denied. Please check your API permissions.")
        case 404:
            await setError("API endpoint not found. Please try again.")
        case 429:
            await setError("Rate limit exceeded. Please wait before trying again.")
        case 500...599:
            await setError("Server error. Please try again later.")
        default:
            await setError("Unexpected error occurred. Please try again.")
        }
        return false
    }
    
    /// Makes API request with error handling
    private func makeAPIRequest(url: URL) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard await handleHTTPResponse(httpResponse) else {
            throw URLError(.badServerResponse)
        }
        
        return (data, httpResponse)
    }
    
    // MARK: - Recipe Fetching Methods
    
    /// Fetches a completely random recipe
    func completelyRandomRecipe() async {
        guard !isLoading else {
            print("⚠️ Already loading recipe, skipping duplicate call")
            return
        }
        
        await setLoadingState(true)
        print("🔍 Searching for random recipe")
        
        do {
            guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
                await setError("API key not configured. Please check your configuration.")
                return
            }
            
            guard let url = buildRandomRecipeURL(apiKey: apiKey) else {
                await setError("Failed to construct API request URL")
                return
            }
            
            print("🌐 Making request to: \(url.absoluteString)")
            
            let (data, _) = try await makeAPIRequest(url: url)
            
            // Parse and validate response
            let apiResponse = try JSONDecoder().decode(RandomRecipeResponse.self, from: data)
            
            guard let recipe = apiResponse.recipes.first else {
                await setError("No recipes found matching your criteria. Please try different filters.")
                return
            }
            
            // Store raw recipe data (NO SwiftData conversion yet)
            await MainActor.run {
                currentRecipe = recipe
                currentRecipeId = recipe.id
                isLoading = false
                searchSuccess = true
                errorMessage = nil
                print("🎉 Recipe fetch completed successfully!")
            }
            
        } catch {
            await handleError(error)
        }
    }
    
    /// Builds URL for random recipe API call
    private func buildRandomRecipeURL(apiKey: String) -> URL? {
        guard var urlComponents = URLComponents(string: "https://api.spoonacular.com/recipes/random") else {
            return nil
        }
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "number", value: "1")
        ]
        
        // Add filters if any are selected
        if hasAnySelections {
            let tagsString = allSelectedTags.joined(separator: ",")
            queryItems.append(URLQueryItem(name: "include-tags", value: tagsString))
            print("🏷️ Including tags: \(tagsString)")
        }
        
        urlComponents.queryItems = queryItems
        return urlComponents.url
    }
    
    /// Handles errors with user-friendly messages
    private func handleError(_ error: Error) async {
        print("❌ Error: \(error)")
        
        let errorMessage: String
        if let urlError = error as? URLError {
            errorMessage = getNetworkErrorMessage(for: urlError)
        } else if let decodingError = error as? DecodingError {
            errorMessage = getDecodingErrorMessage(for: decodingError)
        } else {
            errorMessage = "An unexpected error occurred. Please try again."
        }
        
        await setError(errorMessage)
    }
    
    /// Provides user-friendly network error messages
    private func getNetworkErrorMessage(for error: URLError) -> String {
        switch error.code {
        case .notConnectedToInternet:
            return "No internet connection. Please check your network settings."
        case .timedOut:
            return "Request timed out. Please try again."
        case .cannotFindHost:
            return "Cannot reach server. Please check your connection."
        case .networkConnectionLost:
            return "Network connection lost. Please try again."
        case .dnsLookupFailed:
            return "DNS lookup failed. Please check your internet connection."
        default:
            return "Network error occurred. Please try again."
        }
    }
    
    /// Provides user-friendly decoding error messages
    private func getDecodingErrorMessage(for error: DecodingError) -> String {
        switch error {
        case .dataCorrupted:
            return "Corrupted data received from server"
        case .keyNotFound(let key, _):
            return "Missing required field: \(key.stringValue)"
        case .typeMismatch(let type, _):
            return "Invalid data type received: expected \(type)"
        case .valueNotFound(let type, _):
            return "Missing required value of type: \(type)"
        @unknown default:
            return "Failed to parse server response"
        }
    }
    
    // MARK: - Recipe Management
    
    /// Clears the currently fetched recipe and resets search state
    func clearCurrentRecipe() {
        currentRecipe = nil
        currentRecipeId = nil
        currentRecipeSummary = nil
        searchSuccess = false
        errorMessage = nil
    }
    
    /// Creates and saves SDRecipe model to SwiftData context (ONLY when user wants to save)
    func saveCurrentRecipe(to modelContext: ModelContext) -> Bool {
        guard let recipe = currentRecipe else {
            errorMessage = "No recipe to save"
            return false
        }
        
        do {
            // Convert to SwiftData model ONLY when saving
            let sdRecipe = SDRecipe(from: recipe)
            modelContext.insert(sdRecipe)
            try modelContext.save()
            print("✅ Recipe saved to SwiftData successfully")
            return true
        } catch {
            print("❌ Failed to save recipe: \(error)")
            errorMessage = "Failed to save recipe: \(error.localizedDescription)"
            return false
        }
    }
    
    /// Creates SDRecipe model from current recipe (for preview/saving later)
    func createSDRecipeFromCurrent() -> SDRecipe? {
        guard let recipe = currentRecipe else { return nil }
        return SDRecipe(from: recipe)
    }
    
    /// Fetches a custom random recipe based on user-selected filters
    func customRandomRecipe() async {
        guard !isLoading else {
            print("⚠️ Already loading recipe, skipping duplicate call")
            return
        }
        
        await setLoadingState(true)
        print("🔍 Searching for custom random recipe with filters:")
        print("   Meal Types: \(selectedMealTypes)")
        print("   Cuisines: \(selectedCuisines)")
        print("   Diets: \(selectedDiets)")
        print("   Intolerances: \(selectedIntolerances)")
        
        do {
            guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
                await setError("API key not configured. Please check your configuration.")
                return
            }
            
            guard let url = buildComplexSearchURL(apiKey: apiKey) else {
                await setError("Failed to construct API request URL")
                return
            }
            
            print("🌐 Making request to: \(url.absoluteString)")
            
            let (data, _) = try await makeAPIRequest(url: url)
            
            // Parse search results
            let searchResponse = try JSONDecoder().decode(ComplexSearchRecipeResponse.self, from: data)
            
            guard let searchResult = searchResponse.results.first, searchResult.id > 0 else {
                await setError("No recipes found matching your criteria. Please try different filters.")
                return
            }
            
            print("✅ Found recipe: \(searchResult.title) (ID: \(searchResult.id))")
            
            // Fetch complete recipe details
            await fetchCompleteRecipeById(id: searchResult.id)
            
        } catch {
            await handleError(error)
        }
    }
    
    /// Builds URL for complex search API call
    private func buildComplexSearchURL(apiKey: String) -> URL? {
        guard var urlComponents = URLComponents(string: "https://api.spoonacular.com/recipes/complexSearch") else {
            return nil
        }
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "number", value: "1"),
            URLQueryItem(name: "sort", value: "random")
        ]
        
        // Add filters
        if !selectedMealTypes.isEmpty {
            queryItems.append(URLQueryItem(name: "type", value: selectedMealTypes.joined(separator: ",")))
        }
        if !selectedCuisines.isEmpty {
            queryItems.append(URLQueryItem(name: "cuisine", value: selectedCuisines.joined(separator: ",")))
        }
        if !selectedDiets.isEmpty {
            queryItems.append(URLQueryItem(name: "diet", value: selectedDiets.joined(separator: ",")))
        }
        if !selectedIntolerances.isEmpty {
            queryItems.append(URLQueryItem(name: "excludeIngredients", value: selectedIntolerances.joined(separator: ",")))
        }
        
        urlComponents.queryItems = queryItems
        return urlComponents.url
    }
    
    /// Fetches complete recipe details by ID from Spoonacular API
    private func fetchCompleteRecipeById(id: Int) async {
        print("🔍 Fetching complete recipe details for ID: \(id)")
        
        do {
            guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
                await setError("API key not configured. Please check your configuration.")
                return
            }
            
            guard let url = buildRecipeInfoURL(id: id, apiKey: apiKey) else {
                await setError("Failed to construct API request URL")
                return
            }
            
            print("🌐 Making request to: \(url.absoluteString)")
            
            let (data, _) = try await makeAPIRequest(url: url)
            
            // Parse recipe details
            let recipe = try JSONDecoder().decode(Recipe.self, from: data)
            
            print("✅ Successfully decoded complete recipe: \(recipe.title)")
            print("🥘 Ingredients count: \(recipe.extendedIngredients?.count ?? 0)")
            
            // Store raw recipe data (NO SwiftData conversion yet)
            await MainActor.run {
                currentRecipe = recipe
                currentRecipeId = recipe.id
                isLoading = false
                searchSuccess = true
                errorMessage = nil
                print("🎉 Complete recipe fetch completed successfully!")
            }
            
        } catch {
            await handleError(error)
        }
    }
    
    /// Builds URL for recipe information API call
    private func buildRecipeInfoURL(id: Int, apiKey: String) -> URL? {
        guard var urlComponents = URLComponents(string: "https://api.spoonacular.com/recipes/\(id)/information") else {
            return nil
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "includeNutrition", value: "false")
        ]
        
        return urlComponents.url
    }
    
    // MARK: - Ingredient Search Methods
    
    /// Searches for recipe IDs using ingredients from products
    func findRecipeIdsByIngredients(ingredients: [String]) async {
        guard !isLoading else {
            print("⚠️ Already loading recipes, skipping duplicate call")
            return
        }
        
        await setLoadingState(true)
        foundRecipeIds = []
        foundRecipeSummaries = []
        
        print("🔍 Searching for recipe IDs with ingredients: \(ingredients)")
        
        do {
            guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
                await setError("API key not configured. Please check your configuration.")
                return
            }
            
            guard let url = buildIngredientSearchURL(ingredients: ingredients, apiKey: apiKey) else {
                await setError("Failed to construct API request URL")
                return
            }
            
            print("🌐 Making request to: \(url.absoluteString)")
            
            let (data, _) = try await makeAPIRequest(url: url)
            
            // Parse ingredient search results
            let recipes = try JSONDecoder().decode([FindByIngredientsRecipe].self, from: data)
            
            print("✅ Found \(recipes.count) recipes")
            
            // Update UI on main actor
            await MainActor.run {
                foundRecipeIds = recipes.map { $0.id }
                foundRecipeSummaries = recipes
                isLoading = false
                ingredientsSearchSuccess = true
                errorMessage = nil
                print("🎉 Recipe ID search completed successfully!")
            }
            
        } catch {
            await handleError(error)
        }
    }
    
    /// Builds URL for ingredient search API call
    private func buildIngredientSearchURL(ingredients: [String], apiKey: String) -> URL? {
        guard var urlComponents = URLComponents(string: "https://api.spoonacular.com/recipes/findByIngredients") else {
            return nil
        }
        
        let ingredientsString = ingredients.joined(separator: ",")
        
        urlComponents.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "ingredients", value: ingredientsString),
            URLQueryItem(name: "number", value: "4"),
            URLQueryItem(name: "ignorePantry", value: "true")
        ]
        
        return urlComponents.url
    }
    
    /// Searches for recipe IDs using ingredients from a list of products
    func findRecipeIdsFromProducts(products: [Product]) async {
        // Extract ingredients from products
        var ingredients: [String] = []
        
        for product in products {
            if let breadcrumbs = product.breadcrumbs, !breadcrumbs.isEmpty {
                ingredients.append(contentsOf: breadcrumbs)
            } else {
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
    func fetchFullRecipeDetails(recipeId: Int) async {
        print("🔍 Fetching full details for recipe ID: \(recipeId)")
        await fetchCompleteRecipeById(id: recipeId)
    }
}

