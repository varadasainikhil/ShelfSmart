//
//  HomeViewViewModel.swift
//  FreshAlert
//
//  Created by Sai Nikhil Varada on 9/3/25.
//

import Foundation
import SwiftData

@Observable
class CardViewViewModel{
    
    func deleteProduct(modelContext : ModelContext, product : Item){
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
                
                // Remove the matching product
                group.products?.removeAll { productInGroup in
                    productInGroup.id == product.id
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
