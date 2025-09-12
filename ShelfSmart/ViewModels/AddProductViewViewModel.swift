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
    var expirationDate : Date = Date.now.addingTimeInterval(86400)
    var isLoading : Bool = false
    var errorMessage : String?
    var searchSuccess : Bool = false
    
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
            
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(GroceryProduct.self, from: data)
            
            print("✅ Successfully decoded response")
            print("🖼️ API Response imageLink: \(String(describing: apiResponse.imageLink))")
            print("🖼️ API Response moreImageLinks: \(String(describing: apiResponse.moreImageLinks))")
            
            if apiResponse.upc == barcode {
                // Update UI with found product data
                await MainActor.run {
                    self.name = apiResponse.title
                    self.productDescription = apiResponse.description ?? ""
                    self.searchSuccess = true
                    self.isLoading = false
                }
                
                // Create and save the product
                await MainActor.run {
                    self.createProductFromAPIResponse(apiResponse: apiResponse, modelContext: modelContext)
                }
                
            } else {
                print("⚠️ No products found in response")
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "No products found for this barcode"
                }
            }
            
        } catch let decodingError as DecodingError {
            print("❌ JSON Decoding Error: \(decodingError)")
            print("❌ Decoding Error Details: \(decodingError.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to parse product data"
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
        
        let credit = Credit(text: apiResponse.credits.text, link: apiResponse.credits.link ,image: apiResponse.credits.image, imageLink: apiResponse.credits.imageLink)
        
        let product = Product(id: apiResponse.id, barcode : apiResponse.upc, title: apiResponse.title, brand: apiResponse.brand ?? "", badges: apiResponse.badges, importantBadges: apiResponse.importantBadges, spoonacularScore: apiResponse.spoonacularScore, productDescription: apiResponse.description, imageLink: apiResponse.imageLink, moreImageLinks: apiResponse.moreImageLinks, generatedText: apiResponse.generatedText, ingredientCount: apiResponse.ingredientCount, credits: credit,  expirationDate: expirationDate)
        
        print("Created a new Item")
        print("🖼️ Product imageLink set to: \(String(describing: product.imageLink))")
        
        // Find the userId of the user
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Could not find the userID of the user"
            print("Could not find the userID of the user")
            return
        }
        
        do {
            // Use normalized date for comparison
            let normalizedDate = Calendar.current.startOfDay(for: product.expirationDate)
            
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
    
}
