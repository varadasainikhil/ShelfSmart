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
    var product : Product
    var body: some View {
        ZStack{
            // Background Color of the screen
            Rectangle()
                .fill(product.borderColor.opacity(0.4))
                .ignoresSafeArea()
            
            ScrollView {
                VStack{
                    ZStack{
                        if let imageLink = product.imageLink, !imageLink.isEmpty {
                            AsyncImage(url: URL(string: imageLink)){phase in
                                
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
                                        product.LikeProduct()
                                        try? modelContext.save()
                                    }
                                    
                                } label: {
                                    if product.isLiked{
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
                    
                    Text(product.title)
                        .font(.title.bold())
                    
                    
                    ZStack{
                        RoundedRectangle(cornerRadius: 12)
                            .foregroundStyle(product.borderColor.opacity(0.4))
                            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
                        
                        HStack{
                            
                            Spacer()
                            
                            VStack(alignment: .center){
                                Text("Expires on")
                                Text("\(product.expirationDate.formatted(date: .abbreviated, time: .omitted))")
                            }
                            Spacer()
                            
                            Spacer()
                            
                            VStack(alignment: .center){
                                if product.spoonacularScore != nil {
                                    Text(String(format: "%.2f", product.spoonacularScore!))
                                }
                            }
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .padding(.horizontal)
                    
                    VStack{
                        if product.productDescription != nil {
                            Text(product.productDescription!)
                        }
                        else if product.generatedText != nil {
                            Text(product.generatedText!)
                        }
                    }
                    .padding()
                    
                    VStack(alignment: .leading){
                        HStack{
                            Text("Recipes Using this Product")
                                .font(.title2.bold())
                            
                            Spacer()
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
        }
    }
}


#Preview {
    let spoonacularCredit = SpoonacularCredit(text: "openfoodfacts.org under (ODbL) v1.0", link: "https://opendatacommons.org/licenses/odbl/1-0/", image: "openfoodfacts.org under CC BY-SA 3.0 DEED", imageLink:  "https://creativecommons.org/licenses/by-sa/3.0/deed.en")
    let groceryProduct = GroceryProduct(id: 9348958, title: "LECHE SIN LACTOSA", upc: "8410128750145", credits: spoonacularCredit)
    
    let newCredit = Credit(text: spoonacularCredit.text, link: spoonacularCredit.link,  image: spoonacularCredit.image, imageLink: spoonacularCredit.imageLink)
    
    let newProduct = Product(id: groceryProduct.id, barcode: groceryProduct.upc, title: groceryProduct.title, brand: groceryProduct.brand ?? "", importantBadges: groceryProduct.importantBadges, spoonacularScore: groceryProduct.spoonacularScore, productDescription: groceryProduct.description, imageLink: groceryProduct.imageLink, moreImageLinks: groceryProduct.moreImageLinks, generatedText: groceryProduct.generatedText, ingredientCount: groceryProduct.ingredientCount, credits: newCredit, expirationDate: Date.now.addingTimeInterval(86400*3))
    DetailProductView(product: newProduct)
}
