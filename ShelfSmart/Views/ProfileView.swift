//
//  ProfileView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/25/25.
//

import FirebaseAuth
import SwiftData
import SwiftUI
  
struct ProfileView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(NotificationManager.self) var notificationManager
    @State var viewModel = ProfileViewViewModel()
    @State private var currentUserId: String = Auth.auth().currentUser?.uid ?? ""
    @State private var showDeleteConfirmation = false
    
    
    // Get all groups and filter in the view - this will be reactive to changes
    @Query(sort: \GroupedProducts.expirationDate) private var allGroups: [GroupedProducts]
    
    // Get all products for liked products section
    @Query private var allProducts: [Product]

    // Get all recipes for liked recipes section
    @Query private var allRecipes: [SDRecipe]
    
    // Computed property that filters groups by current user
    var groups: [GroupedProducts] {
        return allGroups.filter { group in
            group.userId == currentUserId
        }
    }
    
    // Computed property for liked products by current user
    var likedProducts: [Product] {
        return allProducts.filter { product in
            product.isLiked && product.userId == currentUserId
        }
    }

    // Computed property for liked recipes by current user
    var likedRecipes: [SDRecipe] {
        return allRecipes.filter { recipe in
            recipe.isLiked && recipe.userId == currentUserId
        }
    }

    // Computed property for used products by current user
    var usedProducts: [Product] {
        return allProducts.filter { product in
            product.isUsed && product.userId == currentUserId
        }
    }
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome back,")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text(viewModel.userName.isEmpty ? "User" : viewModel.userName)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        
                        // Profile Icon
                        Circle()
                            .fill(.green.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.green)
                            }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Subtitle
                    Text("Manage your ShelfSmart account and preferences")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
                
                // Content Sections
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Liked Products Section
                        VStack(alignment: .leading, spacing: 12) {
                            // Section Header
                            NavigationLink(destination: AllLikedProductsView()) {
                                HStack {
                                    Text("Liked Products")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 20)
                        
                            // Recent 5 Liked Items - Horizontal Scroll
                            if !likedProducts.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(Array(likedProducts.prefix(5)), id: \.self) { product in
                                            NavigationLink(destination: DetailProductView(product: product)) {
                                                LikedProductCard(product: product)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                .padding(.bottom, 16)
                            }
                        
                            if likedProducts.isEmpty {
                                // Empty State for Liked Products
                                VStack(spacing: 16) {
                                    Circle()
                                        .fill(.red.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                        .overlay {
                                            Image(systemName: "heart.slash")
                                                .font(.system(size: 24))
                                                .foregroundStyle(.red.opacity(0.7))
                                        }
                                    
                                    VStack(spacing: 6) {
                                        Text("No liked products yet")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)
                                        
                                        Text("Start liking products to see them here")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 140)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Liked Recipes Section
                        VStack(alignment: .leading, spacing: 12) {
                            // Section Header
                            NavigationLink(destination: AllLikedRecipesView()) {
                                HStack {
                                    Text("Liked Recipes")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 20)

                            // Recent 5 Liked Recipes - Horizontal Scroll
                            if !likedRecipes.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(Array(likedRecipes.prefix(5)), id: \.self) { recipe in
                                            NavigationLink(destination: RecipeDetailView(sdRecipe: recipe)) {
                                                LikedRecipeCard(recipe: recipe)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                .padding(.bottom, 16)
                            }

                            if likedRecipes.isEmpty {
                                // Empty State for Liked Recipes
                                VStack(spacing: 16) {
                                    Circle()
                                        .fill(.orange.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                        .overlay {
                                            Image(systemName: "heart.slash")
                                                .font(.system(size: 24))
                                                .foregroundStyle(.orange.opacity(0.7))
                                        }

                                    VStack(spacing: 6) {
                                        Text("No liked recipes yet")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)

                                        Text("Start liking recipes to see them here")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 140)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                                .padding(.horizontal, 20)
                            }
                        }

                        // Used Products Section
                        VStack(alignment: .leading, spacing: 12) {
                            // Section Header
                            NavigationLink(destination: AllUsedProductsView()) {
                                HStack {
                                    Text("Used Products")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 20)

                            // Recent 5 Used Products - Horizontal Scroll
                            if !usedProducts.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(Array(usedProducts.prefix(5)), id: \.self) { product in
                                            NavigationLink(destination: DetailProductView(product: product)) {
                                                UsedProductCard(product: product)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                .padding(.bottom, 16)
                            }

                            if usedProducts.isEmpty {
                                // Empty State for Used Products
                                VStack(spacing: 16) {
                                    Circle()
                                        .fill(.blue.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                        .overlay {
                                            Image(systemName: "tray")
                                                .font(.system(size: 24))
                                                .foregroundStyle(.blue.opacity(0.7))
                                        }

                                    VStack(spacing: 6) {
                                        Text("No used products yet")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)

                                        Text("Products you mark as used will appear here")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 140)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.bottom, 120) // Extra space for bottom buttons
                }
            }
            .overlay(alignment: .bottom) {
                // Bottom Action Buttons
                VStack(spacing: 16) {
                    // Delete All Items Button
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        showDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Clear All Items")
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.red)
                        )
                        .shadow(color: .red.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .disabled(groups.isEmpty)
                    .opacity(groups.isEmpty ? 0.6 : 1.0)
                    
                    // Sign Out Button
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        Task {
                            viewModel.signOut()
                        }
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Sign Out")
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.green, lineWidth: 2)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 34)
                .background(
                    ZStack {
                        // Gradient background for overlay
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, Color(.systemBackground)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .ignoresSafeArea(.container, edges: .bottom)
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                currentUserId = Auth.auth().currentUser?.uid ?? ""
                Task {
                    await viewModel.getUserName()
                }
            }
            .confirmationDialog(
                "Clear All Items",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear All Items", role: .destructive) {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                    impactFeedback.impactOccurred()
                    viewModel.deleteGroups(groups: groups, modelContext: modelContext, notificationManager: notificationManager)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all \(groups.count) items from your shelf. This action cannot be undone.")
            }
        }
    }
}

// MARK: - Liked Product Card Component
struct LikedProductCard: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Product Image
            ZStack {
                if let imageLink = product.imageLink, !imageLink.isEmpty {
                    let secureImageLink = imageLink.hasPrefix("http://") ? imageLink.replacingOccurrences(of: "http://", with: "https://") : imageLink
                    AsyncImage(url: URL(string: secureImageLink)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else if phase.error != nil {
                            Image("placeholder")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            ProgressView()
                                .frame(width: 80, height: 80)
                        }
                    }
                } else {
                    Image("placeholder")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Heart indicator overlay
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .background(
                                Circle()
                                    .fill(.red)
                                    .frame(width: 22, height: 22)
                            )
                            .offset(x: -6, y: 6)
                    }
                    Spacer()
                }
            }
            .frame(width: 80, height: 80)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Product Info
            VStack(alignment: .center, spacing: 2) {
                Text(product.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 28) // Reduced height for text area
            .padding(.horizontal, 4)
        }
        .frame(width: 100, height: 120)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(product.borderColor.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Liked Recipe Card Component
struct LikedRecipeCard: View {
    let recipe: SDRecipe

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Recipe Image
            ZStack {
                if let imageLink = recipe.image, !imageLink.isEmpty {
                    let secureImageLink = imageLink.hasPrefix("http://") ? imageLink.replacingOccurrences(of: "http://", with: "https://") : imageLink
                    AsyncImage(url: URL(string: secureImageLink)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else if phase.error != nil {
                            Image("placeholder")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            ProgressView()
                                .frame(width: 80, height: 80)
                        }
                    }
                } else {
                    Image("placeholder")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Heart indicator overlay
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .background(
                                Circle()
                                    .fill(.red)
                                    .frame(width: 22, height: 22)
                            )
                            .offset(x: -6, y: 6)
                    }
                    Spacer()
                }
            }
            .frame(width: 80, height: 80)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Recipe Info
            VStack(alignment: .center, spacing: 2) {
                Text(recipe.title ?? "Unknown Recipe")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                if let readyInMinutes = recipe.readyInMinutes {
                    Text("\(readyInMinutes) mins")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 28)
            .padding(.horizontal, 4)
        }
        .frame(width: 100, height: 120)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.orange.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Used Product Card Component
struct UsedProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Product Image
            ZStack {
                if let imageLink = product.imageLink, !imageLink.isEmpty {
                    let secureImageLink = imageLink.hasPrefix("http://") ? imageLink.replacingOccurrences(of: "http://", with: "https://") : imageLink
                    AsyncImage(url: URL(string: secureImageLink)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else if phase.error != nil {
                            Image("placeholder")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            ProgressView()
                                .frame(width: 80, height: 80)
                        }
                    }
                } else {
                    Image("placeholder")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Checkmark indicator overlay
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .background(
                                Circle()
                                    .fill(.green)
                                    .frame(width: 22, height: 22)
                            )
                            .offset(x: -6, y: 6)
                    }
                    Spacer()
                }
            }
            .frame(width: 80, height: 80)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .grayscale(0.5)
            .opacity(0.8)

            // Product Info
            VStack(alignment: .center, spacing: 2) {
                Text(product.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .strikethrough(true, color: .primary)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 28) // Reduced height for text area
            .padding(.horizontal, 4)
        }
        .frame(width: 100, height: 120)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.blue.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
    }
}

#Preview {
    ProfileView(viewModel: ProfileViewViewModel())
}

