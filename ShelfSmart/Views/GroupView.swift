//
//  GroupView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/11/25.
//

import SwiftUI

struct GroupView: View {
    var group : GroupedProducts
    
    var body: some View {
        VStack{
            HStack{
                Text(group.daysTillExpiry().message)
                    .padding(.horizontal, 8)
                Spacer()
            }
            
            ForEach(group.products ?? [], id: \.id){ product in
                NavigationLink(destination: DetailProductView(product: product)) {
                    if group.products?.last == product {
                        CardView(product: product)
                            .padding(.bottom)
                        
                    }
                    else {
                        CardView(product: product)
                    }
                }
            }
        }
    }
}

#Preview {
    let threeDaysFromNow = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? Date.now)
    
    // Use empty string to match what HomeView uses when no user is authenticated
    let sampleUserId = ""
    let sampleGroup = GroupedProducts(expirationDate: threeDaysFromNow, products: [
        Product(spoonacularId: 123456789, barcode: "123456789", title: "Milk", brand: "Organic Milk", breadcrumbs: ["Dairy", "Milk"], recipeIds: [111, 222, 333], expirationDate: threeDaysFromNow),
        Product(spoonacularId: 12345679, barcode: "12345679", title: "Bread", brand: "Whole Wheat Bread", breadcrumbs: ["Bakery", "Bread"], recipeIds: [444, 555, 666], expirationDate: threeDaysFromNow)
    ], userId: sampleUserId)
    
    return GroupView(group: sampleGroup)
}
