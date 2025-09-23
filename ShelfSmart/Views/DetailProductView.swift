//
//  DetailProductView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/5/25.
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct DetailProductView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var recipeCardViewModel = RecipeCardViewModel()
    @State private var recipeToShow: Recipe?
    var product : Product

    // Query to check liked recipes
    @Query private var allRecipes: [SDRecipe]

    // Helper function to check if recipe is liked
    private func isRecipeLiked(_ recipeId: Int) -> Bool {
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        return allRecipes.contains { recipe in
            recipe.id == recipeId && recipe.isLiked && recipe.userId == currentUserId
        }
    }
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
                            Image(systemName: product.id != nil ? "cloud.fill" : "person.fill")
                                .font(.caption)
                            Text(product.type)
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(product.id != nil ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                        )
                        .foregroundColor(product.id != nil ? .blue : .green)
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
                            if let recipeIds = product.recipeIds, !recipeIds.isEmpty {
                                Text("\(recipeIds.count)")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        // Recipe Cards Display
                        if let recipeIds = product.recipeIds, !recipeIds.isEmpty {
                            if recipeCardViewModel.isLoading && recipeCardViewModel.recipes.isEmpty {
                                // Loading state
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                    Text("Loading recipes...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else if recipeCardViewModel.hasRecipes {
                                // Recipe cards grid - 2x2 layout for 4 recipes
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ], spacing: 16) {
                                    ForEach(recipeCardViewModel.recipes, id: \.id) { recipe in
                                        RecipeCard(recipe: recipe, isLiked: isRecipeLiked(recipe.id)) {
                                            recipeToShow = recipe
                                        }
                                        .id("recipe-\(recipe.id)") // Ensure stable identity
                                    }
                                }
                            } else if let errorMessage = recipeCardViewModel.errorMessage {
                                // Error state
                                VStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.title2)
                                        .foregroundColor(.orange)
                                    
                                    Text("Failed to load recipes")
                                        .font(.headline)
                                    
                                    Text(errorMessage)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                    
                                    Button("Try Again") {
                                        Task {
                                            await recipeCardViewModel.fetchMultipleRecipeDetails(recipeIds: recipeIds)
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                // No recipes loaded yet - trigger loading
                                VStack(spacing: 12) {
                                    Image(systemName: "fork.knife")
                                        .font(.title2)
                                        .foregroundColor(.gray)
                                    
                                    Text("Loading recipes...")
                                        .font(.headline)
                                    
                                    Text("Fetching recipe details for this product")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .onAppear {
                                    Task {
                                        await recipeCardViewModel.fetchMultipleRecipeDetails(recipeIds: recipeIds)
                                    }
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
        .sheet(item: $recipeToShow) { recipe in
            RecipeDetailView(recipe: recipe)
        }
    }
}


#Preview {
    let spoonacularCredit = SpoonacularCredit(text: "openfoodfacts.org under (ODbL) v1.0", link: "https://opendatacommons.org/licenses/odbl/1-0/", image: "openfoodfacts.org under CC BY-SA 3.0 DEED", imageLink:  "https://creativecommons.org/licenses/by-sa/3.0/deed.en")
    let groceryProduct = GroceryProduct(id: 9348958, title: "LECHE SIN LACTOSA", breadcrumbs: ["Dairy", "Milk"], upc: "8410128750145", credits: spoonacularCredit)
    
    let newCredit = Credit(text: spoonacularCredit.text, link: spoonacularCredit.link,  image: spoonacularCredit.image, imageLink: spoonacularCredit.imageLink)
    
    let newProduct = Product(id: groceryProduct.id ?? 9348958, barcode: groceryProduct.upc ?? "", title: groceryProduct.title ?? "", brand: groceryProduct.brand ?? "", breadcrumbs: groceryProduct.breadcrumbs, badges: groceryProduct.badges, importantBadges: groceryProduct.importantBadges, spoonacularScore: groceryProduct.spoonacularScore, productDescription: groceryProduct.description, imageLink: groceryProduct.image, moreImageLinks: groceryProduct.images, generatedText: groceryProduct.generatedText, ingredientCount: groceryProduct.ingredientCount, recipeIds: [12345, 67890, 11111], credits: newCredit, expirationDate: Date.now.addingTimeInterval(86400*3))
    DetailProductView(product: newProduct)
}
