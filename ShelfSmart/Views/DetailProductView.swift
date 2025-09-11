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
        ZStack{
            // Background Color of the screen
            Rectangle()
                .fill(item.borderColor.opacity(0.4))
                .ignoresSafeArea()
            
            VStack{
                ZStack{
                    if item.productImage != nil || ((item.productImage?.isEmpty) != nil){
                        AsyncImage(url: URL(string: item.productImage ?? "")){phase in
                            
                            if let image = phase.image{
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 300, height: 300)
                                    .clipped()
                            }
                            else if phase.error != nil{
                                Text("There was an issue loading the image")
                            }
                            else {
                                ProgressView()
                                    .frame(width: 300, height: 300)
                                    .clipped()
                            }
                        }
                    }
                    else{
                        Image("placeholder")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300)
                            .clipped()
                    }
                    
                    VStack{
                        
                        Spacer()
                        
                        HStack{
                            
                            Spacer()
                            
                            Button {
                                // Like the item and store it
                                withAnimation {
                                    item.LikeItem()
                                    try? modelContext.save()
                                }
                                
                            } label: {
                                if item.isLiked{
                                    Image(systemName: "heart.circle.fill")
                                        .symbolRenderingMode(.palette) // Enable the palette mode
                                        .foregroundStyle(.white, .red) // Assign colors to the layers
                                        .font(.system(size: 50))
                                }
                                else {
                                    ZStack{
                                        Image(systemName: "circle.fill")
                                            .foregroundStyle(.white)
                                            .font(.system(size: 50, weight: .light))
                                        
                                        Image(systemName: "circle")
                                            .foregroundStyle(.red)
                                            .font(.system(size: 50, weight: .light))
                                        
                                        Image(systemName: "heart")
                                            .foregroundStyle(.red)
                                            .font(.system(size: 25))
                                    }
                                }
                                
                            }
                            .padding(.trailing)
                            .padding(.bottom)
                        }
                        
                    }
                    

                    
                }
                .frame(width: 300, height: 300)
                
                Text(item.name)
                    .font(.title.bold())
                
                Text(item.productDescription)
                
                ZStack{
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundStyle(item.borderColor.opacity(0.4))
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
                    
                    HStack{
                        
                        Spacer()
                        
                        VStack(alignment: .center){
                            Text("Expires on")
                            Text("\(item.expirationDate.formatted(date: .abbreviated, time: .omitted))")
                        }
                        Spacer()
                        
                        Spacer()
                        
                        VStack(alignment: .center){
                            if item.nutritionScore != nil && item.nutritionGrade != nil{
                                Text(item.nutritionGrade!.capitalized)
                                Text("\(item.nutritionScore!)")
                            }
                        }
                        
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .padding(.horizontal)
                
                if !item.productDescription.isEmpty {
                    Text(item.productDescription)
                        .padding()
                }
                VStack(alignment: .leading){
                    Text("Recipes Using this Product")
                        .font(.title2.bold())
                    
                    
                }
                
                
                Spacer()
            }
            
            
            
            
        }
    }
}

#Preview {
    let item = Item(barcode: "123456789", name: "Milk", productDescription: "Organic whole milk", expirationDate: Date.now)
    item.productImage = "https://images.barcodelookup.com/15872/158728480-1.jpg"
    item.nutritionGrade = "a"
    item.nutritionScore = 93
    return DetailProductView(item: item)
}
