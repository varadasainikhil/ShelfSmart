//
//  SwiftUIView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/29/25.
//

import SwiftData
import SwiftUI

struct CardView: View {
    @Environment(\.modelContext) var modelContext
    @State private var viewModel = CardViewViewModel()
    var product : Product
    var body: some View {
        
        ZStack{
            RoundedRectangle(cornerRadius: 12)
                .fill(product.borderColor.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(product.borderColor, lineWidth: 2)
                )
            
            VStack{
                HStack{
                    VStack{
                        if let imageLink = product.imageLink, !imageLink.isEmpty{
                            let _ = print("🖼️ CardView - Attempting to load image: \(imageLink)")
                            AsyncImage(url: URL(string: imageLink)){phase in
                                if let image = phase.image{
                                    image
                                        .resizable()
                                        .scaledToFill()
                                }
                                else  if phase.error != nil {
                                    let _ = print("🚨 CardView - Image loading error: \(String(describing: phase.error))")
                                    Text("There was an error loading the image")
                                }
                                else {
                                    ProgressView()
                                }
                            }
                        }
                        else {
                            let _ = print("🖼️ CardView - No image URL, showing placeholder. ImageLink: \(String(describing: product.imageLink))")
                            Image("placeholder")
                                .resizable()
                                .scaledToFill()
                        }
                    }
                    .frame(width: 75, height: 75)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    
                    Spacer()
                    
                    VStack(alignment: .leading){
                        Spacer()
                        Text(product.title)
                            .foregroundStyle(.black)
                            .font(.title3.bold())
                            .lineLimit(2)
                        
                        
                        if product.productDescription != nil{
                            Text(product.productDescription!)
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                        else if product.generatedText != nil{
                            Text(product.generatedText!)
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        if product.productDescription == nil && ((product.productDescription?.isEmpty) != nil) && product.generatedText == nil && ((product.generatedText?.isEmpty) != nil) {
                            Spacer()
                        }
                        
                        
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    if product.isExpired{
                        Button {
                            // delete the product
                            withAnimation {
                                viewModel.deleteProduct(modelContext: modelContext, product: product)
                            }
                        } label: {
                            Image(systemName: "trash.circle")
                                .font(.title)
                                .foregroundStyle(product.isUsed ? .green : .black)
                        }
                    }
                    else {
                        Button {
                            // mark the product as used and completed
                            product.markUsed()
                        } label: {
                            Image(systemName: product.isUsed ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.title)
                                .foregroundStyle(product.isUsed ? .green : .black)
                        }
                    }
                    
                    Spacer()
                }
            }
            .frame(height: 100)
            .padding(.horizontal, 8)
        }
        .frame(height: 100)
        .padding(.horizontal, 8)
    }
}
#Preview {
    let spoonacularCredit = SpoonacularCredit(text: "openfoodfacts.org under (ODbL) v1.0", link: "https://opendatacommons.org/licenses/odbl/1-0/", image: "openfoodfacts.org under CC BY-SA 3.0 DEED", imageLink:  "https://creativecommons.org/licenses/by-sa/3.0/deed.en")
    let groceryProduct = GroceryProduct(id: 9348958, title: "LECHE SIN LACTOSA", badges: [
        "egg_free",
        "peanut_free",
        "primal",
        "sulfite_free",
        "nut_free",
        "vegan",
        "no_preservatives",
        "soy_free",
        "msg_free",
        "no_artificial_colors",
        "sugar_free",
        "no_artificial_flavors",
        "vegetarian",
        "no_artificial_ingredients",
        "no_additives",
        "corn_free",
        "dairy_free",
        "paleo",
        "gluten_free"
    ], importantBadges:  [
        "gluten_free"
    ], spoonacularScore: 100.0, image: "https://img.spoonacular.com/products/9348958-312x231.jpg", images: [
        "https://img.spoonacular.com/products/9348958-90x90.jpg",
        "https://img.spoonacular.com/products/9348958-312x231.jpg",
        "https://img.spoonacular.com/products/9348958-636x393.jpg"
    ], generatedText:  "LECHE SIN LACTOSA: This product is a tremendous fit if you like to buy products that are free of preservatives, vegetarian, vegan, and gluten-free. According to our research, this product contains no ingredients that you should avoid. This product has 2 ingredients (in our experience: the fewer ingredients, the better!)", description: nil, upc: "8410128750145", brand: nil, ingredientCount: 2, credits: spoonacularCredit)
    
    let newCredit = Credit(text: spoonacularCredit.text, link: spoonacularCredit.link,  image: spoonacularCredit.image, imageLink: spoonacularCredit.imageLink)
    
    let newItem = Product(id: groceryProduct.id, barcode: groceryProduct.upc, title: groceryProduct.title, brand: groceryProduct.brand ?? "", importantBadges: groceryProduct.importantBadges, spoonacularScore: groceryProduct.spoonacularScore, productDescription: groceryProduct.description, imageLink: groceryProduct.imageLink, moreImageLinks: groceryProduct.moreImageLinks, generatedText: groceryProduct.generatedText, ingredientCount: groceryProduct.ingredientCount, credits: newCredit, expirationDate: Date.now.addingTimeInterval(86400*3))
    CardView(product: newItem)
}
