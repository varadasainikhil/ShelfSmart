//
//  AddProductViewViewModel.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/26/25.
//

import FirebaseAuth
import FirebaseFirestore
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

    // Scanner state
    var showingScanner : Bool = false

    // This is to track the errors
    var errorMessage : String?

    // This variable is for tracking the searchProduct success
    var searchSuccess : Bool = false

    var lastVerifiedBarcode : String = ""

    var searchAttempted : Bool = false

    // Store the groceryProduct - created when saving the product (Spoonacular)
    var groceryProduct : GroceryProduct? = nil

    // Product variable to hold the product that is going to be saved to the modelContext (Spoonacular)
    var product : Product? = nil

    // OFFA product variables
    var offaProduct: OFFAProduct? = nil
    var lsProduct: LSProduct? = nil
    var offaRecipes: [SDOFFARecipe] = []
    
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
        showingScanner = false
        errorMessage = nil
        searchSuccess = false
        searchAttempted = false
        groceryProduct = nil
        self.recipes = [SDRecipe]()
        offaProduct = nil
        lsProduct = nil
        self.offaRecipes = []
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
    
    /// Fetches user's saved allergies from Firestore
    /// - Parameter userId: The user ID to fetch allergies for
    /// - Returns: Array of allergy strings (empty array if none found or error)
    private func fetchUserAllergies(userId: String) async -> [String] {
        // Guard: Check if user is still authenticated
        guard Auth.auth().currentUser != nil else {
            print("ℹ️ [OFFA Recipe] User not authenticated - skipping allergy fetch")
            return []
        }
        
        do {
            let db = Firestore.firestore()
            let userDoc = try await db.collection("users").document(userId).getDocument()
            
            if let data = userDoc.data(),
               let allergies = data["allergies"] as? [String] {
                print("✅ [OFFA Recipe] User allergies fetched: \(allergies)")
                return allergies
            } else {
                print("ℹ️ [OFFA Recipe] No allergies found for user")
                return []
            }
        } catch {
            print("❌ [OFFA Recipe] Error fetching user allergies: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Handle Scanned Barcode
    /// Handles a barcode scanned from the camera
    /// - Parameters:
    ///   - code: The scanned barcode string
    ///   - modelContext: The SwiftData model context for API search
    func handleScannedBarcode(_ code: String, modelContext: ModelContext) async {
        print("📷 Handling scanned barcode: \(code)")

        // Update barcode field
        await MainActor.run {
            self.barcode = code
        }

        // Automatically trigger OFFA product search
        do {
            try await searchProductOFFA(modelContext: modelContext)
            print("✅ [OFFA] Product search completed for scanned barcode")
        } catch {
            print("❌ [OFFA] Error searching for scanned barcode: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Failed to search for product. Please try again."
            }
        }
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
            
            if hasValidTitle && hasValidId && hasValidUPC {
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

    // MARK: - OFFA Product Search
    /// Searches for the product using the barcode via Open Food Facts API
    func searchProductOFFA(modelContext: ModelContext) async throws {
        // Reset state
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            searchSuccess = false
            searchAttempted = true
            imageLink = ""
        }

        print("🔍 [OFFA] Searching for barcode: \(barcode)")

        // Build OFFA API URL - no API key needed!
        guard let url = URL(string: "https://world.openfoodfacts.net/api/v2/product/\(barcode)") else {
            print("❌ [OFFA] Error: Failed to create URL")
            await MainActor.run {
                isLoading = false
                errorMessage = "Invalid barcode format"
                searchSuccess = false
            }
            throw URLError(.badURL)
        }

        print("🌐 [OFFA] Making request to: \(url.absoluteString)")

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            // Log response details
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 [OFFA] Response status code: \(httpResponse.statusCode)")
                
                // Open Food Facts API returns 200 even for "product not found"
                // The actual status is in the JSON body (status: 0 = not found, status: 1 = found)
                // Only treat non-200 as server error if it's a server error (5xx)
                if httpResponse.statusCode >= 500 {
                    print("❌ [OFFA] Server error status code: \(httpResponse.statusCode)")
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "Server error. Please try again."
                        searchSuccess = false
                    }
                    return
                }
            }

            
            print("📦 [OFFA] Received data size: \(data.count) bytes")

            // Log the raw JSON response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 [OFFA] Raw JSON Response: \(jsonString.prefix(500))...") // First 500 chars
            }

            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(OpenFoodFactsResponse.self, from: data)

            print("✅ [OFFA] Successfully decoded response")
            print("📦 [OFFA] Status: \(apiResponse.status)")
            print("📦 [OFFA] Status Verbose: \(apiResponse.statusVerbose ?? "N/A")")

            // Check if product was found
            // status: 0 = product not found, status: 1 = product found
            guard apiResponse.status == 1, let product = apiResponse.product else {
                print("⚠️ [OFFA] Product not found in OFFA database")
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Product not found. Please enter details manually."
                    self.searchSuccess = false
                    // Keep barcode so user can still save manually with this barcode
                }
                return
            }

            print("✅ [OFFA] Product found!")
            print("📦 [OFFA] Product Name: \(product.productName ?? "Unknown")")
            print("📦 [OFFA] Brand: \(product.brands ?? "Unknown")")
            print("📦 [OFFA] Barcode: \(product.code)")
            print("🖼️ [OFFA] Image URL: \(product.imageFrontURL ?? "None")")
            print("🏷️ [OFFA] Labels Tags: \(product.labelsTags ?? [])")

            self.offaProduct = product

            // Update UI with found product data
            await MainActor.run {
                self.name = product.productName ?? "Unknown Product"
                self.lastVerifiedBarcode = product.code
                self.productDescription = product.ingredientsText ?? ""
                self.imageLink = product.imageFrontURL ?? product.imageURL ?? ""
                self.searchSuccess = true
                self.isLoading = false
                self.errorMessage = nil
            }

            print("✅ [OFFA] Product data loaded successfully - ready for user to save")

        } catch let decodingError as DecodingError {
            print("❌ [OFFA] JSON Decoding Error: \(decodingError)")
            print("❌ [OFFA] Decoding Error Details: \(decodingError.localizedDescription)")

            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Product not found. Please enter details manually."
                self.searchSuccess = false
                self.offaProduct = nil
            }
        } catch let urlError as URLError {
            print("❌ [OFFA] Network Error: \(urlError)")
            print("❌ [OFFA] Network Error Code: \(urlError.code.rawValue)")

            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Network error: \(urlError.localizedDescription)"
                self.searchSuccess = false
                self.offaProduct = nil
            }
        } catch {
            print("❌ [OFFA] Unknown Error: \(error)")
            print("❌ [OFFA] Error Type: \(type(of: error))")

            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Unexpected error: \(error.localizedDescription)"
                self.searchSuccess = false
                self.offaProduct = nil
            }
        }
    }

    // MARK: - Create OFFA Product from API Response
    @MainActor
    func createOFFAProductFromAPIResponse(userId: String, modelContext: ModelContext, notificationManager: NotificationManager) async {
        // Set saving state and reset any previous error messages
        isSaving = true
        errorMessage = nil

        // Clear any previously accumulated recipes to prevent duplicates
        self.offaRecipes = []

        guard let offaProduct = offaProduct else {
            print("❌ [OFFA] No OFFA product available to save")
            errorMessage = "No product data available"
            isSaving = false
            return
        }

        // Capture the expiration date before any potential reset
        let userSelectedExpirationDate = self.expirationDate
        print("📦 [OFFA] User selected expiration date: \(userSelectedExpirationDate)")
        print("📦 [OFFA] Creating LSProduct from OFFA product: \(offaProduct.productName ?? "Unknown")")

        // Search for recipes using product title as ingredient
        print("🔍 [OFFA] Searching for recipes using product title: \(self.name)")
        let recipeIds = await searchForRecipeIdsForOFFAProduct(productTitle: self.name, userId: userId)

        // Fetch recipe details
        await self.searchRecipeByIDForOFFAProduct(recipeIds: recipeIds ?? [])

        // Create LSProduct using convenience initializer
        let lsProduct = LSProduct(
            from: offaProduct,
            recipeIds: recipeIds,
            recipes: self.offaRecipes,
            expirationDate: userSelectedExpirationDate,
            userId: userId
        )

        // Update with user-edited fields
        lsProduct.title = self.name
        lsProduct.productDescription = self.productDescription.isEmpty ? nil : self.productDescription
        lsProduct.imageLink = self.imageLink

        self.lsProduct = lsProduct

        print("✅ [OFFA] Created LSProduct: \(lsProduct.title)")
        print("🍽️ [OFFA] Recipe IDs: \(recipeIds ?? [])")
        print("🖼️ [OFFA] Image link: \(lsProduct.imageLink ?? "None")")

        // Save to GroupedOFFAProducts
        await searchAndSaveRecipesForOFFAProduct(
            lsProduct: lsProduct,
            userId: userId,
            modelContext: modelContext,
            userExpirationDate: userSelectedExpirationDate,
            notificationManager: notificationManager
        )
    }

    /// Saves OFFA product to grouped products and schedules notifications
    @MainActor
    private func searchAndSaveRecipesForOFFAProduct(
        lsProduct: LSProduct,
        userId: String,
        modelContext: ModelContext,
        userExpirationDate: Date,
        notificationManager: NotificationManager
    ) async {
        print("💾 [OFFA] Saving LSProduct to database")

        do {
            // Use normalized date for comparison
            let normalizedDate = Calendar.current.startOfDay(for: userExpirationDate)
            print("🗓️ [OFFA] Original expiration date: \(userExpirationDate)")
            print("🗓️ [OFFA] Normalized date for grouping: \(normalizedDate)")

            // Set the expiration date to normalized date
            lsProduct.expirationDate = normalizedDate

            // Use SwiftData predicate to find existing group
            let predicate = #Predicate<GroupedOFFAProducts> { group in
                group.expirationDate == normalizedDate &&
                group.userId == userId
            }

            let descriptor = FetchDescriptor<GroupedOFFAProducts>(predicate: predicate)
            let existingGroups = try modelContext.fetch(descriptor)

            // Check if we found any existing groups for this date and user
            if let existingGroup = existingGroups.first {
                // Add to existing group
                existingGroup.offaProducts?.append(lsProduct)
                print("✅ [OFFA] Found existing group, added LSProduct to it")
            } else {
                // Create new group
                let newGroupedProducts = GroupedOFFAProducts(
                    expirationDate: normalizedDate,
                    offaProducts: [lsProduct],
                    userId: userId
                )
                modelContext.insert(newGroupedProducts)
                print("✅ [OFFA] Created new GroupedOFFAProducts")
            }

            // Save to database
            try modelContext.save()
            print("✅ [OFFA] Successfully saved LSProduct to database: \(lsProduct.title)")

            // Schedule notifications for the product
            await notificationManager.scheduleNotifications(for: lsProduct)
            print("📅 [OFFA] Notifications scheduled for product: \(lsProduct.title)")

            // Clear error message on success
            self.errorMessage = nil
            self.isSaving = false

        } catch {
            print("❌ [OFFA] Error saving LSProduct: \(error.localizedDescription)")
            self.errorMessage = "Failed to save product. Please try again."
            self.isSaving = false
        }
    }

    @MainActor
    func createProductFromAPIResponse(userId: String, modelContext : ModelContext, notificationManager: NotificationManager) async {
        // Set saving state and reset any previous error messages
        isSaving = true
        errorMessage = nil

        guard groceryProduct != nil else {
            isSaving = false
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
            isSaving = false
            return
        }

        // If there is no productBarcode, the function generates an error
        guard let _ = groceryProduct?.upc else {
            print("Barcode not found from the API Response")
            errorMessage = "Barcode not found from API Response"
            isSaving = false
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
    
    // Function to create product manually (without API) - Creates LSProduct (OFFA format)
    @MainActor
    func createAndSaveManualProduct(userId: String, modelContext: ModelContext, notificationManager: NotificationManager) async {
        // Set saving state and reset any previous error messages
        self.isSaving = true
        self.errorMessage = nil

        // Clear any previously accumulated recipes to prevent duplicates
        self.offaRecipes = []

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

        print("📝 [Manual OFFA] Creating manual LSProduct")
        print("🗓️ [Manual OFFA] User selected expiration date: \(productExpirationDate)")

        // Search for recipes using product name as ingredient
        print("🔍 [Manual OFFA] Searching for recipes using product name: \(productName)")
        let recipeIds = await self.searchForRecipeIdsForOFFAProduct(productTitle: productName, userId: userId)

        // Fetch recipe details
        await self.searchRecipeByIDForOFFAProduct(recipeIds: recipeIds ?? [])

        // Create LSProduct for manual entry using convenience initializer
        let lsProduct = LSProduct(
            barcode: productBarcode.isEmpty ? "" : productBarcode,
            title: productName,
            brand: "",
            quantity: nil,
            productDescription: productDescription.isEmpty ? nil : productDescription,
            imageLink: nil,
            recipeIds: recipeIds,
            recipes: self.offaRecipes,
            expirationDate: productExpirationDate,
            userId: userId
        )

        self.lsProduct = lsProduct

        print("✅ [Manual OFFA] Created LSProduct: \(lsProduct.title)")
        print("🍽️ [Manual OFFA] Recipe IDs: \(recipeIds ?? [])")

        do {
            // Use normalized date for comparison
            let normalizedDate = Calendar.current.startOfDay(for: productExpirationDate)
            print("🗓️ [Manual OFFA] Original expiration date: \(productExpirationDate)")
            print("🗓️ [Manual OFFA] Normalized date for grouping: \(normalizedDate)")

            // Set the expiration date to normalized date
            lsProduct.expirationDate = normalizedDate

            // Use SwiftData predicate to find existing group
            let predicate = #Predicate<GroupedOFFAProducts> { group in
                group.expirationDate == normalizedDate &&
                group.userId == userId
            }

            let descriptor = FetchDescriptor<GroupedOFFAProducts>(predicate: predicate)
            let existingGroups = try modelContext.fetch(descriptor)

            // Check if we found any existing groups for this date and user
            if let existingGroup = existingGroups.first {
                // Add to existing group
                existingGroup.offaProducts?.append(lsProduct)
                print("✅ [Manual OFFA] Found existing group, added LSProduct to it")
            } else {
                // Create new group
                let newGroupedProducts = GroupedOFFAProducts(
                    expirationDate: normalizedDate,
                    offaProducts: [lsProduct],
                    userId: userId
                )
                modelContext.insert(newGroupedProducts)
                print("✅ [Manual OFFA] Created new GroupedOFFAProducts")
            }

            // Save to database
            try modelContext.save()
            print("✅ [Manual OFFA] Successfully saved manual LSProduct to database: \(lsProduct.title)")

            // Schedule notifications for the product
            await notificationManager.scheduleNotifications(for: lsProduct)
            print("📅 [Manual OFFA] Notifications scheduled for product: \(lsProduct.title)")

            // Clear error message on success
            self.errorMessage = nil
            self.isSaving = false

        } catch {
            print("❌ [Manual OFFA] Error saving manual LSProduct: \(error.localizedDescription)")
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

                // Get measurement system based on user's locale
                let unitSystem = MeasurementSystemManager.shared.getMeasurementSystem()

                let queryItems: [URLQueryItem] = [
                    URLQueryItem(name: "apiKey", value: apiKey),
                    URLQueryItem(name: "unitSystem", value: unitSystem)
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

    // MARK: - OFFA Recipe Methods
    /// Searches for recipe IDs using product title as ingredient (for OFFA products)
    /// Uses complexSearch endpoint with includeIngredients and intolerances parameters
    /// - Parameters:
    ///   - productTitle: The product title to use as ingredient
    ///   - userId: The user ID to fetch allergy preferences for
    /// - Returns: Array of recipe IDs (up to 4)
    private func searchForRecipeIdsForOFFAProduct(productTitle: String, userId: String) async -> [Int]? {
        do {
            // Get and validate API key
            guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
                print("❌ [OFFA Recipe] Error: API key is nil or empty")
                return nil
            }

            // Fetch user allergies from Firebase
            let userAllergies = await fetchUserAllergies(userId: userId)
            
            // Build URL with query parameters using complexSearch endpoint
            guard var urlComponents = URLComponents(string: "https://api.spoonacular.com/recipes/complexSearch") else {
                print("❌ [OFFA Recipe] Error: Failed to create URL components")
                return nil
            }

            // Use product title as the ingredient with includeIngredients parameter
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "apiKey", value: apiKey),
                URLQueryItem(name: "includeIngredients", value: productTitle),
                URLQueryItem(name: "number", value: "4") // Limit to 4 recipes
            ]
            
            // Add intolerances parameter if user has allergies
            if !userAllergies.isEmpty {
                let intolerancesString = userAllergies.joined(separator: ",")
                queryItems.append(URLQueryItem(name: "intolerances", value: intolerancesString))
                print("🚫 [OFFA Recipe] Excluding user allergies: \(intolerancesString)")
            }

            urlComponents.queryItems = queryItems

            guard let url = urlComponents.url else {
                print("❌ [OFFA Recipe] Error: Failed to create final URL")
                return nil
            }

            print("🌐 [OFFA Recipe] Making recipe search request to: \(url.absoluteString)")

            // Make API request
            let (data, response) = try await URLSession.shared.data(from: url)

            // Validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [OFFA Recipe] Error: Invalid response type")
                return nil
            }

            print("📡 [OFFA Recipe] Recipe search response status code: \(httpResponse.statusCode)")

            // Handle HTTP error status codes
            switch httpResponse.statusCode {
            case 200...299:
                print("✅ [OFFA Recipe] Recipe search successful")
            case 401:
                print("❌ [OFFA Recipe] Unauthorized: Invalid API key")
                return nil
            case 402:
                print("❌ [OFFA Recipe] Payment required: API quota exceeded")
                return nil
            case 403:
                print("❌ [OFFA Recipe] Forbidden: Access denied")
                return nil
            case 404:
                print("❌ [OFFA Recipe] Not found: Invalid endpoint")
                return nil
            case 429:
                print("❌ [OFFA Recipe] Too many requests: Rate limit exceeded")
                return nil
            case 500...599:
                print("❌ [OFFA Recipe] Server error: \(httpResponse.statusCode)")
                return nil
            default:
                print("❌ [OFFA Recipe] Unexpected status code: \(httpResponse.statusCode)")
                return nil
            }

            // Validate data is not empty
            guard !data.isEmpty else {
                print("❌ [OFFA Recipe] Error: Empty response data")
                return nil
            }

            // Parse JSON response - complexSearch returns a ComplexSearchRecipeResponse wrapper
            let decoder = JSONDecoder()
            let searchResponse = try decoder.decode(ComplexSearchRecipeResponse.self, from: data)

            print("✅ [OFFA Recipe] Successfully decoded recipe search response")
            print("🍽️ [OFFA Recipe] Found \(searchResponse.results.count) recipes")

            // Extract recipe IDs from results array
            let recipeIds = searchResponse.results.map { $0.id }
            print("📋 [OFFA Recipe] Recipe IDs: \(recipeIds)")

            return recipeIds

        } catch {
            print("❌ [OFFA Recipe] Error searching for recipes: \(error.localizedDescription)")
            return nil
        }
    }

    /// Searches for recipes by ID and converts to SDOFFARecipe (for OFFA products)
    /// - Parameter recipeIds: Array of recipe IDs to fetch
    func searchRecipeByIDForOFFAProduct(recipeIds: [Int]) async {
        for recipeId in recipeIds {
            do {
                // Get and validate API key
                guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
                    print("❌ [OFFA Recipe] Error: API key is nil or empty")
                    return
                }

                // Build URL with query parameters
                guard var urlComponents = URLComponents(string: "https://api.spoonacular.com/recipes/\(recipeId)/information") else {
                    print("❌ [OFFA Recipe] Error: Failed to create URL components")
                    return
                }

                // Get measurement system based on user's locale
                let unitSystem = MeasurementSystemManager.shared.getMeasurementSystem()

                let queryItems: [URLQueryItem] = [
                    URLQueryItem(name: "apiKey", value: apiKey),
                    URLQueryItem(name: "unitSystem", value: unitSystem)
                ]

                urlComponents.queryItems = queryItems

                guard let url = urlComponents.url else {
                    print("❌ [OFFA Recipe] Error: Failed to create final URL")
                    return
                }

                print("🌐 [OFFA Recipe] Making recipe detail request to: \(url.absoluteString)")

                // Make API request
                let (data, response) = try await URLSession.shared.data(from: url)

                // Validate HTTP response
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ [OFFA Recipe] Error: Invalid response type")
                    return
                }

                print("📡 [OFFA Recipe] Recipe detail response status code: \(httpResponse.statusCode)")

                // Handle HTTP error status codes
                switch httpResponse.statusCode {
                case 200...299:
                    print("✅ [OFFA Recipe] Recipe detail fetch successful")
                case 401:
                    print("❌ [OFFA Recipe] Unauthorized: Invalid API key")
                    return
                case 402:
                    print("❌ [OFFA Recipe] Payment required: API quota exceeded")
                    return
                case 403:
                    print("❌ [OFFA Recipe] Forbidden: Access denied")
                    return
                case 404:
                    print("❌ [OFFA Recipe] Not found: Invalid endpoint")
                    return
                case 429:
                    print("❌ [OFFA Recipe] Too many requests: Rate limit exceeded")
                    return
                case 500...599:
                    print("❌ [OFFA Recipe] Server error: \(httpResponse.statusCode)")
                    return
                default:
                    print("❌ [OFFA Recipe] Unexpected status code: \(httpResponse.statusCode)")
                    return
                }

                // Validate data is not empty
                guard !data.isEmpty else {
                    print("❌ [OFFA Recipe] Error: Empty response data")
                    return
                }

                // Parse JSON response
                let decoder = JSONDecoder()
                let recipe = try decoder.decode(Recipe.self, from: data)

                print("✅ [OFFA Recipe] Successfully decoded recipe information")

                // Convert to SDOFFARecipe
                let sdOffaRecipe = SDOFFARecipe(from: recipe)
                await MainActor.run {
                    self.offaRecipes.append(sdOffaRecipe)
                }

                print("✅ [OFFA Recipe] Added recipe to OFFA product: \(sdOffaRecipe.title ?? "Unknown Recipe")")
            } catch {
                print("❌ [OFFA Recipe] Error fetching recipe details: \(error.localizedDescription)")
                return
            }
        }
    }
}
