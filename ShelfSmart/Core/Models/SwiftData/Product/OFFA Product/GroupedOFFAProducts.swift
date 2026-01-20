//
//  GroupedOFFAProducts.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 11/7/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class GroupedOFFAProducts {
    var userId: String = ""
    var id: String = UUID().uuidString
    var expirationDate: Date = Date.now

    // Relationship: One GroupedOFFAProducts has many LSProducts
    @Relationship(deleteRule: .cascade)
    var offaProducts: [LSProduct]? = [LSProduct]()

    init(expirationDate: Date, offaProducts: [LSProduct], userId: String) {
        // Normalize the expiration date to start of day for consistent comparison
        self.userId = userId
        self.expirationDate = Calendar.current.startOfDay(for: expirationDate)
        self.offaProducts = offaProducts
    }

    var isExpired: Bool {
        let daysTillExpiry = daysTillExpiry().count
        if daysTillExpiry >= 0 {
            return false
        }
        return true
    }

    var borderColor: Color {
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
    func daysTillExpiry() -> (message: String, count: Int) {
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

