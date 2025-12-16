//
//  QuickScanViewModel.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 12/10/25.
//

import Firebase
import FirebaseFunctions
import Foundation
import Observation

@Observable
class QuickScanViewModel {
    // MARK: - Input State
    var barcode: String = ""

    // MARK: - Loading State
    var isLoading: Bool = false

    // MARK: - Error State
    var errorMessage: String?
    var showError: Bool = false

    // MARK: - Product Result State
    var productFound: Bool = false
    var showProductSheet: Bool = false

    // Product Details
    var productName: String?
    var productBrand: String?
    var productQuantity: String?
    var productImageURL: String?
    var nutriscoreGrade: String?
    var novaGroup: Int?
    var ecoScoreGrade: String?
    var source: String?

    // Nutriments
    var energyKcal: Double?
    var fat: Double?
    var carbohydrates: Double?
    var proteins: Double?
    var sugars: Double?

    // Creating an instance of functions
    @ObservationIgnored lazy var functions = Functions.functions()

    // MARK: - Fetch Product
    /// Fetch product from cloud function (checks cache first, then calls OFF API)
    func fetchProduct() {
        guard !barcode.isEmpty else {
            showErrorMessage("Please enter a barcode")
            return
        }

        performFetch(barcode: barcode)
    }

    /// Fetch product after scanning
    func fetchProductFromScan(_ scannedBarcode: String) {
        barcode = scannedBarcode
        performFetch(barcode: scannedBarcode)
    }

    private func performFetch(barcode: String) {
        isLoading = true
        clearError()
        clearProductData()

        let callable = functions.httpsCallable("fetchProduct")
        let dataToSend = ["barcode": barcode]

        callable.call(dataToSend) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    self?.showErrorMessage(error.localizedDescription)
                    return
                }

                guard let data = result?.data as? [String: Any] else {
                    self?.showErrorMessage("Invalid response from server")
                    return
                }

                // Parse the response
                let status = data["status"] as? String ?? "unknown"
                self?.source = data["source"] as? String

                if status == "found",
                   let product = data["product"] as? [String: Any] {
                    self?.parseProduct(product)
                    self?.productFound = true
                    self?.showProductSheet = true
                    print("Product found: \(product["productName"] ?? "Unknown")")
                    print("Source: \(self?.source ?? "unknown")")
                } else {
                    self?.productFound = false
                    self?.showErrorMessage("Product not found in Open Food Facts database")
                }
            }
        }
    }

    // MARK: - Parse Product Data
    private func parseProduct(_ product: [String: Any]) {
        // DEBUG: Print all product keys to see what's available
        print("📦 Product keys: \(product.keys.sorted())")
        print("📦 Full product data: \(product)")
        
        productName = product["productName"] as? String
        productBrand = product["brands"] as? String
        productQuantity = product["quantity"] as? String
        
        // Get image URL with proper fallback (handle empty strings)
        let frontURL = product["imageFrontURL"] as? String
        let fallbackURL = product["imageURL"] as? String
        
        // DEBUG: Print image URL values
        print("🖼️ imageFrontURL: \(String(describing: frontURL))")
        print("🖼️ imageURL: \(String(describing: fallbackURL))")
        
        // Properly check both URLs for non-empty values
        var imageURL: String? = nil
        if let front = frontURL, !front.isEmpty {
            imageURL = front
        } else if let fallback = fallbackURL, !fallback.isEmpty {
            imageURL = fallback
        }

        // Ensure HTTPS (iOS blocks HTTP by default)
        if let url = imageURL, url.hasPrefix("http://") {
            imageURL = url.replacingOccurrences(of: "http://", with: "https://")
        }
        
        // DEBUG: Print final image URL
        print("🖼️ Final productImageURL: \(String(describing: imageURL))")
        
        productImageURL = imageURL
        nutriscoreGrade = product["nutriscoreGrade"] as? String
        novaGroup = product["novaGroup"] as? Int
        ecoScoreGrade = product["ecoScoreGrade"] as? String

        // Parse nutriments
        if let nutriments = product["nutriments"] as? [String: Any] {
            energyKcal = nutriments["energyKcal"] as? Double
            fat = nutriments["fat"] as? Double
            carbohydrates = nutriments["carbohydrates"] as? Double
            proteins = nutriments["proteins"] as? Double
            sugars = nutriments["sugars"] as? Double
        }
    }

    // MARK: - Error Handling
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }

    private func clearError() {
        errorMessage = nil
        showError = false
    }

    // MARK: - Clear Product Data
    private func clearProductData() {
        productFound = false
        productName = nil
        productBrand = nil
        productQuantity = nil
        productImageURL = nil
        nutriscoreGrade = nil
        novaGroup = nil
        ecoScoreGrade = nil
        source = nil
        energyKcal = nil
        fat = nil
        carbohydrates = nil
        proteins = nil
        sugars = nil
    }

    // MARK: - Reset All State
    func reset() {
        barcode = ""
        isLoading = false
        clearError()
        clearProductData()
        showProductSheet = false
    }

    // MARK: - Dismiss Sheet
    func dismissSheet() {
        showProductSheet = false
    }
}
