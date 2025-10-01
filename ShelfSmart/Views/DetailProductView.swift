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
    @State private var recipeToShow: SDRecipe?
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
                            let _ = print("🖼️ DetailProductView - Attempting to load image: \(imageLink)")
                            // Convert HTTP to HTTPS if needed for App Transport Security
                            let secureImageLink = imageLink.hasPrefix("http://") ? imageLink.replacingOccurrences(of: "http://", with: "https://") : imageLink
                            AsyncImage(url: URL(string: secureImageLink)){phase in
                                
                                if let image = phase.image{
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 300, height: 300)
                                        .clipped()
                                }
                                else if phase.error != nil{
                                    let _ = print("🚨 DetailProductView - Image loading error: \(String(describing: phase.error))")
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
                                    Image(systemName: product.isLiked ? "heart.fill" : "heart")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundStyle(product.isLiked ? .red : .white)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(.black.opacity(0.3))
                                                .blur(radius: 1)
                                        )
                                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.trailing)
                                .padding(.bottom)
                            }
                            
                        }
                    }
                    .frame(width: 300, height: 300)
                    
                    VStack(spacing: 8) {
                        Text(product.title)
                            .font(.title.bold())
                        
                        // Product type tag
                        HStack {
                            Image(systemName: product.spoonacularId != nil ? "cloud.fill" : "person.fill")
                                .font(.caption)
                            Text(product.type)
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(product.spoonacularId != nil ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                        )
                        .foregroundColor(product.spoonacularId != nil ? .blue : .green)
                    }
                    
                    
                    ZStack{
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundStyle(product.borderColor.opacity(0.3))
                            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
                        
                        HStack(spacing: 20){
                            
                            // Expiration Date Section
                            VStack(alignment: .center, spacing: 4){
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("Expires on")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Text("\(product.expirationDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.subheadline.bold())
                                    .foregroundColor(product.isExpired ? .red : .primary)
                            }
                            .frame(maxWidth: .infinity)
                            
                            // Divider
                            Rectangle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 1, height: 40)
                            
                            // Ingredients Section
                            VStack(alignment: .center, spacing: 4){
                                HStack(spacing: 4) {
                                    Image(systemName: "list.bullet")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("Ingredients")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                if let ingredientCount = product.ingredientCount {
                                    Text("\(ingredientCount)")
                                        .font(.title2.bold())
                                        .foregroundColor(.primary)
                                } else {
                                    Text("N/A")
                                        .font(.title2.bold())
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
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
                    
                    // Recipes Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack{
                            Text("Recipes Using this Product")
                                .font(.title2.bold())

                            Spacer()

                            // Recipe count badge
                            if let recipes = product.recipes, !recipes.isEmpty {
                                Text("\(recipes.count)")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        // Recipe Cards Display
                        if let recipes = product.recipes, !recipes.isEmpty {
                            // Recipe cards grid - 2x2 layout for recipes
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 16) {
                                ForEach(recipes, id: \.id) { sdRecipe in
                                    RecipeCardView(sdRecipe: sdRecipe) {
                                        recipeToShow = sdRecipe
                                    }
                                    .id("recipe-\(sdRecipe.id ?? 0)") // Ensure stable identity
                                }
                            }
                        } else {
                            // No recipes found
                            VStack(spacing: 8) {
                                Image(systemName: "fork.knife")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                                
                                Text("No recipes found for this product")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Text("Try adding more specific ingredients or check back later")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
        }
        .sheet(item: $recipeToShow) { sdRecipe in
            RecipeDetailView(sdRecipe: sdRecipe)
        }
    }
}


#Preview {
    let spoonacularCredit = SpoonacularCredit(text: "openfoodfacts.org under (ODbL) v1.0", link: "https://opendatacommons.org/licenses/odbl/1-0/", image: "openfoodfacts.org under CC BY-SA 3.0 DEED", imageLink:  "https://creativecommons.org/licenses/by-sa/3.0/deed.en")
    let groceryProduct = GroceryProduct(id: 9348958, title: "LECHE SIN LACTOSA", breadcrumbs: ["Dairy", "Milk"], upc: "8410128750145", credits: spoonacularCredit)

    let newCredit = Credit(text: spoonacularCredit.text, link: spoonacularCredit.link,  image: spoonacularCredit.image, imageLink: spoonacularCredit.imageLink)

    let newProduct = Product(id: UUID().uuidString, spoonacularId: groceryProduct.id ?? 9348958, barcode: groceryProduct.upc ?? "", title: groceryProduct.title ?? "", brand: groceryProduct.brand ?? "", breadcrumbs: groceryProduct.breadcrumbs, badges: groceryProduct.badges, importantBadges: groceryProduct.importantBadges, spoonacularScore: groceryProduct.spoonacularScore, productDescription: groceryProduct.description, imageLink: groceryProduct.image, moreImageLinks: groceryProduct.images, generatedText: groceryProduct.generatedText, ingredientCount: groceryProduct.ingredientCount, recipeIds: [12345, 67890, 11111], credits: newCredit, expirationDate: Date.now.addingTimeInterval(86400*3))
    return DetailProductView(product: newProduct)
}
