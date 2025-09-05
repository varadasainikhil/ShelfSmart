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
    var productImageLink : String?
    var isLoading : Bool = false
    var errorMessage : String?
    var searchSuccess : Bool = false
    var isSearchButtonDisabled : Bool {
        return barcode.isEmpty || isLoading
    }
    
    
    func createItem(modelContext : ModelContext){
        // Reset any previous error messages
        errorMessage = nil
        let newItem = Item(barcode: barcode, name: name, productDescription: productDescription, expirationDate: expirationDate, productImage: productImageLink)
        
        print("Created a new Item")
        
        // Find the userId of the user
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Could not find the userID of the user"
            print("Could not find the userID of the user")
            return
        }
        
        do {
            // Use normalized date for comparison
            let normalizedDate = Calendar.current.startOfDay(for: newItem.expirationDate)
            
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
                existingGroup.products?.append(newItem)
                print("Found existing group for date, adding item to it")
            } else {
                
                // Create new group
                let newGroupedProducts = GroupedProducts(expirationDate: normalizedDate, products: [newItem], userId : userId)
                
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
    
    func getAPIKey() -> String? {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let apiKey = plist["API_KEY"] as? String else {
            return nil
        }
        print(apiKey)
        return apiKey
    }
    
    func BCLUSearchBarCode(barCode: String) async throws {
        
        // Reset state
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            searchSuccess = false
        }
        
        print("Searching for barcode: \(barCode)")
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
        
        guard var urlComponents = URLComponents(string: "https://api.barcodelookup.com/v3/products") else {
            print("❌ Error: Failed to create URL components")
            throw URLError(.badURL)
        }
        
        let queryItems : [URLQueryItem] = [
            URLQueryItem(name: "barcode", value: barCode),
            URLQueryItem(name: "formatted", value: "y"),
            URLQueryItem(name: "key", value: validApiKey)
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
            let apiResponse = try decoder.decode(BCLUResponse.self, from: data)
            
            print("✅ Successfully decoded response")
            print("📊 Number of products found: \(apiResponse.products.count)")
            
            if let firstProduct = apiResponse.products.first {
                print("🏷️ First product title: \(firstProduct.title)")
                await MainActor.run {
                    self.name = firstProduct.title
                    self.productDescription = firstProduct.description
                    self.productImageLink = firstProduct.images.first
                    self.isLoading = false
                    self.searchSuccess = true
                    self.errorMessage = nil
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
    
    func OFFASearchBarCode(barCode: String) async throws {
        
        // Reset state
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            searchSuccess = false
        }
        
        print("Searching for barcode: \(barCode)")
        
        guard var urlComponents = URLComponents(string: "https://world.openfoodfacts.org/api/v2/product/\(barCode)") else {
            print("❌ Error: Failed to create URL components")
            throw URLError(.badURL)
        }
        
        let queryItems : [URLQueryItem] = [
            URLQueryItem(name: "fields", value: "product_name,brands,nutriments,nutrition_grades,ingredients_text,image_url")
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
            let apiResponse = try decoder.decode(OFFAResponse.self, from: data)
            
            print("✅ Successfully decoded response")
            
            if apiResponse.status == 1 {
                let product = apiResponse.product
                print("🏷️ First product name: \(product.productName)")
                await MainActor.run {
                    self.name = product.brands.capitalized + "" + product.productName.capitalized
                    self.productDescription = ""
                    self.productImageLink = product.imageURL
                    self.isLoading = false
                    self.searchSuccess = true
                    self.errorMessage = nil
                    
                    
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
    
}
