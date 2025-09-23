//
//  AddProductViewViewModel.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/26/25.
//

import FirebaseAuth
import Foundation
import SwiftData

// Model for API error responses
struct APIErrorResponse: Codable {
    let status: String
    let message: String
}

@Observable
class AddProductViewViewModel {
    var barcode : String = ""
    var name : String = ""
    var productDescription : String = ""
    var imageLink : String = ""
    var recipes : [SDRecipe] = [SDRecipe]()
    var expirationDate : Date = Calendar.current.date(byAdding: .day, value: 7, to: Date.now) ?? Date.now {
        didSet {
            print("🗓️ ExpirationDate changed to: \(expirationDate)")
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.timeStyle = .medium
            print("🗓️ Formatted new expiration date: \(formatter.string(from: expirationDate))")
        }
    }
    var isLoading : Bool = false
    var isSaving : Bool = false
    var errorMessage : String?
    var searchSuccess : Bool = false
    var searchAttempted : Bool = false
    var apiResponse : GroceryProduct? = nil
    
    // Store the groceryProduct - created when saving the product
    var groceryProduct : GroceryProduct? = nil
    
    var isSearchButtonDisabled : Bool {
        return barcode.isEmpty || isLoading
    }

    var isSaveButtonDisabled : Bool {
        return isSaving || isLoading || (name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !searchSuccess)
    }
    
    // Helper function to get current groceryProduct
    func getCurrentGroceryProduct() -> GroceryProduct? {
        return groceryProduct
    }
    
    // Helper function to clear groceryProduct
    func clearGroceryProduct() {
        groceryProduct = nil
        print("🗑️ Cleared groceryProduct")
    }
    
    // Reset all fields to initial state for clean sheet
    func resetAllFields() {
        barcode = ""
        name = ""
        productDescription = ""
        imageLink = ""
        expirationDate = Calendar.current.date(byAdding: .day, value: 7, to: Date.now) ?? Date.now
        isLoading = false
        isSaving = false
        errorMessage = nil
        searchSuccess = false
        searchAttempted = false
        apiResponse = nil
        groceryProduct = nil
        self.recipes = [SDRecipe]()
        print("🔄 Reset all fields to initial state - clean sheet ready")
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
    
    func searchProduct(modelContext: ModelContext) async throws {
        // Reset state
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            searchSuccess = false
            searchAttempted = true
            imageLink = ""
        }
        
        print("Searching for barcode: \(barcode)")
        let apiKey = getAPIKey()
        
        // Validate API key
        guard let validApiKey = apiKey, !validApiKey.isEmpty else {
            print("❌ Error: API key is nil or empty")
            await MainActor.run {
                isLoading = false
                errorMessage = "API key not configured"
            }
            return
        }
        
        print("✅ API key retrieved successfully")
        
        guard var urlComponents = URLComponents(string:"https://api.spoonacular.com/food/products/upc/\(barcode)") else {
            print("❌ Error: Failed to create URL components")
            throw URLError(.badURL)
        }
        
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "apiKey", value: apiKey)
        ]
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            print("❌ Error: Failed to create final URL")
            throw URLError(.badURL)
        }
        
        print("🌐 Making request to: \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Log response details
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Response status code: \(httpResponse.statusCode)")
                
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
                    print("❌ Not found: Invalid endpoint or product not found")
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "Product not found for this barcode."
                        self.barcode = ""
                    }
                    return
                default:
                    print("❌ Unexpected status code: \(httpResponse.statusCode)")
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "An unexpected error occurred. Please try again."
                    }
                    return
                }
            }
            
            print("📦 Received data size: \(data.count) bytes")
            
            // Log the raw JSON response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON Response: \(jsonString)")
            }
            
            let decoder = JSONDecoder()
            
            // If not an error, try to decode as a product
            let apiResponse = try decoder.decode(GroceryProduct.self, from: data)
            
            print("✅ Successfully decoded response")
            print("📦 Product ID: \(String(describing: apiResponse.id))")
            print("📦 Product Title: \(String(describing: apiResponse.title))")
            print("📦 Product UPC: \(String(describing: apiResponse.upc))")
            print("📦 Product Brand: \(String(describing: apiResponse.brand))")
            print("🖼️ API Response image: \(String(describing: apiResponse.image))")
            print("🖼️ API Response images: \(String(describing: apiResponse.images))")
            print("💳 Credits available: \(apiResponse.credits != nil)")
            print("BreadCrumbs : \(String(describing: apiResponse.breadcrumbs))")
            // Check if we have essential data to create a product
            let productTitle = apiResponse.title ?? ""
            let productUpc = apiResponse.upc ?? ""
            let productId = apiResponse.id
            
            // Validate that we have a meaningful product response
            // A valid product should have either a non-empty title or a valid ID
            let hasValidTitle = !productTitle.isEmpty && productTitle != "Unknown Product"
            let hasValidId = productId != nil && productId != 0
            let hasValidUPC = !productUpc.isEmpty
            
            if hasValidTitle || hasValidId || hasValidUPC {
                // Update UI with found product data
                await MainActor.run {
                    self.name = productTitle.isEmpty ? "Unknown Product" : productTitle
                    self.productDescription = apiResponse.description ?? ""
                    self.imageLink = apiResponse.image ?? ""
                    self.searchSuccess = true
                    self.isLoading = false
                    self.errorMessage = nil // Clear any previous errors
                }
                
                // Store the API response for later use when user saves
                await MainActor.run {
                    self.apiResponse = apiResponse
                    print("✅ API product data loaded successfully - ready for user to save")
                }
                
            } else {
                print("⚠️ No valid product data found in response")
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "No product found for this barcode. Please try a different barcode or enter details manually."
                    self.searchSuccess = false
                    self.barcode = "" // Clear barcode so user can enter/scan a new one
                    self.name = "" // Clear name field
                    self.productDescription = "" // Clear description field
                    self.imageLink = "" // Clear image link
                    self.apiResponse = nil // Clear API response
                }
            }
            
        } catch let decodingError as DecodingError {
            print("❌ JSON Decoding Error: \(decodingError)")
            print("❌ Decoding Error Details: \(decodingError.localizedDescription)")
            
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "No product found for this barcode. Please try a different barcode or enter details manually."
                self.searchSuccess = false
                self.barcode = "" // Clear barcode so user can enter/scan a new one
                self.name = "" // Clear name field
                self.productDescription = "" // Clear description field
                self.imageLink = "" // Clear image link
                self.apiResponse = nil // Clear API response
            }
        } catch let urlError as URLError {
            print("❌ Network Error: \(urlError)")
            print("❌ Network Error Code: \(urlError.code.rawValue)")
            print("❌ Network Error Description: \(urlError.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Network error: \(urlError.localizedDescription)"
                self.searchSuccess = false
                self.barcode = "" // Clear barcode so user can enter/scan a new one
                self.name = "" // Clear name field
                self.productDescription = "" // Clear description field
                self.imageLink = "" // Clear image link
                self.apiResponse = nil // Clear API response
            }
        } catch {
            print("❌ Unknown Error: \(error)")
            print("❌ Error Type: \(type(of: error))")
            print("❌ Error Description: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Unexpected error: \(error.localizedDescription)"
                self.searchSuccess = false
                self.barcode = "" // Clear barcode so user can enter/scan a new one
                self.name = "" // Clear name field
                self.productDescription = "" // Clear description field
                self.imageLink = "" // Clear image link
                self.apiResponse = nil // Clear API response
            }
        }
    }
    
    @MainActor
    func createProductFromAPIResponse(apiResponse : GroceryProduct, modelContext : ModelContext ) async {
        // Set saving state and reset any previous error messages
        isSaving = true
        errorMessage = nil
        
        // Capture the expiration date before any potential reset
        let userSelectedExpirationDate = self.expirationDate
        print("📦 API Product - User selected expiration date: \(userSelectedExpirationDate)")
        
        // Create groceryProduct from API response
        self.groceryProduct = apiResponse
        print("📦 Created groceryProduct from API response: \(String(describing: apiResponse.title))")
        
        // Handle optional credits
        let credit: Credit
        if let apiCredits = apiResponse.credits {
            credit = Credit(text: apiCredits.text, link: apiCredits.link, image: apiCredits.image, imageLink: apiCredits.imageLink)
        } else {
            // Provide default credits when API doesn't include them
            credit = Credit(text: "Product information provided by Spoonacular", link: "https://spoonacular.com", image: "Spoonacular", imageLink: "https://spoonacular.com")
        }
        
        // Use fallback values for essential fields
        let productTitle = apiResponse.title ?? "Unknown Product"
        let productBarcode = apiResponse.upc ?? self.barcode
        
        // Search for recipes using this product's ingredients and save product
        await searchAndSaveRecipesForProduct(apiResponse: apiResponse, modelContext: modelContext, credit: credit, productTitle: productTitle, productBarcode: productBarcode, userExpirationDate: userSelectedExpirationDate)
    }
    
    /// Searches for recipes and creates the product with recipe IDs
    @MainActor
    private func searchAndSaveRecipesForProduct(apiResponse: GroceryProduct, modelContext: ModelContext, credit: Credit, productTitle: String, productBarcode: String, userExpirationDate: Date) async {
        // Extract ingredients for recipe search
        var ingredients: [String] = []
        
        // Use breadcrumbs if available, otherwise use title
        if let breadcrumbs = apiResponse.breadcrumbs, !breadcrumbs.isEmpty {
            ingredients.append(contentsOf: breadcrumbs)
        } else {
            // Fallback to using the product title as an ingredient
            ingredients.append(productTitle)
        }
        
        // Remove duplicates and filter out empty strings
        let uniqueIngredients = Array(Set(ingredients.filter { !$0.isEmpty }))
        
        print("🥘 Searching for recipes with ingredients: \(uniqueIngredients)")
        
        // Search for recipe IDs
        let recipeIds = await searchForRecipeIds(ingredients: uniqueIngredients)
        
        // Search for recipe using recipeId
        await self.searchRecipeByID(recipeIds: recipeIds ?? [Int]())
        
        
        // Create product with recipe IDs using the user-selected expiration date
        let product = Product(id: apiResponse.id, manualId: nil, barcode: productBarcode, title: productTitle, brand: apiResponse.brand ?? "",breadcrumbs: apiResponse.breadcrumbs, badges: apiResponse.badges, importantBadges: apiResponse.importantBadges, spoonacularScore: apiResponse.spoonacularScore, productDescription: apiResponse.description, imageLink: apiResponse.image, moreImageLinks: apiResponse.images, generatedText: apiResponse.generatedText, ingredientCount: apiResponse.ingredientCount, recipeIds: recipeIds,recipes: self.recipes, credits: credit, expirationDate: userExpirationDate)
        
        print("Created a new Item")
        print("🖼️ Product imageLink set to: \(String(describing: product.imageLink))")
        print("BreadCrumbs : \(product.breadcrumbs ?? [])")
        print("🍽️ Recipe IDs found: \(recipeIds ?? [])")
        
        // Find the userId of the user
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Could not find the userID of the user"
            print("Could not find the userID of the user")
            return
        }
        
        do {
            // Use normalized date for comparison - ensure we use the exact date selected by user
            let normalizedDate = Calendar.current.startOfDay(for: userExpirationDate)
            print("🗓️ API Product - Original expiration date: \(userExpirationDate)")
            print("🗓️ API Product - Normalized date for grouping: \(normalizedDate)")
            
            // Use SwiftData predicate for more efficient querying
            let predicate = #Predicate<GroupedProducts> { group in
                group.expirationDate == normalizedDate &&
                group.userId == userId
            }
            
            let descriptor = FetchDescriptor<GroupedProducts>(predicate: predicate)
            let existingGroups = try modelContext.fetch(descriptor)
            
            // Check if we found any existing groups for this date and the userID
            if let existingGroup = existingGroups.first {
                // Add to existing group
                existingGroup.products?.append(product)
                print("Found existing group for date, adding item to it")
            } else {
                
                // Create new group
                let newGroupedProducts = GroupedProducts(expirationDate: normalizedDate, products: [product], userId : userId)
                
                modelContext.insert(newGroupedProducts)
                print("Created new group for date")
            }
            
            // Single save operation
            try modelContext.save()
            print("Successfully saved item to database")
            print("✅ API Product created: \(product.title)")
            
            // Clear error message on success
            self.errorMessage = nil
            self.isSaving = false

        } catch {
            print("Error creating item: \(error.localizedDescription)")
            self.errorMessage = "Failed to save product. Please try again."
            self.isSaving = false
        }
    }
    
    /// Searches for recipe IDs using ingredients
    /// - Parameter ingredients: Array of ingredient names to search for
    /// - Returns: Array of recipe IDs (up to 3)
    private func searchForRecipeIds(ingredients: [String]) async -> [Int]? {
        do {
            // Get and validate API key
            guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
                print("❌ Error: API key is nil or empty")
                return nil
            }
            
            // Build URL with query parameters
            guard var urlComponents = URLComponents(string: "https://api.spoonacular.com/recipes/findByIngredients") else {
                print("❌ Error: Failed to create URL components")
                return nil
            }
            
            // Join ingredients with commas as required by the API
            let ingredientsString = ingredients.joined(separator: ",")
            
            let queryItems: [URLQueryItem] = [
                URLQueryItem(name: "apiKey", value: apiKey),
                URLQueryItem(name: "ingredients", value: ingredientsString),
                URLQueryItem(name: "number", value: "4"), // Limit to 4 recipes as requested
                URLQueryItem(name: "ignorePantry", value: "true") // Ignore pantry items as requested
            ]
            
            urlComponents.queryItems = queryItems
            
            guard let url = urlComponents.url else {
                print("❌ Error: Failed to create final URL")
                return nil
            }
            
            print("🌐 Making recipe search request to: \(url.absoluteString)")
            
            // Make API request
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Error: Invalid response type")
                return nil
            }
            
            print("📡 Recipe search response status code: \(httpResponse.statusCode)")
            
            // Handle HTTP error status codes
            switch httpResponse.statusCode {
            case 200...299:
                print("✅ Recipe search successful")
            case 401:
                print("❌ Unauthorized: Invalid API key")
                return nil
            case 402:
                print("❌ Payment required: API quota exceeded")
                return nil
            case 403:
                print("❌ Forbidden: Access denied")
                return nil
            case 404:
                print("❌ Not found: Invalid endpoint")
                return nil
            case 429:
                print("❌ Too many requests: Rate limit exceeded")
                return nil
            case 500...599:
                print("❌ Server error: \(httpResponse.statusCode)")
                return nil
            default:
                print("❌ Unexpected status code: \(httpResponse.statusCode)")
                return nil
            }
            
            // Validate data is not empty
            guard !data.isEmpty else {
                print("❌ Error: Empty response data")
                return nil
            }
            
            // Parse JSON response
            let decoder = JSONDecoder()
            let recipes = try decoder.decode([FindByIngredientsRecipe].self, from: data)
            
            print("✅ Successfully decoded recipe search response")
            print("🍽️ Found \(recipes.count) recipes")
            
            // Extract recipe IDs
            let recipeIds = recipes.map { $0.id }
            print("📋 Recipe IDs: \(recipeIds)")
            
            return recipeIds
            
        } catch {
            print("❌ Error searching for recipes: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Function to create product manually (without API)
    @MainActor
    func createManualProduct(modelContext: ModelContext) async {
        // Set saving state and reset any previous error messages
        self.isSaving = true
        self.errorMessage = nil
        
        // Validate required fields - only name is required
        let productName = self.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let productDescription = self.productDescription
        let productBarcode = self.barcode
        let productExpirationDate = self.expirationDate
        
        guard !productName.isEmpty else {
            self.errorMessage = "Product name cannot be empty."
            self.isSaving = false
            return
        }
        
        // Create default credits for manual products
        let credit = Credit(text: "Manually added product", link: "", image: "User Added", imageLink: "")
        
        print("📝 Creating manual product directly")
        print("🗓️ User selected expiration date: \(productExpirationDate)")
        
        // Search for recipes using manual product ingredients
        let ingredients = productName.components(separatedBy: " ")
        
        // Search for recipes by ingredients using the name because it is a manual entry
        let recipeIds = await self.searchForRecipeIds(ingredients: ingredients)
        
        // Searching for recipes from recipeIds
        await self.searchRecipeByID(recipeIds: recipeIds ?? [Int]())
        
        // Create Product directly without unnecessary GroceryProduct intermediate step
        // For manual products: id=nil, manualId=UUID to differentiate from API products
        let product = Product(
            id: nil, // No Spoonacular ID for manual products
            manualId: UUID().uuidString, // Unique identifier for manual entries
            barcode: productBarcode,
            title: productName,
            brand: "",
            breadcrumbs: productName.components(separatedBy: " "),
            badges: nil,
            importantBadges: nil,
            spoonacularScore: nil,
            productDescription: productDescription.isEmpty ? nil : productDescription,
            imageLink: nil,
            moreImageLinks: nil,
            generatedText: nil,
            ingredientCount: nil,
            recipeIds: recipeIds,
            recipes: self.recipes,
            credits: credit,
            expirationDate: productExpirationDate
        )
            
        print("📝 Created manual product with expiration date: \(product.expirationDate)")
        
        // Find the userId of the user
        guard let userId = Auth.auth().currentUser?.uid else {
            self.errorMessage = "Could not find the userID of the user"
            self.isSaving = false
            print("Could not find the userID of the user")
            return
        }
            
        do {
            // Use normalized date for comparison - ensure we use the exact date selected by user
            let normalizedDate = Calendar.current.startOfDay(for: productExpirationDate)
            print("🗓️ Manual product - Original expiration date: \(productExpirationDate)")
            print("🗓️ Manual product - Normalized date for grouping: \(normalizedDate)")
                
                // Use SwiftData predicate for more efficient querying
                let predicate = #Predicate<GroupedProducts> { group in
                    group.expirationDate == normalizedDate &&
                    group.userId == userId
                }
                
                let descriptor = FetchDescriptor<GroupedProducts>(predicate: predicate)
                let existingGroups = try modelContext.fetch(descriptor)
                
                // Check if we found any existing groups for this date and the userID
                if let existingGroup = existingGroups.first {
                    // Add to existing group
                    existingGroup.products?.append(product)
                    print("📝 Found existing group for manual product, adding item to it")
                } else {
                    // Create new group
                    let newGroupedProducts = GroupedProducts(expirationDate: normalizedDate, products: [product], userId: userId)
                    modelContext.insert(newGroupedProducts)
                    print("📝 Created new group for manual product")
                }
                
                // Single save operation
                try modelContext.save()
                print("✅ Successfully saved manual product to database")
                print("✅ Manual Product created: \(product.title)")
                
            // Clear error message on success
            self.errorMessage = nil
            self.isSaving = false

        } catch {
            print("❌ Error creating manual product: \(error.localizedDescription)")
            self.errorMessage = "Failed to save product. Please try again."
            self.isSaving = false
        }
    }
    
    func searchRecipeByID(recipeIds : [Int]) async {
        for recipeId in recipeIds{
            do {
                // Get and validate API key
                guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
                    print("❌ Error: API key is nil or empty")
                    return
                }
                
                // Build URL with query parameters
                guard var urlComponents = URLComponents(string: "https://api.spoonacular.com/recipes/\(recipeId)/information") else {
                    print("❌ Error: Failed to create URL components")
                    return
                }
                
                let queryItems: [URLQueryItem] = [
                    URLQueryItem(name: "apiKey", value: apiKey)
                ]
                
                urlComponents.queryItems = queryItems
                
                guard let url = urlComponents.url else {
                    print("❌ Error: Failed to create final URL")
                    return
                }
                
                print("🌐 Making recipe search request to: \(url.absoluteString)")
                
                // Make API request
                let (data, response) = try await URLSession.shared.data(from: url)
                
                // Validate HTTP response
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Error: Invalid response type")
                    return
                }
                
                print("📡 Recipe search response status code: \(httpResponse.statusCode)")
                
                // Handle HTTP error status codes
                switch httpResponse.statusCode {
                case 200...299:
                    print("✅ Recipe search successful")
                case 401:
                    print("❌ Unauthorized: Invalid API key")
                    return
                case 402:
                    print("❌ Payment required: API quota exceeded")
                    return
                case 403:
                    print("❌ Forbidden: Access denied")
                    return
                case 404:
                    print("❌ Not found: Invalid endpoint")
                    return
                case 429:
                    print("❌ Too many requests: Rate limit exceeded")
                    return
                case 500...599:
                    print("❌ Server error: \(httpResponse.statusCode)")
                    return
                default:
                    print("❌ Unexpected status code: \(httpResponse.statusCode)")
                    return
                }
                
                // Validate data is not empty
                guard !data.isEmpty else {
                    print("❌ Error: Empty response data")
                    return
                }
                
                // Parse JSON response
                let decoder = JSONDecoder()
                let recipe = try decoder.decode(Recipe.self, from: data)
                
                print("✅ Successfully decoded recipe information")
                
                let sdRecipe = SDRecipe(from : recipe)
                await MainActor.run {
                    self.recipes.append(sdRecipe)
                }
                
                print("Added recipe to product : \(sdRecipe.title ?? "Unknown Recipe")")
            } catch {
                print("❌ Error searching for recipes: \(error.localizedDescription)")
                return
            }
        }
        
    }
    
    
}
