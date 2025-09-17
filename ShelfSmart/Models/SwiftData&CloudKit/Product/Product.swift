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
    var id : Int?
    var barcode : String = ""
    var title : String = ""
    var brand : String?
    var badges : [String]?
    var importantBadges : [String]?
    var spoonacularScore: Double?
    var productDescription : String?
    var imageLink : String?
    var moreImageLinks : [String]?
    var generatedText : String?
    var ingredientCount : Int?
    
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
    
    init(id: Int, barcode: String, title: String, brand: String, badges: [String]? = nil, importantBadges: [String]? = nil, spoonacularScore: Double? = nil, productDescription: String? = nil, imageLink: String? = nil, moreImageLinks: [String]? = nil, generatedText: String? = nil, ingredientCount: Int? = nil, credits: Credit? = nil, expirationDate: Date) {
        self.id = id
        self.barcode = barcode
        self.title = title
        self.brand = brand
        self.badges = badges
        self.importantBadges = importantBadges
        self.spoonacularScore = spoonacularScore
        self.productDescription = productDescription
        self.imageLink = imageLink
        self.moreImageLinks = moreImageLinks
        self.generatedText = generatedText
        self.ingredientCount = ingredientCount
        self.credits = credits
        self.dateAdded = .now
        self.expirationDate = expirationDate
        self.isUsed = false
        self.isLiked = false
        
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
