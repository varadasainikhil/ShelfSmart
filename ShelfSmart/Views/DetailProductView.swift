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
        VStack{
            ZStack{
                if let imageLink = product.imageLink, !imageLink.isEmpty, let url = URL(string: imageLink) {
                    AsyncImage(url: url){phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure(let error):
                            Text("There was an issue loading the image")
                        case .empty:
                            ProgressView()
                        @unknown default:
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
                                product.LikeProduct()
                                try? modelContext.save()
                            }
                        } label: {
                            Image(systemName: product.isLiked ? "heart.fill" : "heart")
                                .font(.title)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(product.title)
            
            if product.productDescription != nil {
                Text(product.productDescription!)
                    .font(.title3)
            }
            else if product.generatedText != nil {
                Text(product.generatedText!)
                    .font(.title3)
            }
            
            Text("Added on : \(product.dateAdded.formatted(date: .abbreviated, time: .omitted))")
        }
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
    ], spoonacularScore: 100.0, imageLink: "https://img.spoonacular.com/products/9348958-312x231.jpg", moreImageLinks: [
        "https://img.spoonacular.com/products/9348958-90x90.jpg",
        "https://img.spoonacular.com/products/9348958-312x231.jpg",
        "https://img.spoonacular.com/products/9348958-636x393.jpg"
    ], generatedText:  "LECHE SIN LACTOSA: This product is a tremendous fit if you like to buy products that are free of preservatives, vegetarian, vegan, and gluten-free. According to our research, this product contains no ingredients that you should avoid. This product has 2 ingredients (in our experience: the fewer ingredients, the better!)", description: nil, upc: "8410128750145", brand: nil, ingredientCount: 2, credits: spoonacularCredit)
    
    let newCredit = Credit(text: spoonacularCredit.text, link: spoonacularCredit.link,  image: spoonacularCredit.image, imageLink: spoonacularCredit.imageLink,)
    
    let newProduct = Product(id: groceryProduct.id, barcode: groceryProduct.upc, title: groceryProduct.title, brand: groceryProduct.brand ?? "", importantBadges: groceryProduct.importantBadges, spoonacularScore: groceryProduct.spoonacularScore, productDescription: groceryProduct.description, imageLink: groceryProduct.imageLink, moreImageLinks: groceryProduct.moreImageLinks, generatedText: groceryProduct.generatedText, ingredientCount: groceryProduct.ingredientCount, credits: newCredit, expirationDate: Date.now.addingTimeInterval(86400*3))
    DetailProductView(product: newProduct)
}
