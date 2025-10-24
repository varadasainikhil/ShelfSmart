//
//  AddProductViewViewModel.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/26/25.
//

import FirebaseAuth
import Foundation
import SwiftData

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
    
    // This is to track the errors
    var errorMessage : String?
    
    // This variable is for tracking the searchProduct success
    var searchSuccess : Bool = false
    
    var lastVerifiedBarcode : String = ""
    
    var searchAttempted : Bool = false
    
    // Store the groceryProduct - created when saving the product
    var groceryProduct : GroceryProduct? = nil
    
    // Product variable to hold the product that is going to be saved to the modelContext
    var product : Product? = nil
    
    var isSearchButtonDisabled : Bool {
        return barcode.isEmpty || isLoading
    }

    var isSaveButtonDisabled : Bool {
        return isSaving || isLoading || (name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !searchSuccess)
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
        return apiKey
    }
    
    // Searches for the product using the barcode
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
                searchSuccess = false
            }
            return
        }
        
        print("✅ API key retrieved successfully")
        
        guard var urlComponents = URLComponents(string:"https://api.spoonacular.com/food/products/upc/\(barcode)") else {
            print("❌ Error: Failed to create URL components")
            searchSuccess = false
            throw URLError(.badURL)
        }
        
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "apiKey", value: apiKey)
        ]
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            print("❌ Error: Failed to create final URL")
            searchSuccess = false
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
                        searchSuccess = false
                    }
                    return
                case 402:
                    print("❌ Payment required: API quota exceeded")
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "API quota exceeded. Please try again later."
                        searchSuccess = false
                    }
                    return
                case 404:
                    print("❌ Not found: Invalid endpoint or product not found")
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "Product not found for this barcode."
                        self.barcode = ""
                        searchSuccess = false
                    }
                    return
                default:
                    print("❌ Unexpected status code: \(httpResponse.statusCode)")
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "An unexpected error occurred. Please try again."
                        searchSuccess = false
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
            
            self.groceryProduct = apiResponse
            
            // Validate that we have a meaningful product response
            let hasValidTitle = !(groceryProduct?.title?.isEmpty ?? true)
            let hasValidId = groceryProduct?.id != nil
            let hasValidUPC = !(groceryProduct?.upc?.isEmpty ?? true)

            print()
            
            if hasValidTitle || hasValidId || hasValidUPC {
                // Update UI with found product data
                await MainActor.run {
                    self.name = groceryProduct?.title?.cleanHTMLText ?? "Unknown Product"
                    self.lastVerifiedBarcode = groceryProduct?.upc?.cleanHTMLText ?? ""
                    self.productDescription = groceryProduct?.description?.cleanHTMLText ?? ""
                    self.imageLink = apiResponse.image?.cleanHTMLText ?? ""
                    self.searchSuccess = true
                    self.isLoading = false
                    self.errorMessage = nil // Clear any previous errors
                }

                print("✅ API product data loaded successfully - ready for user to save")
                
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
                    self.groceryProduct = nil // Clear grocery product
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
                self.groceryProduct = nil // Clear grocery product
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
                self.groceryProduct = nil // Clear grocery product
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
                self.groceryProduct = nil // Clear grocery product
            }
        }
    }
    
    @MainActor
    func createProductFromAPIResponse(userId: String, modelContext : ModelContext, notificationManager: NotificationManager) async {
        // Set saving state and reset any previous error messages
        isSaving = true
        errorMessage = nil

        guard groceryProduct != nil else {
            return
        }

        // Capture the expiration date before any potential reset
        let userSelectedExpirationDate = self.expirationDate
        print("📦 API Product - User selected expiration date: \(userSelectedExpirationDate)")

        print("📦 Created groceryProduct from API response: \(String(describing: groceryProduct?.title))")

        // If there is no productTitle, the function generates an error
        guard let _ = groceryProduct?.title else {
            print("Title not found from the API Response")
            errorMessage = "Title not found from API Response"
            return
        }

        // If there is no productBarcode, the function generates an error
        guard let _ = groceryProduct?.upc else {
            print("Barcode not found from the API Response")
            errorMessage = "Barcode not found from API Response"
            return
        }

        // Creating the product using our convenience initializer
        product = Product(from: groceryProduct!, expirationDate: self.expirationDate, userId: userId)
        product?.title = name
        product?.productDescription = productDescription

        // Calling the function searchAndSaveRecipesForProduct
        await searchAndSaveRecipesForProduct(product : self.product!, userId: userId, modelContext: modelContext, userExpirationDate: userSelectedExpirationDate, notificationManager: notificationManager)
    }

    /// Searches for recipes and creates the product with recipe IDs
    @MainActor
    private func searchAndSaveRecipesForProduct(product : Product, userId: String, modelContext: ModelContext, userExpirationDate: Date, notificationManager: NotificationManager) async {
        // Extract ingredients for recipe search
        var ingredients: [String] = []
        
        // Use breadcrumbs if available from the product apiResponse, otherwise use title
        if let breadcrumbs = product.breadcrumbs, !breadcrumbs.isEmpty {
            ingredients.append(contentsOf: breadcrumbs)
        } else {
            // Fallback to using the product title as an ingredient
            ingredients.append(product.title)
        }
        
        // Remove duplicates and filter out empty strings
        let uniqueIngredients = Array(Set(ingredients.filter { !$0.isEmpty }))
        
        print("🥘 Searching for recipes with ingredients: \(uniqueIngredients)")
        
        // Search for recipe IDs
        let recipeIds = await searchForRecipeIds(ingredients: uniqueIngredients)
        
        // Search for recipe using recipeId
        await self.searchRecipeByID(recipeIds: recipeIds ?? [Int]())
        
        // Assigning the recipeIDs to the product
        product.recipeIds = recipeIds
        
        // Assigning the recipes to the product
        product.recipes = self.recipes
        
        print("Created a new Item")
        print("🖼️ Product imageLink set to: \(String(describing: product.imageLink))")
        print("BreadCrumbs : \(product.breadcrumbs ?? [])")
        print("🍽️ Recipe IDs found: \(recipeIds ?? [])")

        do {
            // Use normalized date for comparison - ensure we use the exact date selected by user
            let normalizedDate = Calendar.current.startOfDay(for: userExpirationDate)
            print("🗓️ API Product - Original expiration date: \(userExpirationDate)")
            print("🗓️ API Product - Normalized date for grouping: \(normalizedDate)")
            
            // Setting the expiration Date to the normalizedDate
            product.expirationDate = normalizedDate
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

            // Schedule notifications for the product
            await notificationManager.scheduleNotifications(for: product)
            print("📅 Notifications scheduled for product: \(product.title)")

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
    func createAndSaveManualProduct(userId: String, modelContext: ModelContext, notificationManager: NotificationManager) async {
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
        
        // Search for recipes using product name
        let ingredients = productName.components(separatedBy: " ")
        
        // Search for recipes by ingredients using the name because it is a manual entry
        let recipeIds = await self.searchForRecipeIds(ingredients: ingredients)
        
        // Searching for recipes from recipeIds
        await self.searchRecipeByID(recipeIds: recipeIds ?? [Int]())
        
        // Create Product directly without unnecessary GroceryProduct intermediate step
        // For manual products: spoonacularId=nil
        let product = Product(
            id: UUID().uuidString, // Unique identifier for this product instance
            spoonacularId: nil, // No Spoonacular ID for manual products
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
            expirationDate: productExpirationDate,
            userId: userId
        )
            
        print("📝 Created manual product with expiration date: \(product.expirationDate)")

        do {
            // Use normalized date for comparison - ensure we use the exact date selected by user
            let normalizedDate = Calendar.current.startOfDay(for: productExpirationDate)
            print("🗓️ Manual product - Original expiration date: \(productExpirationDate)")
            print("🗓️ Manual product - Normalized date for grouping: \(normalizedDate)")
                
            // Setting the product expiration date to the normalizedDate
            product.expirationDate = normalizedDate
            
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

                // Schedule notifications for the product
                await notificationManager.scheduleNotifications(for: product)
                print("📅 Notifications scheduled for product: \(product.title)")

            // Clear error message on success
            self.errorMessage = nil
            self.isSaving = false

        } catch {
            print("❌ Error creating manual product: \(error.localizedDescription)")
            self.errorMessage = "Failed to save product. Please try again."
            self.isSaving = false
        }
    }
    
    // Searches for the recipe using the recipe ID
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
