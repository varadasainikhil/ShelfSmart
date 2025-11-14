//
//  HomeView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/25/25.
//
import SwiftData
import SwiftUI
import FirebaseAuth

struct HomeView: View {
    let userId: String  // Passed from AuthenticatedView

    @Environment(\.modelContext) var modelContext
    @State var showingAddProduct : Bool = false
    @State private var addProductViewModel = AddProductViewViewModel()

    // Optimized query with predicate-based filtering
    @Query private var groups: [GroupedProducts]
    @Query private var offaGroups: [GroupedOFFAProducts]

    init(userId: String) {
        self.userId = userId

        // Predicate for Spoonacular products
        let predicate = #Predicate<GroupedProducts> { group in
            group.userId == userId
        }
        self._groups = Query(filter: predicate, sort: \GroupedProducts.expirationDate)

        // Predicate for OFFA products
        let offaPredicate = #Predicate<GroupedOFFAProducts> { group in
            group.userId == userId
        }
        self._offaGroups = Query(filter: offaPredicate, sort: \GroupedOFFAProducts.expirationDate)
    }

    // Combine and sort both product types by expiration date
    private var allGroupsSorted: [(date: Date, isOFFA: Bool, index: Int)] {
        var combined: [(date: Date, isOFFA: Bool, index: Int)] = []

        // Add Spoonacular groups
        for (index, group) in groups.enumerated() {
            combined.append((date: group.expirationDate, isOFFA: false, index: index))
        }

        // Add OFFA groups
        for (index, group) in offaGroups.enumerated() {
            combined.append((date: group.expirationDate, isOFFA: true, index: index))
        }

        // Sort by expiration date
        return combined.sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Your")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            Text("Products")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Subtitle
                    Text("Track expiration dates and manage your shelf")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
                
                // Content Section
                ZStack {
                    if groups.isEmpty && offaGroups.isEmpty {
                        // Empty State
                        VStack(spacing: 20) {
                            Spacer()
                            
                            VStack(spacing: 16) {
                                Circle()
                                    .fill(.green.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                    .overlay {
                                        Image(systemName: "archivebox")
                                            .font(.system(size: 32))
                                            .foregroundStyle(.green)
                                    }
                                
                                VStack(spacing: 8) {
                                    Text("No products yet")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                    
                                    Text("Start by adding your first product to track its expiration date")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                            }
                            
                            Spacer()
                        }
                    } else {
                        // Products List
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(spacing: 16) {
                                    ForEach(allGroupsSorted, id: \.date) { item in
                                        if item.isOFFA {
                                            // OFFA Product Group
                                            EnhancedOFFAGroupView(group: offaGroups[item.index])
                                        } else {
                                            // Spoonacular Product Group
                                            EnhancedGroupView(group: groups[item.index])
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 100) // Space for floating button
                            }
                            .scrollContentBackground(.hidden)
                        }
                    }
                    
                    // Floating Add Button
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                showingAddProduct = true
                            } label: {
                                ZStack {
                                    // Outer glow
                                    Circle()
                                        .fill(.green)
                                        .frame(width: 60, height: 60)
                                        .shadow(color: .green.opacity(0.4), radius: 12, x: 0, y: 6)
                                        .shadow(color: .green.opacity(0.2), radius: 4, x: 0, y: 2)

                                    // Icon
                                    Image(systemName: "plus")
                                        .font(.system(size: 26, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 34)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddProduct, onDismiss: addProductViewModel.resetAllFields) {
                AddProductView(userId: userId, viewModel: addProductViewModel)
            }
        }
    }
}

// MARK: - Enhanced Group View Component
struct EnhancedGroupView: View {
    @Environment(\.colorScheme) var colorScheme
    var group: GroupedProducts

    // Computed property to filter out used products
    private var activeProducts: [Product] {
        group.products?.filter { !$0.isUsed } ?? []
    }

    var body: some View {
        VStack(spacing: 14) {
            // Group Header
            HStack(spacing: 12) {
                let status = getGroupStatus(for: group)

                VStack(alignment: .leading, spacing: 3) {
                    Text(status.message)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(status.color)

                    Text("\(activeProducts.count) item\(activeProducts.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                // Status indicator with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [status.color.opacity(0.2), status.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: status.icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(status.color.opacity(0.9))
                }
                // Soft shadow for indicator
                .shadow(color: status.color.opacity(0.2), radius: 4, x: 0, y: 2)
            }

            // Products in group (only active/non-used)
            VStack(spacing: 10) {
                ForEach(activeProducts, id: \.id) { product in
                    NavigationLink(destination: DetailProductView(product: product)) {
                        EnhancedCardView(product: product)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(0.05)
                        : Color.clear,
                    lineWidth: 0.5
                )
        )
        // Neumorphic shadows - outer depth
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.7) : Color.black.opacity(0.1), radius: 16, x: 0, y: 6)
        .shadow(color: colorScheme == .dark ? Color.white.opacity(0.08) : Color.white, radius: 2, x: 0, y: -1)
    }
}

// MARK: - Enhanced OFFA Group View Component
struct EnhancedOFFAGroupView: View {
    @Environment(\.colorScheme) var colorScheme
    var group: GroupedOFFAProducts

    // Computed property to filter out used products
    private var activeProducts: [LSProduct] {
        group.offaProducts?.filter { !$0.isUsed } ?? []
    }

    var body: some View {
        VStack(spacing: 14) {
            // Group Header
            HStack(spacing: 12) {
                let status = getOFFAGroupStatus(for: group)

                VStack(alignment: .leading, spacing: 3) {
                    Text(status.message)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(status.color)

                    Text("\(activeProducts.count) item\(activeProducts.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                // Status indicator with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [status.color.opacity(0.2), status.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: status.icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(status.color.opacity(0.9))
                }
                // Soft shadow for indicator
                .shadow(color: status.color.opacity(0.2), radius: 4, x: 0, y: 2)
            }

            // Products in group (only active/non-used)
            VStack(spacing: 10) {
                ForEach(activeProducts, id: \.id) { product in
                    NavigationLink(destination: Text("Detail View - Coming Soon")) {
                        EnhancedOFFACardView(product: product)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(0.05)
                        : Color.clear,
                    lineWidth: 0.5
                )
        )
        // Neumorphic shadows - outer depth
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.7) : Color.black.opacity(0.1), radius: 16, x: 0, y: 6)
        .shadow(color: colorScheme == .dark ? Color.white.opacity(0.08) : Color.white, radius: 2, x: 0, y: -1)
    }
}

// MARK: - Enhanced OFFA Card View Component
struct EnhancedOFFACardView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(NotificationManager.self) var notificationManager
    @Environment(\.colorScheme) var colorScheme
    var product: LSProduct

    // MARK: - Subviews

    private var productImageView: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let imageURL = product.imageFrontURL ?? product.imageLink, !imageURL.isEmpty {
                    RobustAsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    }
                } else {
                    Image("placeholder")
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(width: 68, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(Color(.systemGray6))
            )
            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.1), radius: 4, x: 2, y: 2)
            .shadow(color: colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.8), radius: 3, x: -1, y: -1)

            if product.isExpired {
                expirationBadge
            }
        }
    }

    private var expirationBadge: some View {
        Circle()
            .fill(.red)
            .frame(width: 26, height: 26)
            .overlay {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
            .shadow(color: .red.opacity(0.4), radius: 4, x: 0, y: 2)
            .offset(x: 5, y: -5)
    }

    private var productInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.title)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .strikethrough(product.isUsed, color: .primary)

            if let brand = product.brand, !brand.isEmpty {
                Text(brand)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
    }

    private var actionButton: some View {
        Button(action: {
            if product.isExpired {
                handleDeleteExpiredOFFAProduct(product: product, modelContext: modelContext, notificationManager: notificationManager)
            } else {
                handleMarkOFFAAsUsed(product: product, modelContext: modelContext, notificationManager: notificationManager)
            }
        }) {
            if product.isExpired {
                Image(systemName: "trash.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.red.opacity(0.8))
            } else {
                Image(systemName: product.isUsed ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(product.isUsed ? .green : .gray.opacity(0.6))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 44, height: 44)
    }

    private var cardContent: some View {
        HStack(spacing: 14) {
            productImageView
            productInfoView
            Spacer(minLength: 8)
            actionButton
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 13)
            .fill(Color(.systemBackground))
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 13)
            .stroke(
                colorScheme == .dark
                    ? Color.white.opacity(0.08)
                    : Color.clear,
                lineWidth: 0.5
            )
    }

    // MARK: - Body

    var body: some View {
        cardContent
            .padding(14)
            .background(cardBackground)
            .overlay(cardBorder)
            .shadow(
                color: colorScheme == .dark ? Color.black.opacity(0.6) : Color.black.opacity(0.08),
                radius: 10,
                x: 0,
                y: 4
            )
            .shadow(
                color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.5),
                radius: 2,
                x: 0,
                y: -1
            )
            .opacity(product.isUsed ? 0.6 : 1.0)
            .grayscale(product.isUsed ? 0.8 : 0.0)
    }
}

// MARK: - Enhanced Card View Component
struct EnhancedCardView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(NotificationManager.self) var notificationManager
    @Environment(\.colorScheme) var colorScheme
    var product: Product

    // MARK: - Subviews (extracted to help compiler type-checking)

    private var productImageView: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let imageLink = product.imageLink, !imageLink.isEmpty {
                    RobustAsyncImage(url: imageLink) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    }
                } else {
                    Image("placeholder")
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(width: 68, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(Color(.systemGray6))
            )
            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.1), radius: 4, x: 2, y: 2)
            .shadow(color: colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.8), radius: 3, x: -1, y: -1)

            if product.isExpired {
                expirationBadge
            }
        }
    }

    private var expirationBadge: some View {
        Circle()
            .fill(.red)
            .frame(width: 26, height: 26)
            .overlay {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
            .shadow(color: .red.opacity(0.4), radius: 4, x: 0, y: 2)
            .offset(x: 5, y: -5)
    }

    private var productInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.title)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .strikethrough(product.isUsed, color: .primary)

            if let description = product.productDescription ?? product.generatedText {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let brand = product.brand, !brand.isEmpty {
                Text(brand)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
    }

    private var actionButton: some View {
        Button(action: {
            if product.isExpired {
                handleDeleteExpiredProduct(product: product, modelContext: modelContext, notificationManager: notificationManager)
            } else {
                handleMarkAsUsed(product: product, modelContext: modelContext, notificationManager: notificationManager)
            }
        }) {
            if product.isExpired {
                Image(systemName: "trash.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.red.opacity(0.8))
            } else {
                Image(systemName: product.isUsed ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(product.isUsed ? .green : .gray.opacity(0.6))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 44, height: 44)
    }

    private var cardContent: some View {
        HStack(spacing: 14) {
            productImageView
            productInfoView
            Spacer(minLength: 8)
            actionButton
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 13)
            .fill(Color(.systemBackground))
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 13)
            .stroke(
                colorScheme == .dark
                    ? Color.white.opacity(0.08)
                    : Color.clear,
                lineWidth: 0.5
            )
    }

    // MARK: - Body

    var body: some View {
        cardContent
            .padding(14)
            .background(cardBackground)
            .overlay(cardBorder)
            .shadow(
                color: colorScheme == .dark ? Color.black.opacity(0.6) : Color.black.opacity(0.08),
                radius: 10,
                x: 0,
                y: 4
            )
            .shadow(
                color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.5),
                radius: 2,
                x: 0,
                y: -1
            )
            .opacity(product.isUsed ? 0.6 : 1.0)
            .grayscale(product.isUsed ? 0.8 : 0.0)
    }
}

// MARK: - Helper Functions
private func handleMarkAsUsed(product: Product, modelContext: ModelContext, notificationManager: NotificationManager) {
    ProductHelpers.markProductAsUsed(product: product, modelContext: modelContext, notificationManager: notificationManager)
}

private func handleDeleteExpiredProduct(product: Product, modelContext: ModelContext, notificationManager: NotificationManager) {
    // Use shared delete function with proper error handling
    do {
        try ProductHelpers.deleteProduct(product, modelContext: modelContext, notificationManager: notificationManager)
    } catch {
        print("❌ Failed to delete expired product: \(error)")
        // Error is now properly logged instead of being silently swallowed
    }
}

private func getGroupStatus(for group: GroupedProducts) -> (message: String, color: Color, icon: String) {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let expiry = calendar.startOfDay(for: group.expirationDate)
    let days = calendar.dateComponents([.day], from: today, to: expiry).day ?? 0

    if days < 0 {
        return ("Expired \(abs(days)) day\(abs(days) == 1 ? "" : "s") ago", .red, "exclamationmark.triangle.fill")
    } else if days == 0 {
        return ("Expires today", .orange, "clock.fill")
    } else if days <= 3 {
        return ("Expires in \(days) day\(days == 1 ? "" : "s")", .orange, "clock.fill")
    } else {
        return ("Expires in \(days) days", .green, "leaf.fill")
    }
}

private func getOFFAGroupStatus(for group: GroupedOFFAProducts) -> (message: String, color: Color, icon: String) {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let expiry = calendar.startOfDay(for: group.expirationDate)
    let days = calendar.dateComponents([.day], from: today, to: expiry).day ?? 0

    if days < 0 {
        return ("Expired \(abs(days)) day\(abs(days) == 1 ? "" : "s") ago", .red, "exclamationmark.triangle.fill")
    } else if days == 0 {
        return ("Expires today", .orange, "clock.fill")
    } else if days <= 3 {
        return ("Expires in \(days) day\(days == 1 ? "" : "s")", .orange, "clock.fill")
    } else {
        return ("Expires in \(days) days", .green, "leaf.fill")
    }
}

private func handleMarkOFFAAsUsed(product: LSProduct, modelContext: ModelContext, notificationManager: NotificationManager) {
    ProductHelpers.markOFFAProductAsUsed(product: product, modelContext: modelContext, notificationManager: notificationManager)
}

private func handleDeleteExpiredOFFAProduct(product: LSProduct, modelContext: ModelContext, notificationManager: NotificationManager) {
    // Use shared delete function with proper error handling
    do {
        try ProductHelpers.deleteOFFAProduct(product, modelContext: modelContext, notificationManager: notificationManager)
    } catch {
        print("❌ Failed to delete expired OFFA product: \(error)")
        // Error is now properly logged instead of being silently swallowed
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: GroupedProducts.self, Product.self, configurations: config)
        let context = container.mainContext
        
        // Add sample products
        let threeDaysFromNow = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? Date.now)
        let fiveDaysFromNow = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 5, to: .now) ?? Date.now)
        let twoDaysAgo = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? Date.now)
        
        // Use empty string to match what HomeView uses when no user is authenticated
        let sampleUserId = ""
        let sampleGroups = [
            GroupedProducts(expirationDate: threeDaysFromNow, products: [
                Product(spoonacularId: 123456789, barcode: "123456789", title: "Milk", brand: "Organic Milk", breadcrumbs: ["Dairy", "Milk"], recipeIds: [111, 222, 333], expirationDate: threeDaysFromNow),
                Product(spoonacularId: 12345679, barcode: "12345679", title: "Bread", brand: "Whole Wheat Bread", breadcrumbs: ["Bakery", "Bread"], recipeIds: [444, 555, 666], expirationDate: threeDaysFromNow)
            ], userId: sampleUserId),
            GroupedProducts(expirationDate: fiveDaysFromNow, products: [
                Product(spoonacularId: 12345689, barcode: "12345689", title: "Eggs", brand: "Free-range eggs", breadcrumbs: ["Dairy", "Eggs"], recipeIds: [777, 888, 999], expirationDate: fiveDaysFromNow),
                Product(spoonacularId: 1234589, barcode: "1234589", title: "Yogurt", brand: "Greek Yogurt", breadcrumbs: ["Dairy", "Yogurt"], recipeIds: [101, 202, 303], expirationDate: fiveDaysFromNow)
            ], userId: sampleUserId),
            GroupedProducts(expirationDate: twoDaysAgo, products: [
                Product(spoonacularId: 345689, barcode: "345689", title: "Honey", brand: "Organic Honey", breadcrumbs: ["Sweeteners", "Honey"], recipeIds: [404, 505, 606], expirationDate: twoDaysAgo),
                Product(spoonacularId: 45689, barcode: "45689", title: "Tortilla", brand: "Corn Tortilla", breadcrumbs: ["Bakery", "Tortilla"], recipeIds: [707, 808, 909], expirationDate: twoDaysAgo)
            ], userId: sampleUserId)
        ]
        
        for group in sampleGroups {
            context.insert(group)
        }
        
        return HomeView(userId: "preview_user_id")
            .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}
 
