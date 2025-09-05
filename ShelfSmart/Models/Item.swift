//
//  product.swift
//  FreshAlert
//
//  Created by Sai Nikhil Varada on 8/25/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class Item{
    var id : String = UUID().uuidString
    var barcode : String = ""
    var name : String = ""
    var productDescription : String = ""
    var dateAdded : Date = Date.now
    var expirationDate : Date = Date.now
    var productImage : String?
    var isUsed : Bool = false
    
    @Relationship(inverse: \GroupedProducts.products) 
    var groupedProduct: GroupedProducts?
    
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
    
    init(barcode: String , name: String, productDescription: String, expirationDate: Date, productImage: String? = nil) {
        self.barcode = barcode
        self.name = name
        self.productDescription = productDescription
        self.dateAdded = .now
        self.expirationDate = Calendar.current.startOfDay(for: expirationDate)
        self.productImage = productImage
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
