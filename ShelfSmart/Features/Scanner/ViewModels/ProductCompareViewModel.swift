//
//  ProductCompareViewModel.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 1/19/26.
//

import Foundation
import SwiftUI

/// ViewModel for Compare feature
/// Manages scanning state and up to 2 products for comparison
@Observable
class ProductCompareViewModel {
    // MARK: - Properties
    
    /// Products currently in comparison (max 2)
    var comparisonProducts: [CompareProduct] = []
    
    /// Product currently scanned (shown in sheet before adding to comparison)
    var scannedProduct: CompareProduct?
    
    /// Loading state for API calls
    var isLoading: Bool = false
    
    /// Error message to display
    var errorMessage: String?
    
    /// Whether to show the scanner sheet
    var showScannerSheet: Bool = false
    
    /// Whether the scanned product already exists in comparison
    var productAlreadyExists: Bool = false
    
    // MARK: - Dependencies
    
    private let firebaseService = ProductFirebaseService.shared
    
    // MARK: - Computed Properties
    
    /// Whether user can add more products to comparison (max 2)
    var canAddToComparison: Bool {
        comparisonProducts.count < 2
    }
    
    var shouldAutoShowScanner: Bool {
        comparisonProducts.isEmpty
    }
    
    /// Number of products in comparison
    var productCount: Int {
        comparisonProducts.count
    }
    
    /// Whether comparison view should show side-by-side layout
    var showSideBySide: Bool {
        comparisonProducts.count == 2
    }
    
    /// First product in comparison (if any)
    var firstProduct: CompareProduct? {
        comparisonProducts.first
    }
    
    /// Second product in comparison (if any)
    var secondProduct: CompareProduct? {
        comparisonProducts.count > 1 ? comparisonProducts[1] : nil
    }
    
    // MARK: - Actions
    
    /// Scans a barcode and fetches product info
    /// Checks Firebase cache first, then falls back to OpenFoodFacts API
    /// - Parameter barcode: The scanned barcode string
    func scanBarcode(_ barcode: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            scannedProduct = nil
            productAlreadyExists = false
        }
        
        print("🔍 [QuickScan] Scanning barcode: \(barcode)")
        
        // Check if product already exists in comparison
        if comparisonProducts.contains(where: { $0.barcode == barcode }) {
            await MainActor.run {
                isLoading = false
                productAlreadyExists = true
                errorMessage = "This product is already in your comparison"
            }
            return
        }
        
        // Try Firebase cache first - ignoring errors (handled internally by service)
        if let cachedProduct = await firebaseService.fetchProduct(barcode: barcode) {
            await MainActor.run {
                scannedProduct = cachedProduct
                isLoading = false
            }
            print("✅ [QuickScan] Product loaded from Firebase cache")
            return
        }
        
        do {
            // Fall back to OpenFoodFacts API
            let result = try await fetchFromOpenFoodFacts(barcode: barcode)
            
            if let result = result {
                await MainActor.run {
                    scannedProduct = result.compareProduct
                    isLoading = false
                }
                
                // Cache OFFAProduct to Firebase in background (consistent with AddProductView)
                Task.detached {
                    await ProductFirebaseService.shared.saveOFFAProductIfNotExists(result.offaProduct)
                }
                
                print("✅ [QuickScan] Product loaded from OpenFoodFacts API")
            } else {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Product not found. Try a different barcode."
                }
            }
            
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to fetch product: \(error.localizedDescription)"
            }
            print("❌ [QuickScan] Error: \(error.localizedDescription)")
        }
    }
    
    /// Adds the scanned product to comparison
    func addToComparison() {
        guard let product = scannedProduct else { return }
        guard canAddToComparison else { return }
        
        comparisonProducts.append(product)
        scannedProduct = nil
        showScannerSheet = false
        
        print("✅ [QuickScan] Added product to comparison. Total: \(comparisonProducts.count)")
    }
    
    /// Clears all products from comparison
    func clearComparison() {
        comparisonProducts.removeAll()
        scannedProduct = nil
        errorMessage = nil
        productAlreadyExists = false
        
        print("🗑️ [QuickScan] Comparison cleared")
    }
    
    /// Removes a specific product from comparison
    /// - Parameter product: The product to remove
    func removeFromComparison(_ product: CompareProduct) {
        comparisonProducts.removeAll { $0.barcode == product.barcode }
        print("🗑️ [QuickScan] Removed product from comparison. Total: \(comparisonProducts.count)")
    }
    
    /// Dismisses the scanner sheet without adding product
    func dismissScanner() {
        showScannerSheet = false
        scannedProduct = nil
        errorMessage = nil
        productAlreadyExists = false
    }
    
    /// Opens the scanner sheet
    func openScanner() {
        guard canAddToComparison else { return }
        showScannerSheet = true
        scannedProduct = nil
        errorMessage = nil
        productAlreadyExists = false
    }
    
    // MARK: - Private Methods
    
    /// Fetches product from OpenFoodFacts API
    /// Returns tuple of (CompareProduct for display, OFFAProduct for Firebase)
    private func fetchFromOpenFoodFacts(barcode: String) async throws -> (compareProduct: CompareProduct, offaProduct: OFFAProduct)? {
        guard let url = URL(string: "https://world.openfoodfacts.net/api/v2/product/\(barcode)") else {
            throw URLError(.badURL)
        }
        
        print("🌐 [OpenFoodFacts] Fetching: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 [OpenFoodFacts] Status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode >= 500 {
                throw URLError(.badServerResponse)
            }
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(OpenFoodFactsResponse.self, from: data)
        
        // Check if product was found (status: 1 = found)
        guard apiResponse.status == 1, let offaProduct = apiResponse.product else {
            print("⚠️ [OpenFoodFacts] Product not found")
            return nil
        }
        
        print("✅ [OpenFoodFacts] Product found: \(offaProduct.productName ?? "Unknown")")
        return (compareProduct: CompareProduct.from(offaProduct), offaProduct: offaProduct)
    }
}

// MARK: - Comparison Helpers

extension ProductCompareViewModel {
    /// Determines which product is "better" for a given nutrient (lower is better for most)
    /// - Parameters:
    ///   - value1: Value for first product
    ///   - value2: Value for second product
    ///   - lowerIsBetter: Whether lower value is better (true for sugar, fat, etc.)
    /// - Returns: 0 if equal/unavailable, 1 if first is better, 2 if second is better
    func compareBetter(value1: Double?, value2: Double?, lowerIsBetter: Bool = true) -> Int {
        guard let v1 = value1, let v2 = value2 else { return 0 }
        if abs(v1 - v2) < 0.1 { return 0 } // Consider equal if difference < 0.1
        
        if lowerIsBetter {
            return v1 < v2 ? 1 : 2
        } else {
            return v1 > v2 ? 1 : 2
        }
    }
    
    /// Compares grade scores (A is better than E)
    func compareGrades(grade1: String?, grade2: String?) -> Int {
        guard let g1 = grade1?.lowercased(), let g2 = grade2?.lowercased() else { return 0 }
        if g1 == g2 { return 0 }
        if g1 == "n/a" || g1 == "unknown" { return 2 }
        if g2 == "n/a" || g2 == "unknown" { return 1 }
        
        var normalizedG1 = g1
            .replacingOccurrences(of: "-plus", with: "+")
            .replacingOccurrences(of: " plus", with: "+")
            .replacingOccurrences(of: "-minus", with: "-")
            .replacingOccurrences(of: " minus", with: "-")
        
        var normalizedG2 = g2
            .replacingOccurrences(of: "-plus", with: "+")
            .replacingOccurrences(of: " plus", with: "+")
            .replacingOccurrences(of: "-minus", with: "-")
            .replacingOccurrences(of: " minus", with: "-")
            
        let gradeOrder = ["a+", "a", "b", "c", "d", "e"]
        
        // Helper to find best match in gradeOrder
        // If exact match fails, fall back to first character (e.g. "b-" -> "b")
        func getIndex(for grade: String) -> Int? {
            if let index = gradeOrder.firstIndex(of: grade) {
                return index
            }
            // Fallback: try just the first letter
            return gradeOrder.firstIndex(of: String(grade.prefix(1)))
        }
        
        guard let index1 = getIndex(for: normalizedG1),
              let index2 = getIndex(for: normalizedG2) else { return 0 }
        
        return index1 < index2 ? 1 : 2
    }
    
    /// Compares NOVA groups (1 is better than 4)
    func compareNovaGroups(nova1: Int?, nova2: Int?) -> Int {
        guard let n1 = nova1, let n2 = nova2 else { return 0 }
        if n1 == n2 { return 0 }
        return n1 < n2 ? 1 : 2
    }
}
