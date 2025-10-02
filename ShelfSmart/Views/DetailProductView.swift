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
                    // If the product is currently liked and is standalone, disliking it will delete it.
                    let willBeDeletedOnDislike = product.isLiked && product.groupedProducts == nil

                    // Toggle the liked status
                    product.LikeProduct()

                    if willBeDeletedOnDislike {
                        // The product was just disliked, and it was a standalone product.
                        // So, delete it - use Task to allow current render to complete
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(100))
                            modelContext.delete(product)
                            try? modelContext.save()
                            dismiss() // Dismiss the view since the item is gone.
                        }
                    } else {
                        // For all other cases (liking a product, or disliking a grouped product),
                        // just save the change in 'isLiked' status.
                        try? modelContext.save()
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
            Text("Are you sure you want to delete '\(product.title)'? This action cannot be undone.")
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

        // Check if product will be deleted (not liked)
        let willBeDeleted = !product.isLiked

        if willBeDeleted {
            // For products that will be deleted, dismiss immediately after animation
            // and perform cleanup in detached background task
            Task { @MainActor in
                // Small delay for animation
                try? await Task.sleep(for: .milliseconds(300))
                dismiss()

                // Cleanup in detached task (no view updates)
                Task.detached {
                    await MainActor.run {
                        // Mark as used
                        product.isUsed = true

                        // Cancel notifications
                        notificationManager.deleteScheduledNotifications(for: product)

                        // Handle recipes: delete non-liked recipes
                        if let recipes = product.recipes {
                            for recipe in recipes {
                                if !recipe.isLiked {
                                    modelContext.delete(recipe)
                                }
                            }
                        }

                        // Remove from GroupedProducts
                        if let group = product.groupedProducts {
                            if let products = group.products,
                               let index = products.firstIndex(where: { $0.id == product.id }) {
                                group.products?.remove(at: index)
                            }

                            if let products = group.products, products.isEmpty {
                                modelContext.delete(group)
                            }
                        }

                        // Delete the product
                        modelContext.delete(product)
                        try? modelContext.save()
                    }
                }
            }
        } else {
            // For liked products that will be kept, dismiss first then cleanup
            Task { @MainActor in
                // Small delay for animation
                try? await Task.sleep(for: .milliseconds(300))
                dismiss()

                // Cleanup in detached task (no view updates)
                Task.detached {
                    await MainActor.run {
                        // Mark as used
                        product.isUsed = true

                        // Cancel notifications
                        notificationManager.deleteScheduledNotifications(for: product)

                        // Handle recipes: delete non-liked recipes, keep liked ones as standalone
                        if let recipes = product.recipes {
                            for recipe in recipes {
                                if !recipe.isLiked {
                                    // Delete non-liked recipes
                                    modelContext.delete(recipe)
                                }
                                // Liked recipes will automatically become standalone (product = nil) due to .nullify delete rule
                            }
                        }

                        // Remove from GroupedProducts
                        if let group = product.groupedProducts {
                            // Remove product from group's array
                            if let products = group.products,
                               let index = products.firstIndex(where: { $0.id == product.id }) {
                                group.products?.remove(at: index)
                            }

                            // Check if group is now empty
                            if let products = group.products, products.isEmpty {
                                modelContext.delete(group)
                            }
                        }

                        // Keep as standalone - null out the group relationship
                        product.groupedProducts = nil
                        try? modelContext.save()
                    }
                }
            }
        }
    }

    // MARK: - Delete Product Function
    private func deleteProduct() {
        // 1. Cancel scheduled notifications for this product
        notificationManager.deleteScheduledNotifications(for: product)

        // 2. If the product is part of a group, handle group logic first
        if let groupedProduct = product.groupedProducts {
            // Remove product from the group's list of products
            if let index = groupedProduct.products?.firstIndex(where: { $0.id == product.id }) {
                groupedProduct.products?.remove(at: index)
            }

            // If the group is now empty, delete the group
            if groupedProduct.products?.isEmpty ?? true {
                modelContext.delete(groupedProduct)
            }
        }

        // 3. Handle recipes: delete non-liked recipes, keep liked ones as standalone
        if let recipes = product.recipes {
            for recipe in recipes {
                if !recipe.isLiked {
                    // Delete non-liked recipes
                    modelContext.delete(recipe)
                }
                // Liked recipes will automatically become standalone (product = nil) due to .nullify delete rule
            }
        }

        // 4. Handle the product itself based on its 'isLiked' status
        if product.isLiked {
            // If liked, make it a standalone product by ensuring its group relationship is nil
            product.groupedProducts = nil
        } else {
            // If not liked, delete the product from the model context
            modelContext.delete(product)
        }

        // 5. Save changes and dismiss the view
        do {
            try modelContext.save()
            dismiss()
        } catch {
            // Handle or log the error appropriately
            print("Failed to save model context after deletion: \(error)")
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
