//
//  HomeViewViewModel.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/3/25.
//

import Foundation
import SwiftData

@Observable
class CardViewViewModel{
    
    func deleteProduct(modelContext : ModelContext, product : Product){
        // Use normalized date for consistent comparison with GroupedProducts
        let targetDate = Calendar.current.startOfDay(for: product.expirationDate)
        let fetchDescriptor = FetchDescriptor<GroupedProducts>(predicate: #Predicate<GroupedProducts> { group in
            group.expirationDate == targetDate
        })
        
        do{
            let matchingGroups = try modelContext.fetch(fetchDescriptor)
            
            if matchingGroups.isEmpty{
                print("Could not find the group of the product")
            }
            else {
                guard let group = matchingGroups.first else {
                    print("No group found despite non-empty results")
                    return
                }
                
                // Remove the matching product - handle both API and manual products safely
                group.products?.removeAll { productInGroup in
                    // Match API products by their Spoonacular ID
                    if let productId = product.id, let groupProductId = productInGroup.id {
                        return productId == groupProductId
                    }
                    // Match manual products by their UUID
                    if let productManualId = product.manualId, let groupProductManualId = productInGroup.manualId {
                        return productManualId == groupProductManualId
                    }
                    // No match if we can't compare properly
                    return false
                }
                
                // Clean up empty group
                if group.products != nil{
                    if group.products!.isEmpty  {
                        modelContext.delete(group)
                    }
                }
                
                // Save changes
                try modelContext.save()
                print("Successfully removed product from group")
            }
        }
        catch{
            print(error.localizedDescription)
        }
    }
}
