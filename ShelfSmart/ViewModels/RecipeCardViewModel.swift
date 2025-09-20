//
//  RecipeCardViewModel.swift
//  ShelfSmart
//
//  Created by AI Assistant on 9/18/25.
//

import Foundation
import SwiftUI

@Observable
class RecipeCardViewModel {
    // MARK: - State
    var isLoading = false
    var errorMessage: String?
    var recipes: [Recipe] = []
    var loadedRecipeIds: Set<Int> = []
    
    // MARK: - Computed Properties
    var hasRecipes: Bool {
        return !recipes.isEmpty
    }
    
    var loadingCount: Int {
        return loadedRecipeIds.count
    }
    
    // MARK: - API Methods
    
    /// Fetches recipe details for a single recipe ID
    func fetchRecipeDetails(recipeId: Int) async -> Recipe? {
        // Check if we already have this recipe
        if loadedRecipeIds.contains(recipeId) {
            return recipes.first { $0.id == recipeId }
        }
        
        do {
            guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
                await setError("API key not configured. Please check your configuration.")
                return nil
            }
            
            guard let url = buildRecipeInfoURL(id: recipeId, apiKey: apiKey) else {
                await setError("Failed to construct API request URL")
                return nil
            }
            
            print("🌐 Fetching recipe details for ID: \(recipeId)")
            
            let (data, _) = try await makeAPIRequest(url: url)
            
            // Parse recipe details
            let recipe = try JSONDecoder().decode(Recipe.self, from: data)
            
            print("✅ Successfully fetched recipe: \(recipe.title)")
            
            // Store the recipe
            await MainActor.run {
                if !loadedRecipeIds.contains(recipeId) {
                    recipes.append(recipe)
                    loadedRecipeIds.insert(recipeId)
                    print("✅ Recipe loaded: \(recipe.title)")
                }
            }
            
            return recipe
            
        } catch {
            print("❌ Error fetching recipe \(recipeId): \(error)")
            await setError("Failed to load recipe details")
            return nil
        }
    }
    
    /// Fetches recipe details for multiple recipe IDs
    func fetchMultipleRecipeDetails(recipeIds: [Int]) async {
        guard !isLoading else { return }
        
        await setLoadingState(true)
        
        print("🔍 Fetching details for \(recipeIds.count) recipes")
        
        // Filter out already loaded recipes
        let newRecipeIds = recipeIds.filter { !loadedRecipeIds.contains($0) }
        
        if newRecipeIds.isEmpty {
            await setLoadingState(false)
            return
        }
        
        // Fetch recipes concurrently
        await withTaskGroup(of: Recipe?.self) { group in
            for recipeId in newRecipeIds {
                group.addTask {
                    await self.fetchRecipeDetails(recipeId: recipeId)
                }
            }
            
            for await recipe in group {
                // Recipes are already stored in fetchRecipeDetails
                if recipe != nil {
                    print("✅ Recipe loaded: \(recipe?.title ?? "Unknown")")
                }
            }
        }
        
        await setLoadingState(false)
    }
    
    /// Gets recipe by ID from loaded recipes
    func getRecipe(by id: Int) -> Recipe? {
        return recipes.first { $0.id == id }
    }
    
    
    /// Clears all loaded recipes
    func clearRecipes() {
        recipes.removeAll()
        loadedRecipeIds.removeAll()
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
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
            }
        }
    }
    
    /// Sets error message and stops loading
    private func setError(_ message: String) async {
        await MainActor.run {
            isLoading = false
            errorMessage = message
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
}
