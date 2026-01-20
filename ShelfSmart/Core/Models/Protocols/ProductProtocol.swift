//
//  ProductProtocol.swift
//  ShelfSmart
//
//  Created by Architecture Refactoring on 1/19/26.
//

import Foundation
import SwiftUI

/// Shared protocol for Product and LSProduct to eliminate code duplication
/// Both Spoonacular (Product) and OFFA (LSProduct) types conform to this protocol
protocol ProductProtocol: AnyObject {
    // MARK: - Required Properties
    var id: String { get }
    var barcode: String { get set }
    var title: String { get set }
    var brand: String? { get set }
    var expirationDate: Date { get set }
    var dateAdded: Date { get }
    var isUsed: Bool { get set }
    var isLiked: Bool { get set }
    var userId: String { get set }
    var imageLink: String? { get set }
    var productDescription: String? { get set }
    
    // MARK: - Notification IDs
    var warningNotificationId: String { get }
    var expirationNotificationId: String { get }
}

// MARK: - Default Implementations
extension ProductProtocol {
    
    /// Calculate days until expiration
    /// - Returns: Tuple containing a human-readable message and the count of days
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
    
    /// Whether the product is expired
    var isExpired: Bool {
        let daysTillExpiry = daysTillExpiry().count
        return daysTillExpiry < 0
    }
    
    /// Status of product expiration
    var expiryStatus: ExpiryStatus {
        if isExpired {
            return .expired
        } else {
            let daysTillExpiryCount = daysTillExpiry().count
            if daysTillExpiryCount >= 7 {
                return .fresh
            }
            return .expiringSoon
        }
    }
    
    /// Border color based on expiry status
    var borderColor: Color {
        if isExpired {
            return .red
        } else {
            let daysTillExpiryCount = daysTillExpiry().count
            if daysTillExpiryCount >= 7 {
                return .green
            }
            return .yellow
        }
    }
    
    /// Warning date (7 days before expiration)
    var warningDate: Date? {
        Calendar.current.date(byAdding: .day, value: -7, to: expirationDate)
    }
    
    /// Toggle the liked status of the product
    func likeProduct() {
        isLiked.toggle()
    }
    
    /// Mark the product as used with animation
    func markUsed() {
        withAnimation {
            isUsed = true
        }
    }
}
