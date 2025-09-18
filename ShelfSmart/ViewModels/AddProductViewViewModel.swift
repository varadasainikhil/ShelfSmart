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
    var errorMessage : String?
    var searchSuccess : Bool = false
    var searchAttempted : Bool = false
    var apiResponse : GroceryProduct? = nil
    
    var isSearchButtonDisabled : Bool {
        return barcode.isEmpty || isLoading
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
            }
            
            print("📦 Received data size: \(data.count) bytes")
            
            // Log the raw JSON response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON Response: \(jsonString)")
            }
            
            let decoder = JSONDecoder()
            
            // First try to decode as an error response
            if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                print("❌ API returned error: \(errorResponse.message)")
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Product not found for this barcode"
                    self.barcode = "" // Clear barcode so user can enter/scan a new one
                }
                return
            }
            
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
            
            // Check if we have essential data to create a product
            let productTitle = apiResponse.title ?? "Unknown Product"
            let productUpc = apiResponse.upc ?? barcode
            
            if !productTitle.isEmpty || !productUpc.isEmpty {
                // Update UI with found product data
                await MainActor.run {
                    self.name = productTitle
                    self.productDescription = apiResponse.description ?? ""
                    self.imageLink = apiResponse.image ?? ""
                    self.searchSuccess = true
                    self.isLoading = false
                }
                
                // Store the API response for later use when user saves
                await MainActor.run {
                    self.apiResponse = apiResponse
                    print("✅ API product data loaded successfully - ready for user to save")
                }
                
            } else {
                print("⚠️ No essential product data found in response")
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Product data incomplete. Please enter details manually."
                    self.barcode = "" // Clear barcode so user can enter/scan a new one
                }
            }
            
        } catch let decodingError as DecodingError {
            print("❌ JSON Decoding Error: \(decodingError)")
            print("❌ Decoding Error Details: \(decodingError.localizedDescription)")
            
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to parse product data. Please try again."
            }
        } catch let urlError as URLError {
            print("❌ Network Error: \(urlError)")
            print("❌ Network Error Code: \(urlError.code.rawValue)")
            print("❌ Network Error Description: \(urlError.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Network error: \(urlError.localizedDescription)"
            }
        } catch {
            print("❌ Unknown Error: \(error)")
            print("❌ Error Type: \(type(of: error))")
            print("❌ Error Description: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Unexpected error: \(error.localizedDescription)"
            }
        }
    }
    
    func createProductFromAPIResponse(apiResponse : GroceryProduct, modelContext : ModelContext ){
        // Reset any previous error messages
        errorMessage = nil
        
        // Handle optional credits
        let credit: Credit
        if let apiCredits = apiResponse.credits {
            credit = Credit(text: apiCredits.text, link: apiCredits.link, image: apiCredits.image, imageLink: apiCredits.imageLink)
        } else {
            // Provide default credits when API doesn't include them
            credit = Credit(text: "Product information provided by Spoonacular", link: "https://spoonacular.com", image: "Spoonacular", imageLink: "https://spoonacular.com")
        }
        
        // Generate a fallback ID if the API doesn't provide one
        let productId = apiResponse.id ?? {
            let fallbackId = Int.random(in: 1000000...9999999)
            print("⚠️ API didn't provide ID, generating fallback ID: \(fallbackId)")
            return fallbackId
        }()
        
        // Use fallback values for essential fields
        let productTitle = apiResponse.title ?? "Unknown Product"
        let productBarcode = apiResponse.upc ?? barcode
        
        let product = Product(id: productId, barcode: productBarcode, title: productTitle, brand: apiResponse.brand ?? "", badges: apiResponse.badges, importantBadges: apiResponse.importantBadges, spoonacularScore: apiResponse.spoonacularScore, productDescription: apiResponse.description, imageLink: apiResponse.image, moreImageLinks: apiResponse.images, generatedText: apiResponse.generatedText, ingredientCount: apiResponse.ingredientCount, credits: credit, expirationDate: expirationDate)
        
        print("Created a new Item")
        print("🖼️ Product imageLink set to: \(String(describing: product.imageLink))")
        
        // Find the userId of the user
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Could not find the userID of the user"
            print("Could not find the userID of the user")
            return
        }
        
        do {
            // Use normalized date for comparison - ensure we use the exact date selected by user
            let normalizedDate = Calendar.current.startOfDay(for: expirationDate)
            print("🗓️ Original expiration date: \(expirationDate)")
            print("🗓️ Normalized date for grouping: \(normalizedDate)")
            
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
            
        } catch {
            print("Error creating item: \(error.localizedDescription)")
            errorMessage = "Failed to save product. Please try again."
        }
        
    }
    
    // Function to create product manually (without API)
    func createManualProduct(modelContext: ModelContext) {
        // Reset any previous error messages
        errorMessage = nil
        
        // Validate required fields - only name is required
        guard !name.isEmpty else {
            errorMessage = "Product name is required to save the product"
            return
        }
        
        // Create default credits for manual products
        let credit = Credit(text: "Manually added product", link: "", image: "User Added", imageLink: "")
        
        // Generate a random ID for manual products
        let productId = Int.random(in: 1000000...9999999)
        print("📝 Creating manual product with ID: \(productId)")
        print("🗓️ User selected expiration date: \(expirationDate)")
        
        // Determine barcode based on whether search was attempted
        let productBarcode: String = {
            if searchAttempted && barcode.isEmpty {
                // User searched but product not found - no barcode
                return ""
            } else if barcode.isEmpty {
                // Pure manual entry - generate barcode
                return "MANUAL-\(productId)"
            } else {
                // User provided barcode
                return barcode
            }
        }()

        let product = Product(
            id: productId,
            barcode: productBarcode,
            title: name,
            brand: "",
            badges: nil,
            importantBadges: nil,
            spoonacularScore: nil,
            productDescription: productDescription.isEmpty ? nil : productDescription,
            imageLink: nil,
            moreImageLinks: nil,
            generatedText: nil,
            ingredientCount: nil,
            credits: credit,
            expirationDate: expirationDate
        )
        
        print("📝 Created manual product with expiration date: \(product.expirationDate)")
        
        // Find the userId of the user
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Could not find the userID of the user"
            print("Could not find the userID of the user")
            return
        }
        
        do {
            // Use normalized date for comparison - ensure we use the exact date selected by user
            let normalizedDate = Calendar.current.startOfDay(for: expirationDate)
            print("🗓️ Manual product - Original expiration date: \(expirationDate)")
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
            
        } catch {
            print("❌ Error creating manual product: \(error.localizedDescription)")
            errorMessage = "Failed to save product. Please try again."
        }
    }
    
}
