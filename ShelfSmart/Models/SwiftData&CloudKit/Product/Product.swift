//
//  product.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/25/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class Product{
    var id : Int? // Spoonacular API ID
    var manualId : String? // UUID for manually created products
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
    
    // Relationships
    @Relationship(deleteRule: .cascade)
    var credits: Credit?
    
    @Relationship(inverse: \GroupedProducts.products)
    var groupedProducts: GroupedProducts?

    
    var isExpired : Bool{
        let daysTillExpiry = daysTillExpiry().count
        if daysTillExpiry >= 0 {
            return false
        }
        return true
    }
    
    // Dynamic property to determine product type
    var type: String {
        if id != nil {
            return "Fetched from Spoonacular"
        } else if manualId != nil {
            return "Manual Entry"
        } else {
            return "Unknown"
        }
    }
    
    
    func LikeProduct(){
        self.isLiked.toggle()
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
    
    init(id: Int?, manualId: String? = nil, barcode: String, title: String, brand: String, breadcrumbs : [String]?, badges: [String]? = nil, importantBadges: [String]? = nil, spoonacularScore: Double? = nil, productDescription: String? = nil, imageLink: String? = nil, moreImageLinks: [String]? = nil, generatedText: String? = nil, ingredientCount: Int? = nil, recipeIds: [Int]? = nil, recipes : [SDRecipe]? = nil, credits: Credit? = nil, expirationDate: Date) {
        self.id = id
        self.manualId = manualId
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
    }

    // Convenience initializer for manual products (no Spoonacular ID required)
    convenience init(barcode: String, title: String, brand: String,breadcrumbs : [String]? = nil, badges: [String]? = nil, importantBadges: [String]? = nil, spoonacularScore: Double? = nil, productDescription: String? = nil, imageLink: String? = nil, moreImageLinks: [String]? = nil, generatedText: String? = nil, ingredientCount: Int? = nil, recipeIds: [Int]? = nil, recipes : [SDRecipe]? = nil, credits: Credit? = nil, expirationDate: Date) {
        self.init(id: nil, manualId: UUID().uuidString, barcode: barcode, title: title, brand: brand,breadcrumbs: breadcrumbs, badges: badges, importantBadges: importantBadges, spoonacularScore: spoonacularScore, productDescription: productDescription, imageLink: imageLink, moreImageLinks: moreImageLinks, generatedText: generatedText, ingredientCount: ingredientCount, recipeIds: recipeIds,recipes: recipes, credits: credits, expirationDate: expirationDate)
    }

    // Convenience initializer for GroceryProduct (from Spoonacular API)
    convenience init(from groceryProduct: GroceryProduct, expirationDate: Date, recipeIds: [Int]? = nil, recipes: [SDRecipe]? = nil) {
        // Convert SpoonacularCredit to Credit if available
        let credit: Credit? = {
            if let spoonCredit = groceryProduct.credits {
                return Credit(text: spoonCredit.text, link: spoonCredit.link, image: spoonCredit.image, imageLink: spoonCredit.imageLink)
            }
            return nil
        }()

        self.init(
            id: groceryProduct.id,
            manualId: nil, // API products don't have manualId
            barcode: groceryProduct.upc ?? "",
            title: groceryProduct.title ?? "Unknown Product",
            brand: groceryProduct.brand ?? "",
            breadcrumbs: groceryProduct.breadcrumbs,
            badges: groceryProduct.badges,
            importantBadges: groceryProduct.importantBadges,
            spoonacularScore: groceryProduct.spoonacularScore,
            productDescription: groceryProduct.description,
            imageLink: groceryProduct.image,
            moreImageLinks: groceryProduct.images,
            generatedText: groceryProduct.generatedText,
            ingredientCount: groceryProduct.ingredientCount,
            recipeIds: recipeIds,
            recipes: recipes,
            credits: credit,
            expirationDate: expirationDate
        )
    }

    func markUsed() {
        withAnimation {
            self.isUsed = true
        }
    }
    
    // Calculate the days left for expiry
    func daysTillExpiry() -> (message : String, count : Int){
        var textToShow = ""
        let dateTillExpiration = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: expirationDate))
        guard let daysTillExpiration = dateTillExpiration.day else { return (message : "could not calculate days for expiration" , count : 0) }
        if daysTillExpiration > 0 {
            textToShow = "\(daysTillExpiration) Days left"
        }
        else if daysTillExpiration == 0 {
            textToShow = "Expiring Today"
        }
        else if daysTillExpiration == -1 {
            textToShow = "Expired Yesterday"
        }
        else {
            textToShow = "Expired \(-daysTillExpiration) Days ago"
        }
        return (message : textToShow, count: daysTillExpiration)
    }
}
