//
//  Product.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/25/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class Product: ProductProtocol {
    var id : String = UUID().uuidString // Unique identifier for each product instance
    var spoonacularId : Int? // Spoonacular API ID (nil for manual products)
    var barcode : String = ""
    var title : String = ""
    var brand : String?
    var breadcrumbs : [String]?
    var badges : [String]? = [String]()
    var importantBadges : [String]? = [String]()
    var spoonacularScore: Double?
    var productDescription : String?
    var imageLink : String?
    var moreImageLinks : [String]? = [String]()
    var generatedText : String?
    var ingredientCount : Int?
    var recipeIds : [Int]? = [Int]() // Array of recipe IDs found for this product

    // One-to-many relationship with SDRecipe
    @Relationship(deleteRule: .nullify, inverse: \SDRecipe.product)
    var recipes : [SDRecipe]? = [SDRecipe]()

    var dateAdded : Date = Date.now
    var expirationDate : Date = Date.now
    var isUsed : Bool = false
    var isLiked : Bool = false
    var userId : String = "" // Track which user owns this product

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \Credit.product)
    var credits: Credit?

    @Relationship(inverse: \GroupedProducts.products)
    var groupedProducts: GroupedProducts?
    
    var warningNotificationId: String {
        return "\(id)_warning_notification_id"
    }

    var expirationNotificationId: String {
        return "\(id)_expiration_notification_id"
    }
    
    // NOTE: isExpired, expiryStatus, borderColor, warningDate, daysTillExpiry(), markUsed(), likeProduct()
    // are now provided by ProductProtocol extension
    
    // Dynamic property to determine product type
    var type: String {
        if spoonacularId != nil {
            return "Fetched from Spoonacular"
        } else {
            return "Manual Entry"
        }
    }
    
    /// Deprecated: Use likeProduct() instead
    @available(*, deprecated, renamed: "likeProduct")
    func LikeProduct() {
        likeProduct()
    }
    
    // MARK: - Initializers
    
    init(id: String = UUID().uuidString, spoonacularId: Int? = nil, barcode: String, title: String, brand: String, breadcrumbs: [String]?, badges: [String]? = nil, importantBadges: [String]? = nil, spoonacularScore: Double? = nil, productDescription: String? = nil, imageLink: String? = nil, moreImageLinks: [String]? = nil, generatedText: String? = nil, ingredientCount: Int? = nil, recipeIds: [Int]? = nil, recipes: [SDRecipe]? = nil, credits: Credit? = nil, expirationDate: Date, userId: String = "") {
        self.id = id
        self.spoonacularId = spoonacularId
        self.barcode = barcode
        self.title = title
        self.brand = brand
        self.breadcrumbs = breadcrumbs
        self.badges = badges
        self.importantBadges = importantBadges
        self.spoonacularScore = spoonacularScore
        self.productDescription = productDescription
        self.imageLink = imageLink
        self.moreImageLinks = moreImageLinks
        self.generatedText = generatedText
        self.ingredientCount = ingredientCount
        self.recipeIds = recipeIds
        self.recipes = recipes
        self.credits = credits
        self.dateAdded = .now
        self.expirationDate = expirationDate
        self.isUsed = false
        self.isLiked = false
        self.userId = userId
    }

    // Convenience initializer for manual products (no Spoonacular ID required)
    convenience init(barcode: String, title: String, brand: String, breadcrumbs: [String]? = nil, badges: [String]? = nil, importantBadges: [String]? = nil, spoonacularScore: Double? = nil, productDescription: String? = nil, imageLink: String? = nil, moreImageLinks: [String]? = nil, generatedText: String? = nil, ingredientCount: Int? = nil, recipeIds: [Int]? = nil, recipes: [SDRecipe]? = nil, credits: Credit? = nil, expirationDate: Date, userId: String = "") {
        self.init(id: UUID().uuidString, spoonacularId: nil, barcode: barcode, title: title, brand: brand, breadcrumbs: breadcrumbs, badges: badges, importantBadges: importantBadges, spoonacularScore: spoonacularScore, productDescription: productDescription, imageLink: imageLink, moreImageLinks: moreImageLinks, generatedText: generatedText, ingredientCount: ingredientCount, recipeIds: recipeIds, recipes: recipes, credits: credits, expirationDate: expirationDate, userId: userId)
    }

    // Convenience initializer from GroceryProduct (from Spoonacular API)
    convenience init(from groceryProduct: GroceryProduct, expirationDate: Date, userId: String = "") {
        // Create Credit if available
        let credit = groceryProduct.credits.map { Credit(from: $0) }

        self.init(
            id: UUID().uuidString,
            spoonacularId: groceryProduct.id,
            barcode: groceryProduct.upc?.cleanHTMLText ?? "",
            title: groceryProduct.title?.cleanHTMLText ?? "",
            brand: groceryProduct.brand?.cleanHTMLText ?? "",
            breadcrumbs: groceryProduct.breadcrumbs,
            badges: groceryProduct.badges,
            importantBadges: groceryProduct.importantBadges,
            spoonacularScore: groceryProduct.spoonacularScore,
            productDescription: groceryProduct.description?.cleanHTMLText,
            imageLink: groceryProduct.image?.cleanHTMLText,
            moreImageLinks: groceryProduct.images,
            generatedText: groceryProduct.generatedText?.cleanHTMLText,
            ingredientCount: groceryProduct.ingredientCount,
            recipeIds: nil,
            recipes: nil,
            credits: credit,
            expirationDate: expirationDate,
            userId: userId
        )
    }
}

// Enum to track different expiry states
enum ExpiryStatus {
    case fresh
    case expiringSoon
    case expired
}
