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
    var includeTags : [String] = [String]()
    var isLoading = false
    var errorMessage : String?
    var searchSuccess = false
    var id : Int?
    var fetchedRecipe: SDRecipe?
    
    func addCuisine (cuisine : Cuisine){
        includeTags.append(cuisine.apiValue)
    }
    
    func removeCuisine (cuisine : Cuisine){
        includeTags.removeAll(where: {$0 == cuisine.apiValue})
    }
    
    func addDiet (diet : Diet){
        includeTags.append(diet.apiValue)
    }
    
    func removeDiet (diet : Diet){
        includeTags.removeAll(where: {$0 == diet.apiValue})
    }
    
    func addIntolerance (intolerance : Intolerances){
        includeTags.append(intolerance.apiValue)
    }
    
    func removeIntolerance (intolerance : Intolerances){
        includeTags.removeAll(where: {$0 == intolerance.apiValue})
    }
    
    func addMealType (mealType : MealType ){
        includeTags.append(mealType.apiValue)
    }
    
    func removeMealType (mealType : MealType){
        includeTags.removeAll(where: {$0 == mealType.apiValue})
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
            
            // Add include tags if any are selected
            if !includeTags.isEmpty {
                let tagsString = includeTags.joined(separator: ",")
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
}

