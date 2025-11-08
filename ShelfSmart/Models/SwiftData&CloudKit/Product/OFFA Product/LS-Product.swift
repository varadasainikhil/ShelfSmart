//
//  LS-Product.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 11/7/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class LSProduct {
    var id : String = UUID().uuidString // Unique identifier for each product instance
    var barcode : String = ""
    var title : String = ""
    var brand : String?
    var quantity : String? // Product size/quantity (e.g., "500g", "1L")
    var productDescription : String?

    // Images
    var imageLink : String? // Main image URL
    var imageFrontURL : String? // Front of package image
    var imageIngredientsURL : String? // Ingredients list image
    var imageNutritionURL : String? // Nutrition facts image

    // Allergens
    var allergens : String? // Allergens as comma-separated string
    var allergensTags : [String]? // Allergens as array

    // Ingredients
    var ingredientsText : String? // Plain text ingredients (backup)
    @Relationship(deleteRule: .cascade, inverse: \LSIngredient.product)
    var ingredients : [LSIngredient]? // Structured ingredient data

    // Nutrition (per 100g)
    @Relationship(deleteRule: .cascade, inverse: \LSNutriments.product)
    var nutriments : LSNutriments? // Detailed nutritional information

    // Nutri-Score
    var nutriscoreGrade : String? // Nutriscore grade (A-E)
    var nutriscoreScore : Int? // Nutriscore numeric score
    @Relationship(deleteRule: .cascade, inverse: \LSNutriscoreData.product)
    var nutriscoreData : LSNutriscoreData? // Detailed nutriscore data

    var recipeIds : [Int]? = [Int]() // Array of recipe IDs found for this product

    // One-to-many relationship with SDOFFARecipe
    @Relationship(deleteRule: .nullify, inverse: \SDOFFARecipe.product)
    var recipes : [SDOFFARecipe]? = [SDOFFARecipe]()

    var dateAdded : Date = Date.now
    var expirationDate : Date = Date.now
    var isUsed : Bool = false
    var isLiked : Bool = false
    var userId : String = "" // Track which user owns this product

    // Relationship with GroupedOFFAProducts
    @Relationship(inverse: \GroupedOFFAProducts.offaProducts)
    var groupedProducts: GroupedOFFAProducts?
    
    var warningNotificationId: String {
        return "\(id)_warning_notification_id"
    }

    var expirationNotificationId: String {
        return "\(id)_expiration_notification_id"
    }
    
    var isExpired : Bool{
        let daysTillExpiry = daysTillExpiry().count
        if daysTillExpiry >= 0 {
            return false
        }
        return true
    }
    
    // Dynamic property to determine product type
    var type: String {
        return "Fetched from OFFA"
    }

    
    func LikeProduct(){
        self.isLiked.toggle()
    }
    
    var expiryStatus : ExpiryStatus {
        if isExpired {
            return .expired
        }
        else {
            let daysTillExpiryDictionary = daysTillExpiry()
            if daysTillExpiryDictionary.count >= 7 {
                return .expiringSoon
            }
            return .fresh
        }
    }
    
    var borderColor : Color {
        if isExpired {
            return .red
        }
        else {
            let daysTillExpiryDictionary = daysTillExpiry()
            if daysTillExpiryDictionary.count >= 7 {
                return .green
            }
            return .yellow
        }
    }
    
    var warningDate: Date? {
        Calendar.current.date(byAdding: .day, value: -7, to: expirationDate)
    }

    init(id: String = UUID().uuidString, barcode: String, title: String, brand: String, quantity: String? = nil, productDescription: String? = nil, imageLink: String? = nil, imageFrontURL: String? = nil, imageIngredientsURL: String? = nil, imageNutritionURL: String? = nil, allergens: String? = nil, allergensTags: [String]? = nil, ingredientsText: String? = nil, ingredients: [LSIngredient]? = nil, nutriments: LSNutriments? = nil, nutriscoreGrade: String? = nil, nutriscoreScore: Int? = nil, nutriscoreData: LSNutriscoreData? = nil, recipeIds: [Int]? = nil, recipes : [SDOFFARecipe]? = nil, expirationDate: Date, userId: String = "") {
        self.id = id
        self.barcode = barcode
        self.title = title
        self.brand = brand
        self.quantity = quantity
        self.productDescription = productDescription
        self.imageLink = imageLink
        self.imageFrontURL = imageFrontURL
        self.imageIngredientsURL = imageIngredientsURL
        self.imageNutritionURL = imageNutritionURL
        self.allergens = allergens
        self.allergensTags = allergensTags
        self.ingredientsText = ingredientsText
        self.ingredients = ingredients
        self.nutriments = nutriments
        self.nutriscoreGrade = nutriscoreGrade
        self.nutriscoreScore = nutriscoreScore
        self.nutriscoreData = nutriscoreData
        self.recipeIds = recipeIds
        self.recipes = recipes
        self.dateAdded = .now
        self.expirationDate = expirationDate
        self.isUsed = false
        self.isLiked = false
        self.userId = userId
    }

    // Convenience initializer for manual products
    convenience init(barcode: String, title: String, brand: String, quantity: String? = nil, productDescription: String? = nil, imageLink: String? = nil, recipeIds: [Int]? = nil, recipes : [SDOFFARecipe]? = nil, expirationDate: Date, userId: String = "") {
        self.init(id: UUID().uuidString, barcode: barcode, title: title, brand: brand, quantity: quantity, productDescription: productDescription, imageLink: imageLink, recipeIds: recipeIds, recipes: recipes, expirationDate: expirationDate, userId: userId)
    }

    // Convenience initializer from OFFAProduct (from OFFA API)
    convenience init(from offaProduct: OFFAProduct, recipeIds: [Int]? = nil, recipes: [SDOFFARecipe]? = nil, expirationDate: Date, userId: String = "") {
        // Convert OFFAIngredient array to LSIngredient array
        let lsIngredients = offaProduct.ingredients?.map { LSIngredient(from: $0) }

        // Convert OFFANutriments to LSNutriments
        let lsNutriments = offaProduct.nutriments.map { LSNutriments(from: $0) }

        // Convert OFFANutriscoreData to LSNutriscoreData
        let lsNutriscoreData = offaProduct.nutriscoreData.map { LSNutriscoreData(from: $0) }

        self.init(
            id: UUID().uuidString,
            barcode: offaProduct.code,
            title: offaProduct.productName ?? "Unknown Product",
            brand: offaProduct.brands ?? "",
            quantity: offaProduct.quantity,
            productDescription: nil,
            imageLink: offaProduct.imageURL,
            imageFrontURL: offaProduct.imageFrontURL,
            imageIngredientsURL: offaProduct.imageIngredientsURL,
            imageNutritionURL: offaProduct.imageNutritionURL,
            allergens: offaProduct.allergens,
            allergensTags: offaProduct.allergensTags,
            ingredientsText: offaProduct.ingredientsText,
            ingredients: lsIngredients,
            nutriments: lsNutriments,
            nutriscoreGrade: offaProduct.nutriscoreGrade,
            nutriscoreScore: offaProduct.nutriscoreScore,
            nutriscoreData: lsNutriscoreData,
            recipeIds: recipeIds,
            recipes: recipes,
            expirationDate: expirationDate,
            userId: userId
        )
    }

    func markUsed() {
        withAnimation {
            self.isUsed = true
        }
    }

    // Calculate the days left for expiry
    func daysTillExpiry() -> (message : String, count : Int){
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expiry = calendar.startOfDay(for: expirationDate)
        
        let components = calendar.dateComponents([.day], from: today, to: expiry)
        
        guard let days = components.day else {
            return ("Error calculating days", 0)
        }
        
        if days < 0 {
            return ("Expired \(abs(days)) day\(abs(days) == 1 ? "" : "s") ago", days)
        } else if days == 0 {
            return ("Expires today", days)
        } else if days == 1 {
            return ("Expires tomorrow", days)
        } else {
            return ("Expires in \(days) days", days)
        }
    }
}

