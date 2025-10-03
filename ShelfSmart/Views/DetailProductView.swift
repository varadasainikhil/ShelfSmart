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
    @Environment(\.dismiss) private var dismiss
    @Environment(NotificationManager.self) var notificationManager
    @State private var recipeToShow: SDRecipe?
    @State private var showDeleteConfirmation = false
    @State private var isMarkedAsUsed = false
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
                            SimpleAsyncImage(url: imageLink) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 300, height: 300)
                                    .clipped()
                            }
                        }
                        else{
                            Image("placeholder")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300)
                                .clipped()
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
                            // Sort recipes by ID to ensure stable order
                            let sortedRecipes = recipes.sorted { ($0.id ?? 0) < ($1.id ?? 0) }

                            // Recipe cards grid - 2x2 layout for recipes
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 16) {
                                ForEach(sortedRecipes, id: \.id) { sdRecipe in
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
        .toolbar {
            // Like Button (rightmost)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // Check if this will cause deletion
                    let willBeDeleted = product.isLiked && product.groupedProducts == nil && !product.isUsed

                    if willBeDeleted {
                        // Unlike will delete the product - dismiss view after deletion
                        ProductHelpers.unlikeProduct(product, modelContext: modelContext) { deleted in
                            if deleted {
                                dismiss()
                            }
                        }
                    } else {
                        // Just toggle like status - no deletion
                        ProductHelpers.unlikeProduct(product, modelContext: modelContext)
                    }
                } label: {
                    Image(systemName: product.isLiked ? "heart.fill" : "heart")
                        .foregroundStyle(product.isLiked ? .red : .primary)
                }
            }

            // Checkmark Button (middle)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    handleMarkAsUsed()
                } label: {
                    Image(systemName: (isMarkedAsUsed || product.isUsed) ? "checkmark.circle.fill" : "checkmark.circle")
                        .foregroundStyle((isMarkedAsUsed || product.isUsed) ? .green : .primary)
                }
            }

            // Trash Button (leftmost)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash.fill")
                        .foregroundStyle(.red)
                }
            }
        }
        .sheet(item: $recipeToShow) { sdRecipe in
            RecipeDetailView(sdRecipe: sdRecipe)
        }
        .confirmationDialog(
            "Delete Product",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteProduct()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if product.isLiked {
                Text("This is a liked item! Are you sure you want to delete '\(product.title)'? This action cannot be undone.")
            } else {
                Text("Are you sure you want to delete '\(product.title)'? This action cannot be undone.")
            }
        }
    }

    // MARK: - Handle Mark As Used Function
    private func handleMarkAsUsed() {
        // Immediate haptic feedback for tactile response
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Immediate visual feedback using state variable (no SwiftData access)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isMarkedAsUsed = true
        }

        // All products are now kept as standalone when marked as used
        Task { @MainActor in
            // Small delay for animation
            try? await Task.sleep(for: .milliseconds(300))
            dismiss()

            // Cleanup in detached task (no view updates)
            Task.detached {
                await MainActor.run {
                    ProductHelpers.markProductAsUsed(product: product, modelContext: modelContext, notificationManager: notificationManager)
                }
            }
        }
    }

    // MARK: - Delete Product Function
    private func deleteProduct() {
        // Haptic feedback for tactile response
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Use shared delete function with proper error handling
        do {
            try ProductHelpers.deleteProduct(product, modelContext: modelContext, notificationManager: notificationManager)
            // Dismiss after successful deletion
            dismiss()
        } catch {
            print("❌ Failed to delete product: \(error)")
            // Could show an alert to user here if needed
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
