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
    @Environment(\.modelContext) var modelContext
    @State var showingAddProduct : Bool = false
    @State private var addProductViewModel = AddProductViewViewModel()

    // Optimized query with predicate-based filtering
    @Query private var groups: [GroupedProducts]

    init() {
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        let predicate = #Predicate<GroupedProducts> { group in
            group.userId == currentUserId
        }
        self._groups = Query(filter: predicate, sort: \GroupedProducts.expirationDate)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("Products")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        
                        // Product count indicator
                        if !groups.isEmpty {
                            VStack(spacing: 2) {
                                Text("\(groups.count)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.green)
                                Text("groups")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Subtitle
                    Text("Track expiration dates and manage your shelf")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
                
                // Content Section
                ZStack {
                    if groups.isEmpty {
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
                                LazyVStack(spacing: 16) {
                                    ForEach(groups) { group in
                                        EnhancedGroupView(group: group)
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
                                Circle()
                                    .fill(.green)
                                    .frame(width: 56, height: 56)
                                    .overlay {
                                        Image(systemName: "plus")
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundStyle(.white)
                                    }
                                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 34)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddProduct, onDismiss: addProductViewModel.resetAllFields) {
                AddProductView(viewModel: addProductViewModel)
            }
        }
    }
}

// MARK: - Enhanced Group View Component
struct EnhancedGroupView: View {
    var group: GroupedProducts

    // Computed property to filter out used products
    private var activeProducts: [Product] {
        group.products?.filter { !$0.isUsed } ?? []
    }

    var body: some View {
        VStack(spacing: 12) {
            // Group Header
            HStack {
                let status = getGroupStatus(for: group)

                VStack(alignment: .leading, spacing: 2) {
                    Text(status.message)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(status.color)

                    Text("\(activeProducts.count) item\(activeProducts.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Status indicator
                Circle()
                    .fill(status.color.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: status.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(status.color)
                    }
            }
            
            // Products in group (only active/non-used)
            VStack(spacing: 8) {
                ForEach(activeProducts, id: \.id) { product in
                    NavigationLink(destination: DetailProductView(product: product)) {
                        EnhancedCardView(product: product)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Enhanced Card View Component
struct EnhancedCardView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(NotificationManager.self) var notificationManager
    var product: Product

    var body: some View {
        HStack(spacing: 12) {
            // Product Image
            Group {
                if let imageLink = product.imageLink, !imageLink.isEmpty {
                    // Convert HTTP to HTTPS if needed for App Transport Security
                    let secureImageLink = imageLink.hasPrefix("http://") ? imageLink.replacingOccurrences(of: "http://", with: "https://") : imageLink
                    AsyncImage(url: URL(string: secureImageLink)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else if phase.error != nil {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        } else {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                } else {
                    Image("placeholder")
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .strikethrough(product.isUsed, color: .black)
                
                if let description = product.productDescription ?? product.generatedText {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                if let brand = product.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Mark as Used Button
            Button(action: {
                handleMarkAsUsed(product: product, modelContext: modelContext, notificationManager: notificationManager)
            }) {
                Image(systemName: product.isUsed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(product.isUsed ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(product.borderColor.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(product.borderColor.opacity(0.3), lineWidth: 1)
                )
        )
        .opacity(product.isUsed ? 0.6 : 1.0)
        .grayscale(product.isUsed ? 0.8 : 0.0)
    }
}

// MARK: - Helper Functions
private func handleMarkAsUsed(product: Product, modelContext: ModelContext, notificationManager: NotificationManager) {
    // 1. Mark as used
    product.markUsed()

    // 2. Cancel notifications
    notificationManager.deleteScheduledNotifications(for: product)

    // 3. Delete ALL recipes (including liked ones)
    if let recipes = product.recipes {
        for recipe in recipes {
            modelContext.delete(recipe)
        }
    }

    // 4. Remove from GroupedProducts
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

    // 5. Handle product based on liked status
    if product.isLiked {
        // Keep as standalone - null out the group relationship
        product.groupedProducts = nil
    } else {
        // Delete the product
        modelContext.delete(product)
    }

    // 6. Save
    try? modelContext.save()
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
        
        return HomeView()
            .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}
 
