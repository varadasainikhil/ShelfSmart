//
//  GroupedProducts.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/2/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class GroupedProducts{
    var userId : String = ""
    var id : String = UUID().uuidString
    var expirationDate : Date = Date.now

    // Relationship: One GroupedProducts has many Products
    @Relationship(deleteRule: .cascade)
    var products : [Product]? = [Product]()
    
    init(expirationDate: Date, products: [Product], userId : String) {
        // Normalize the expiration date to start of day for consistent comparison
        self.userId = userId
        self.expirationDate = Calendar.current.startOfDay(for: expirationDate)
        self.products = products
    }
    
    var isExpired : Bool{
        let daysTillExpiry = daysTillExpiry().count
        if daysTillExpiry >= 0 {
            return false
        }
        return true
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
