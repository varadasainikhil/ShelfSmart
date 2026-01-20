//
//  ProductFirebaseService.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 1/19/26.
//

import Foundation
import FirebaseFirestore

/// Service for caching products to Firebase to reduce API dependency
/// Products are stored in the "products" collection with barcode as document ID
@Observable
class ProductFirebaseService {
    // MARK: - Singleton
    static let shared = ProductFirebaseService()
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    private let collectionName = "sharedProducts"
    
    private init() {}
    
    // MARK: - Fetch Product
    
    /// Fetches a product from Firebase by barcode
    /// - Parameter barcode: The product barcode to search for
    /// - Returns: CompareProduct if found, nil otherwise
    func fetchProduct(barcode: String) async -> CompareProduct? {
        print("🔥 [Firebase] Checking for cached product: \(barcode)")
        
        do {
            let docRef = db.collection(collectionName).document(barcode)
            let document = try await docRef.getDocument()
            
            guard document.exists, let data = document.data() else {
                print("🔥 [Firebase] Product not found in cache: \(barcode)")
                return nil
            }
            
            print("✅ [Firebase] Found cached product: \(barcode)")
            return parseProductFromFirestore(data: data, barcode: barcode)
        } catch {
            print("⚠️ [Firebase] Failed to fetch from cache (proceeding to API): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Fetches OFFA product data from Firebase by barcode for use in AddProductView
    /// - Parameter barcode: The product barcode to search for
    /// - Returns: Tuple of product data (name, description, imageLink, barcode) if found, nil otherwise
    func fetchOFFAProductData(barcode: String) async -> (name: String, description: String?, imageLink: String?, barcode: String)? {
        print("🔥 [Firebase] Checking for cached OFFA product: \(barcode)")
        
        do {
            let docRef = db.collection(collectionName).document(barcode)
            let document = try await docRef.getDocument()
            
            guard document.exists, let data = document.data() else {
                print("🔥 [Firebase] OFFA product not found in cache: \(barcode)")
                return nil
            }
            
            print("✅ [Firebase] Found cached OFFA product: \(barcode)")
            
            let name = data["title"] as? String ?? "Unknown Product"
            let description = data["ingredientsText"] as? String
            
            // Get image from nested structure or flat structure
            var imageLink: String? = nil
            if let imagesMap = data["images"] as? [String: Any] {
                imageLink = imagesMap["front"] as? String
            }
            if imageLink == nil {
                imageLink = data["imageURL"] as? String
            }
            
            return (name: name, description: description, imageLink: imageLink, barcode: barcode)
        } catch {
            print("⚠️ [Firebase] Failed to fetch OFFA product from cache: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Save Product
    
    /// Saves a product to Firebase for future caching
    /// - Parameter product: The CompareProduct to cache
    func saveProduct(_ product: CompareProduct) async throws {
        print("🔥 [Firebase] Caching product: \(product.barcode)")
        
        let data = convertProductToFirestoreData(product)
        
        try await db.collection(collectionName).document(product.barcode).setData(data, merge: true)
        
        print("✅ [Firebase] Product cached successfully: \(product.barcode)")
    }
    
    // MARK: - Check if Product Exists
    
    /// Checks if a product exists in Firebase cache
    /// - Parameter barcode: The product barcode to check
    /// - Returns: true if product exists in cache
    func productExists(barcode: String) async -> Bool {
        do {
            let docRef = db.collection(collectionName).document(barcode)
            let document = try await docRef.getDocument()
            return document.exists
        } catch {
            print("❌ [Firebase] Error checking product existence: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Save OFFA Product
    
    /// Saves an OFFAProduct to Firebase for caching
    /// - Parameter product: The OFFAProduct to cache
    func saveOFFAProduct(_ product: OFFAProduct) async throws {
        print("🔥 [Firebase] Caching OFFA product: \(product.code)")
        
        let data = convertOFFAProductToFirestoreData(product)
        
        try await db.collection(collectionName).document(product.code).setData(data, merge: true)
        
        print("✅ [Firebase] OFFA product cached successfully: \(product.code)")
    }
    
    /// Saves an OFFAProduct to Firebase only if it doesn't already exist
    /// This is a convenience method that combines existence check + save
    /// Errors are logged but not thrown to avoid blocking the user flow
    /// - Parameter product: The OFFAProduct to cache
    func saveOFFAProductIfNotExists(_ product: OFFAProduct) async {
        do {
            let exists = await productExists(barcode: product.code)
            
            if exists {
                print("🔥 [Firebase] OFFA product already exists, skipping upload: \(product.code)")
                return
            }
            
            try await saveOFFAProduct(product)
        } catch {
            print("❌ [Firebase] Failed to cache OFFA product (non-blocking): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Helpers
    
    /// Converts OFFAProduct to Firestore-compatible dictionary
    private func convertOFFAProductToFirestoreData(_ product: OFFAProduct) -> [String: Any] {
        var data: [String: Any] = [
            "barcode": product.code,
            "cachedAt": FieldValue.serverTimestamp()
        ]
        
        // Basic info
        if let productName = product.productName { data["title"] = productName }
        if let brands = product.brands { data["brand"] = brands }
        if let quantity = product.quantity { data["quantity"] = quantity }
        if let servingSize = product.servingSize { data["servingSize"] = servingSize }
        if let ingredientsText = product.ingredientsText { data["ingredientsText"] = ingredientsText }
        
        // Images
        var imagesMap: [String: Any] = [:]
        if let front = product.imageFrontURL ?? product.imageURL { imagesMap["front"] = front }
        if let ingredients = product.imageIngredientsURL { imagesMap["ingredients"] = ingredients }
        if let nutrition = product.imageNutritionURL { imagesMap["nutrition"] = nutrition }
        if !imagesMap.isEmpty { data["images"] = imagesMap }
        
        // Nutrition
        if let nutriments = product.nutriments {
            var nutritionMap: [String: Any] = [:]
            if let calories = nutriments.energyKcal { nutritionMap["calories"] = calories }
            if let caloriesUnit = nutriments.energyKcalUnit { nutritionMap["caloriesUnit"] = caloriesUnit }
            if let sugar = nutriments.sugars { nutritionMap["sugar"] = sugar }
            if let sugarUnit = nutriments.sugarsUnit { nutritionMap["sugarUnit"] = sugarUnit }
            if let protein = nutriments.proteins { nutritionMap["protein"] = protein }
            if let proteinUnit = nutriments.proteinsUnit { nutritionMap["proteinUnit"] = proteinUnit }
            if let fat = nutriments.fat { nutritionMap["fat"] = fat }
            if let fatUnit = nutriments.fatUnit { nutritionMap["fatUnit"] = fatUnit }
            if let saturatedFat = nutriments.saturatedFat { nutritionMap["saturatedFat"] = saturatedFat }
            if let saturatedFatUnit = nutriments.saturatedFatUnit { nutritionMap["saturatedFatUnit"] = saturatedFatUnit }
            if let fiber = nutriments.fiber { nutritionMap["fiber"] = fiber }
            if let salt = nutriments.salt { nutritionMap["salt"] = salt }
            if let saltUnit = nutriments.saltUnit { nutritionMap["saltUnit"] = saltUnit }
            if let sodium = nutriments.sodium { nutritionMap["sodium"] = sodium }
            if let sodiumUnit = nutriments.sodiumUnit { nutritionMap["sodiumUnit"] = sodiumUnit }
            if let carbohydrates = nutriments.carbohydrates { nutritionMap["carbohydrates"] = carbohydrates }
            if let carbohydratesUnit = nutriments.carbohydratesUnit { nutritionMap["carbohydratesUnit"] = carbohydratesUnit }
            if !nutritionMap.isEmpty { data["nutrition"] = nutritionMap }
        }
        
        // Scores
        var scoresMap: [String: Any] = [:]
        if let nutriscoreGrade = product.nutriscoreGrade { scoresMap["nutriscoreGrade"] = nutriscoreGrade }
        if let nutriscoreScore = product.nutriscoreScore { scoresMap["nutriscoreScore"] = nutriscoreScore }
        if let ecoscoreGrade = product.ecoScoreGrade { scoresMap["ecoscoreGrade"] = ecoscoreGrade }
        if let ecoscoreScore = product.ecoScoreScore { scoresMap["ecoscoreScore"] = ecoscoreScore }
        if let novaGroup = product.novaGroup { scoresMap["novaGroup"] = novaGroup }
        if !scoresMap.isEmpty { data["scores"] = scoresMap }
        
        // Metadata
        var metadataMap: [String: Any] = [:]
        if let allergens = product.allergens { metadataMap["allergens"] = allergens }
        if let allergensTags = product.allergensTags { metadataMap["allergensTags"] = allergensTags }
        if let labelsTags = product.labelsTags { metadataMap["labelsTags"] = labelsTags }
        if !metadataMap.isEmpty { data["metadata"] = metadataMap }
        
        return data
    }
    
    /// Converts CompareProduct to Firestore-compatible dictionary
    private func convertProductToFirestoreData(_ product: CompareProduct) -> [String: Any] {
        // Top-level fields
        var data: [String: Any] = [
            "barcode": product.barcode,
            "title": product.title,
            "cachedAt": FieldValue.serverTimestamp()
        ]
        
        if let brand = product.brand { data["brand"] = brand }
        if let quantity = product.quantity { data["quantity"] = quantity }
        if let servingSize = product.servingSize { data["servingSize"] = servingSize }
        if let ingredientsText = product.ingredientsText { data["ingredientsText"] = ingredientsText }
        
        // Nested: Images
        // If we were uploading, we would structure this as a map.
        // For now, we keep the flat structure for backward compatibility if we were to re-enable upload without migration,
        // BUT the user asked for hierarchy. So let's write hierarchically if we were to write.
        
        var imagesMap: [String: Any] = [:]
        if let front = product.images.front { imagesMap["front"] = front }
        if let ingredients = product.images.ingredients { imagesMap["ingredients"] = ingredients }
        if let nutrition = product.images.nutrition { imagesMap["nutrition"] = nutrition }
        if !imagesMap.isEmpty { data["images"] = imagesMap }
        
        // Nested: Nutrition
        var nutritionMap: [String: Any] = [:]
        if let calories = product.nutrition.calories { nutritionMap["calories"] = calories }
        if let caloriesUnit = product.nutrition.caloriesUnit { nutritionMap["caloriesUnit"] = caloriesUnit }
        if let sugar = product.nutrition.sugar { nutritionMap["sugar"] = sugar }
        if let sugarUnit = product.nutrition.sugarUnit { nutritionMap["sugarUnit"] = sugarUnit }
        if let protein = product.nutrition.protein { nutritionMap["protein"] = protein }
        if let proteinUnit = product.nutrition.proteinUnit { nutritionMap["proteinUnit"] = proteinUnit }
        if let fat = product.nutrition.fat { nutritionMap["fat"] = fat }
        if let fatUnit = product.nutrition.fatUnit { nutritionMap["fatUnit"] = fatUnit }
        if let saturatedFat = product.nutrition.saturatedFat { nutritionMap["saturatedFat"] = saturatedFat }
        if let saturatedFatUnit = product.nutrition.saturatedFatUnit { nutritionMap["saturatedFatUnit"] = saturatedFatUnit }
        if let fiber = product.nutrition.fiber { nutritionMap["fiber"] = fiber }
        if let salt = product.nutrition.salt { nutritionMap["salt"] = salt }
        if let saltUnit = product.nutrition.saltUnit { nutritionMap["saltUnit"] = saltUnit }
        if let sodium = product.nutrition.sodium { nutritionMap["sodium"] = sodium }
        if let sodiumUnit = product.nutrition.sodiumUnit { nutritionMap["sodiumUnit"] = sodiumUnit }
        if let carbohydrates = product.nutrition.carbohydrates { nutritionMap["carbohydrates"] = carbohydrates }
        if let carbohydratesUnit = product.nutrition.carbohydratesUnit { nutritionMap["carbohydratesUnit"] = carbohydratesUnit }
        if !nutritionMap.isEmpty { data["nutrition"] = nutritionMap }
        
        // Nested: Scores
        var scoresMap: [String: Any] = [:]
        if let nutriscoreGrade = product.scores.nutriscoreGrade { scoresMap["nutriscoreGrade"] = nutriscoreGrade }
        if let nutriscoreScore = product.scores.nutriscoreScore { scoresMap["nutriscoreScore"] = nutriscoreScore }
        if let ecoscoreGrade = product.scores.ecoscoreGrade { scoresMap["ecoscoreGrade"] = ecoscoreGrade }
        if let ecoscoreScore = product.scores.ecoscoreScore { scoresMap["ecoscoreScore"] = ecoscoreScore }
        if let novaGroup = product.scores.novaGroup { scoresMap["novaGroup"] = novaGroup }
        if !scoresMap.isEmpty { data["scores"] = scoresMap }
        
        // Nested: Metadata
        var metadataMap: [String: Any] = [:]
        if let allergens = product.metadata.allergens { metadataMap["allergens"] = allergens }
        if let allergensTags = product.metadata.allergensTags { metadataMap["allergensTags"] = allergensTags }
        if let labelsTags = product.metadata.labelsTags { metadataMap["labelsTags"] = labelsTags }
        if let positives = product.metadata.positives { metadataMap["positives"] = positives }
        if let negatives = product.metadata.negatives { metadataMap["negatives"] = negatives }
        if !metadataMap.isEmpty { data["metadata"] = metadataMap }
        
        return data
    }
    
    /// Parses Firestore document data into a CompareProduct
    private func parseProductFromFirestore(data: [String: Any], barcode: String) -> CompareProduct {
        // Helper to extract from map or fallback to top-level
        func doubleVal(_ map: [String: Any]?, _ key: String) -> Double? {
            return (map?[key] as? Double) ?? (data[key] as? Double)
        }
        
        func stringVal(_ map: [String: Any]?, _ key: String) -> String? {
            return (map?[key] as? String) ?? (data[key] as? String)
        }
        
        func intVal(_ map: [String: Any]?, _ key: String) -> Int? {
            return (map?[key] as? Int) ?? (data[key] as? Int)
        }
        
        func stringArray(_ map: [String: Any]?, _ key: String) -> [String]? {
            return (map?[key] as? [String]) ?? (data[key] as? [String])
        }
        
        // Extract nested maps if available
        let imagesMap = data["images"] as? [String: Any]
        let nutritionMap = data["nutrition"] as? [String: Any]
        let scoresMap = data["scores"] as? [String: Any]
        let metadataMap = data["metadata"] as? [String: Any]
        
        return CompareProduct(
            id: UUID().uuidString,
            barcode: barcode,
            title: data["title"] as? String ?? "Unknown Product",
            brand: data["brand"] as? String,
            quantity: data["quantity"] as? String,
            servingSize: data["servingSize"] as? String,
            ingredientsText: data["ingredientsText"] as? String,
            
            images: CompareProduct.ProductImages(
                front: stringVal(imagesMap, "front") ?? (data["imageURL"] as? String),
                ingredients: stringVal(imagesMap, "ingredients") ?? (data["imageIngredientsURL"] as? String),
                nutrition: stringVal(imagesMap, "nutrition") ?? (data["imageNutritionURL"] as? String)
            ),
            
            nutrition: CompareProduct.ProductNutriments(
                calories: doubleVal(nutritionMap, "calories"),
                caloriesUnit: stringVal(nutritionMap, "caloriesUnit"),
                sugar: doubleVal(nutritionMap, "sugar"),
                sugarUnit: stringVal(nutritionMap, "sugarUnit"),
                protein: doubleVal(nutritionMap, "protein"),
                proteinUnit: stringVal(nutritionMap, "proteinUnit"),
                fat: doubleVal(nutritionMap, "fat"),
                fatUnit: stringVal(nutritionMap, "fatUnit"),
                saturatedFat: doubleVal(nutritionMap, "saturatedFat"),
                saturatedFatUnit: stringVal(nutritionMap, "saturatedFatUnit"),
                fiber: doubleVal(nutritionMap, "fiber"),
                salt: doubleVal(nutritionMap, "salt"),
                saltUnit: stringVal(nutritionMap, "saltUnit"),
                sodium: doubleVal(nutritionMap, "sodium"),
                sodiumUnit: stringVal(nutritionMap, "sodiumUnit"),
                carbohydrates: doubleVal(nutritionMap, "carbohydrates"),
                carbohydratesUnit: stringVal(nutritionMap, "carbohydratesUnit")
            ),
            
            scores: CompareProduct.ProductScores(
                nutriscoreGrade: stringVal(scoresMap, "nutriscoreGrade"),
                nutriscoreScore: intVal(scoresMap, "nutriscoreScore"),
                ecoscoreGrade: stringVal(scoresMap, "ecoscoreGrade"),
                ecoscoreScore: intVal(scoresMap, "ecoscoreScore"),
                novaGroup: intVal(scoresMap, "novaGroup")
            ),
            
            metadata: CompareProduct.ProductMetadata(
                allergens: stringVal(metadataMap, "allergens"),
                allergensTags: stringArray(metadataMap, "allergensTags"),
                labelsTags: stringArray(metadataMap, "labelsTags"),
                positives: stringArray(metadataMap, "positives"),
                negatives: stringArray(metadataMap, "negatives")
            )
        )
    }
}
