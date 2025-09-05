//
//  DetailProductView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/5/25.
//

import SwiftUI
import SwiftData

struct DetailProductView: View {
    @Environment(\.modelContext) private var modelContext
    var item : Item
    var body: some View {
        VStack{
            ZStack{
                if item.productImage != nil {
                    AsyncImage(url: URL(string: item.productImage ?? "")){phase in
                        
                        if let image = phase.image{
                            image
                                .resizable()
                                .scaledToFill()
                        }
                        else if phase.error != nil{
                            Text("There was an issue loading the image")
                        }
                        else {
                            ProgressView()
                        }
                    }
                }
                else{
                    Image("placeholder")
                        .resizable()
                        .scaledToFill()
                }
                VStack{
                    Spacer()
                    
                    HStack{
                        Spacer()
                        
                        Button {
                            // like the item
                            withAnimation {
                                item.LikeItem()
                                try? modelContext.save()
                            }
                        } label: {
                            Image(systemName: item.isLiked ? "heart.fill" : "heart")
                                .font(.title)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(item.name)
                .font(.title)
            
            Text(item.productDescription)
                .font(.title3)
            
            Text("Added on : \(item.dateAdded.formatted(date: .abbreviated, time: .omitted))")
        }
    }
}

#Preview {
    let item = Item(barcode: "123456789", name: "Milk", productDescription: "Organic whole milk", expirationDate: Date.now)
    item.productImage = "https://images.barcodelookup.com/15872/158728480-1.jpg"
    return DetailProductView(item: item)
}
