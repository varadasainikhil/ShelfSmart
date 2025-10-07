//
//  AllUsedProductsView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/25/25.
//

import FirebaseAuth
import SwiftData
import SwiftUI

struct AllUsedProductsView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Product.dateAdded, order: .reverse) private var allProducts: [Product]
    @State private var currentUserId: String = Auth.auth().currentUser?.uid ?? ""

    // Computed property for used products by current user
    // Note: Filtering at app level for now since @Query predicates don't support dynamic user IDs well
    // For better performance with large datasets, consider implementing custom init with FetchDescriptor
    var usedProducts: [Product] {
        return allProducts.filter { $0.isUsed && $0.userId == currentUserId }
    }

    var body: some View {
        NavigationStack {
            if usedProducts.isEmpty {
                // Empty State
                VStack(spacing: 24) {
                    Spacer()

                    VStack(spacing: 16) {
                        Circle()
                            .fill(.blue.opacity(0.1))
                            .frame(width: 80, height: 80)
                            .overlay {
                                Image(systemName: "tray")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.blue.opacity(0.7))
                            }

                        VStack(spacing: 8) {
                            Text("No Used Products")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)

                            Text("Products you mark as used will appear here")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(usedProducts, id: \.self) { product in
                            NavigationLink(destination: DetailProductView(product: product)) {
                                UsedProductCardView(product: product)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 100) // Extra space for navigation
                }
            }
        }
        .navigationTitle("Used Products")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Used Product Card Component
struct UsedProductCardView: View {
    let product: Product

    var body: some View {
        HStack(spacing: 16) {
            // Product Image
            Group {
                if let imageLink = product.imageLink, !imageLink.isEmpty {
                    SimpleAsyncImage(url: imageLink) { image in
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
            .frame(width: 70, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemGray6))
            )
            .grayscale(0.8)
            .opacity(0.7)

            // Product Info
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(product.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .strikethrough(true, color: .primary)

                    Spacer()

                    // Used indicator badge
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.green)
                }

                if let description = product.productDescription ?? product.generatedText, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                if let brand = product.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 70, alignment: .top) // Ensure consistent height and top alignment
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color(.label).opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.blue.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    AllUsedProductsView()
}
