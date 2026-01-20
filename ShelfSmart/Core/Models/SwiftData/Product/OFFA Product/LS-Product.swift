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
class LSProduct: ProductProtocol {
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

    // Labels (organic, vegan, vegetarian, gluten-free, etc.)
    var labelsTags : [String]? // Labels from Open Food Facts API

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

    // Eco-Score
    var ecoScoreGrade : String? // Eco-score grade (A-E)
    var ecoScoreScore : Int? // Eco-score numeric score

    // NOVA Group
    var novaGroup : Int? // NOVA group classification (1-4)

    // Serving Size
    var servingSize : String? // Serving size (e.g., "240ml", "100g")

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
    
    // NOTE: isExpired, expiryStatus, borderColor, warningDate, daysTillExpiry()
    // are now provided by ProductProtocol extension
    // Keeping overrides here only if they differ from protocol defaults
    
    // Dynamic property to determine product type
    var type: String {
        return "Fetched from OFFA"
    }

    /// Deprecated: Use likeProduct() instead
    @available(*, deprecated, renamed: "likeProduct")
    func LikeProduct() {
        likeProduct()
    }

    init(id: String = UUID().uuidString, barcode: String, title: String, brand: String, quantity: String? = nil, productDescription: String? = nil, imageLink: String? = nil, imageFrontURL: String? = nil, imageIngredientsURL: String? = nil, imageNutritionURL: String? = nil, allergens: String? = nil, allergensTags: [String]? = nil, labelsTags: [String]? = nil, ingredientsText: String? = nil, ingredients: [LSIngredient]? = nil, nutriments: LSNutriments? = nil, nutriscoreGrade: String? = nil, nutriscoreScore: Int? = nil, nutriscoreData: LSNutriscoreData? = nil, ecoScoreGrade: String? = nil, ecoScoreScore: Int? = nil, novaGroup: Int? = nil, servingSize: String? = nil, recipeIds: [Int]? = nil, recipes : [SDOFFARecipe]? = nil, expirationDate: Date, userId: String = "") {
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
        self.labelsTags = labelsTags
        self.ingredientsText = ingredientsText
        self.ingredients = ingredients
        self.nutriments = nutriments
        self.nutriscoreGrade = nutriscoreGrade
        self.nutriscoreScore = nutriscoreScore
        self.nutriscoreData = nutriscoreData
        self.ecoScoreGrade = ecoScoreGrade
        self.ecoScoreScore = ecoScoreScore
        self.novaGroup = novaGroup
        self.servingSize = servingSize
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
            labelsTags: offaProduct.labelsTags,
            ingredientsText: offaProduct.ingredientsText,
            ingredients: lsIngredients,
            nutriments: lsNutriments,
            nutriscoreGrade: offaProduct.nutriscoreGrade,
            nutriscoreScore: offaProduct.nutriscoreScore,
            nutriscoreData: lsNutriscoreData,
            ecoScoreGrade: offaProduct.ecoScoreGrade,
            ecoScoreScore: offaProduct.ecoScoreScore,
            novaGroup: offaProduct.novaGroup,
            servingSize: offaProduct.servingSize,
            recipeIds: recipeIds,
            recipes: recipes,
            expirationDate: expirationDate,
            userId: userId
        )
    }

    // NOTE: markUsed() and daysTillExpiry() are now provided by ProductProtocol extension
}

