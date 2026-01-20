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
    let userId: String  // Passed from AuthenticatedView

    @Environment(\.modelContext) var modelContext
    @Environment(NotificationManager.self) var notificationManager
    @State var viewModel: ProfileViewViewModel
    @State private var showDeleteConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showReauthAlert = false
    @State private var showReauthSheet = false
    @State private var isReauthenticated = false
    @State private var deletionInProgress = false
    @State private var deletionError: String?
    @State private var showDeletionError = false
    @State private var showProfileInfo = false

    // Database-level filtering with predicates (much better performance)
    @Query private var groups: [GroupedProducts]
    @Query private var allProducts: [Product]
    @Query private var allRecipes: [SDRecipe]
    @Query private var likedProducts: [Product]
    @Query private var likedLSProducts: [LSProduct]
    @Query private var likedRecipes: [SDRecipe]
    @Query private var usedProducts: [Product]
    @Query private var usedLSProducts: [LSProduct]

    init(userId: String) {
        self.userId = userId
        _viewModel = State(initialValue: ProfileViewViewModel(userId: userId))

        // All queries filter at database level for optimal performance
        self._groups = Query(filter: #Predicate { $0.userId == userId })
        self._allProducts = Query(filter: #Predicate { $0.userId == userId })
        self._allRecipes = Query(filter: #Predicate { $0.userId == userId })
        self._likedProducts = Query(filter: #Predicate { $0.isLiked && $0.userId == userId })
        self._likedLSProducts = Query(filter: #Predicate<LSProduct> { $0.isLiked && $0.userId == userId })
        self._likedRecipes = Query(filter: #Predicate { $0.isLiked && $0.userId == userId })
        self._usedProducts = Query(filter: #Predicate { $0.isUsed && $0.userId == userId })
        self._usedLSProducts = Query(filter: #Predicate<LSProduct> { $0.isUsed && $0.userId == userId })
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
                        Button(action: {
                            showProfileInfo = true
                        }) {
                            Circle()
                                .fill(.green.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .overlay {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(.green)
                                }
                        }
                        .buttonStyle(PlainButtonStyle())
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
                    VStack(spacing: 24) {
                        // Liked Products Section
                        VStack(alignment: .leading, spacing: 12) {
                            // Section Header
                            NavigationLink(destination: AllLikedProductsView(userId: userId)) {
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
                        
                            // Recent 5 Liked Items - Horizontal Scroll (both Spoonacular and OFFA)
                            if !likedProducts.isEmpty || !likedLSProducts.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        // Spoonacular products
                                        ForEach(Array(likedProducts.prefix(5)), id: \.self) { product in
                                            NavigationLink(destination: DetailProductView(product: product)) {
                                                LikedProductCard(product: product)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }

                                        // OFFA products
                                        ForEach(Array(likedLSProducts.prefix(5)), id: \.self) { product in
                                            NavigationLink(destination: LSProductDetailView(product: product)) {
                                                LikedOFFAProductCard(product: product)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                .padding(.bottom, 16)
                            }

                            if likedProducts.isEmpty && likedLSProducts.isEmpty {
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
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.secondarySystemBackground))
                                )
                                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Liked Recipes Section
                        VStack(alignment: .leading, spacing: 12) {
                            // Section Header
                            NavigationLink(destination: AllLikedRecipesView(userId: userId)) {
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
                                            NavigationLink(destination: RecipeDetailView(userId: userId, sdRecipe: recipe)) {
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
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.secondarySystemBackground))
                                )
                                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
                                .padding(.horizontal, 20)
                            }
                        }

                        // Used Products Section
                        VStack(alignment: .leading, spacing: 12) {
                            // Section Header
                            NavigationLink(destination: AllUsedProductsView(userId: userId)) {
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

                            // Recent 5 Used Products - Horizontal Scroll (both Spoonacular and OFFA)
                            if !usedProducts.isEmpty || !usedLSProducts.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        // Spoonacular products
                                        ForEach(Array(usedProducts.prefix(5)), id: \.self) { product in
                                            NavigationLink(destination: DetailProductView(product: product)) {
                                                UsedProductCard(product: product)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }

                                        // OFFA products
                                        ForEach(Array(usedLSProducts.prefix(5)), id: \.self) { product in
                                            NavigationLink(destination: Text("OFFA Detail View - Coming Soon")) {
                                                UsedOFFAProductCard(product: product)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                .padding(.bottom, 16)
                            }

                            if usedProducts.isEmpty && usedLSProducts.isEmpty {
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
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.secondarySystemBackground))
                                )
                                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
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
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [.red, .red.opacity(0.9)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: .red.opacity(0.4), radius: 10, x: 0, y: 4)
                        .shadow(color: .red.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    .disabled(groups.isEmpty && likedProducts.isEmpty && likedLSProducts.isEmpty && likedRecipes.isEmpty && usedProducts.isEmpty && usedLSProducts.isEmpty)
                    .opacity((groups.isEmpty && likedProducts.isEmpty && likedLSProducts.isEmpty && likedRecipes.isEmpty && usedProducts.isEmpty && usedLSProducts.isEmpty) ? 0.6 : 1.0)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 34)
                .background(
                    ZStack {
                        // Gradient background for overlay
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        Color(.systemBackground).opacity(0.5),
                                        Color(.systemBackground).opacity(0.7),
                                        Color(.systemBackground).opacity(0.9),
                                        Color(.systemBackground).opacity(0.98),
                                        Color(.systemBackground)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 200, alignment: .bottom)
                    }
                    .ignoresSafeArea(.container, edges: .bottom)
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
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
                    viewModel.deleteAllData(groups: groups, products: allProducts, recipes: allRecipes, modelContext: modelContext, notificationManager: notificationManager)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                let totalItems = groups.count + allProducts.count + allRecipes.count
                Text("This will permanently delete ALL data: \(groups.count) groups, \(allProducts.count) products, and \(allRecipes.count) recipes (total: \(totalItems) items). This action cannot be undone.")
            }
            .confirmationDialog(
                "Delete Account",
                isPresented: $showDeleteAccountConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                    impactFeedback.impactOccurred()
                    Task {
                        await performAccountDeletion()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete your account and all associated data including your profile, groups, products, recipes, and notifications. This action CANNOT be undone.")
            }
            .sheet(isPresented: $showReauthSheet) {
                ReauthenticationView(isReauthenticated: $isReauthenticated, viewModel: viewModel)
            }
            .sheet(isPresented: $showProfileInfo) {
                ProfileInfoView(
                    userId: userId,
                    userName: viewModel.userName,
                    userEmail: Auth.auth().currentUser?.email ?? "No email",
                    onSignOut: {
                        Task {
                            viewModel.signOut()
                        }
                    },
                    onDeleteAccount: {
                        showDeleteAccountConfirmation = true
                    }
                )
            }
            .alert("Deletion Failed", isPresented: $showDeletionError) {
                Button("OK", role: .cancel) { }
            } message: {
                if let error = deletionError {
                    Text(error)
                }
            }
            .alert("Login Required", isPresented: $showReauthAlert) {
                Button("Continue") {
                    showReauthSheet = true
                }
                Button("Cancel", role: .cancel) {
                    // User cancelled, reset state
                    deletionInProgress = false
                }
            } message: {
                Text("To delete your account, you need to log in again for security reasons. Would you like to continue?")
            }
            .onChange(of: isReauthenticated) { _, newValue in
                if newValue {
                    // Re-authentication successful, try deletion again
                    Task {
                        await performAccountDeletion()
                    }
                }
            }
        }
    }

    // MARK: - Account Deletion Helper
    private func performAccountDeletion() async {
        deletionInProgress = true

        do {
            try await viewModel.deleteAccount(
                groups: groups,
                products: allProducts,
                recipes: allRecipes,
                modelContext: modelContext,
                notificationManager: notificationManager
            )

            // Account deleted successfully - user will be automatically signed out
            await MainActor.run {
                deletionInProgress = false
            }

        } catch let error as NSError {
            await MainActor.run {
                deletionInProgress = false

                // Check if re-authentication is required
                if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                    // Show explanation alert before re-authentication
                    showReauthAlert = true
                } else {
                    // Show error alert
                    deletionError = error.localizedDescription
                    showDeletionError = true
                }
            }
        }
    }
}

// MARK: - Profile Info View
struct ProfileInfoView: View {
    @Environment(\.dismiss) var dismiss
    let userId: String
    let userName: String
    let userEmail: String
    let onSignOut: () -> Void
    let onDeleteAccount: () -> Void
    @State private var showEditAllergies = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Profile Icon
                Circle()
                    .fill(.green.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.green)
                    }
                    .padding(.top, 20)

                // User Information
                VStack(spacing: 16) {
                    // Name Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Text(userName.isEmpty ? "User" : userName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 13)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)

                    // Email Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Text(userEmail)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 13)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)

                    // Edit Allergies Button
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        showEditAllergies = true
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Allergies & Intolerances")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)

                                Text("Edit your food preferences")
                                    .font(.body)
                                    .foregroundStyle(.primary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.green)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 13)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)

                Spacer()

                // Action Buttons
                VStack(spacing: 16) {
                    // Sign Out Button
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        dismiss() // Dismiss the sheet first
                        onSignOut() // Then trigger sign out
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

                    // Delete Account Button
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        dismiss() // Dismiss the sheet first

                        // Add a small delay to ensure the sheet has fully dismissed
                        // before presenting the confirmation dialog
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                            onDeleteAccount() // Then trigger deletion
                        }
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Delete Account")
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [.red, .red.opacity(0.9)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: .red.opacity(0.4), radius: 10, x: 0, y: 4)
                        .shadow(color: .red.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 34)
            }
            .navigationTitle("Account Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.green)
                }
            }
            .sheet(isPresented: $showEditAllergies) {
                EditAllergiesView(userId: userId)
            }
        }
    }
}

// MARK: - Liked Product Card Component
struct LikedProductCard: View {
    @Environment(\.colorScheme) var colorScheme
    let product: Product

    var body: some View {
        let cardContent = VStack(alignment: .center, spacing: 8) {
            // Product Image
            ZStack {
                if let imageLink = product.imageLink, !imageLink.isEmpty {
                    RobustAsyncImage(url: imageLink) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
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

        return cardContent
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.06) : product.borderColor.opacity(0.15),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.1), radius: 8, x: 0, y: 3)
            .shadow(color: colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.6), radius: 1, x: 0, y: -1)
    }
}

// MARK: - Liked OFFA Product Card Component
struct LikedOFFAProductCard: View {
    @Environment(\.colorScheme) var colorScheme
    let product: LSProduct

    var body: some View {
        let cardContent = VStack(alignment: .center, spacing: 8) {
            // Product Image
            ZStack {
                if let imageURL = product.imageFrontURL ?? product.imageLink, !imageURL.isEmpty {
                    RobustAsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
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

        return cardContent
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.06) : Color.red.opacity(0.15),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.1), radius: 8, x: 0, y: 3)
            .shadow(color: colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.6), radius: 1, x: 0, y: -1)
    }
}

// MARK: - Liked Recipe Card Component
struct LikedRecipeCard: View {
    @Environment(\.colorScheme) var colorScheme
    let recipe: SDRecipe

    var body: some View{
        let cardContent = VStack(alignment: .center, spacing: 8) {
            // Recipe Image
            ZStack {
                if let imageLink = recipe.image, !imageLink.isEmpty {
                    RobustAsyncImage(url: imageLink) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
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

        return cardContent
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.06) : Color.orange.opacity(0.15),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.1), radius: 8, x: 0, y: 3)
            .shadow(color: colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.6), radius: 1, x: 0, y: -1)
    }
}

// MARK: - Used Product Card Component
struct UsedProductCard: View {
    @Environment(\.colorScheme) var colorScheme
    let product: Product

    var body: some View {
        let cardContent = VStack(alignment: .center, spacing: 8) {
            // Product Image
            ZStack {
                if let imageLink = product.imageLink, !imageLink.isEmpty {
                    RobustAsyncImage(url: imageLink) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
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
                            .foregroundStyle(Color(.systemBackground))
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

        return cardContent
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.06) : Color.blue.opacity(0.15),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.1), radius: 8, x: 0, y: 3)
            .shadow(color: colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.6), radius: 1, x: 0, y: -1)
    }
}

// MARK: - Used OFFA Product Card Component
struct UsedOFFAProductCard: View {
    @Environment(\.colorScheme) var colorScheme
    let product: LSProduct

    var body: some View {
        let cardContent = VStack(alignment: .center, spacing: 8) {
            // Product Image
            ZStack {
                if let imageURL = product.imageFrontURL ?? product.imageLink, !imageURL.isEmpty {
                    RobustAsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
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
                            .foregroundStyle(Color(.systemBackground))
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

        return cardContent
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.06) : Color.blue.opacity(0.15),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.1), radius: 8, x: 0, y: 3)
            .shadow(color: colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.6), radius: 1, x: 0, y: -1)
    }
}

#Preview {
    ProfileView(userId: "preview_user_id")
}

