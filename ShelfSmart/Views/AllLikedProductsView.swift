//
//  AllLikedProductsView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/25/25.
//

import FirebaseAuth
import SwiftData
import SwiftUI

struct AllLikedProductsView: View {
    @Environment(\.modelContext) var modelContext
    @Query private var allProducts: [Product]
    
    // Computed property for liked products by current user
    var likedProducts: [Product] {
        let currentUserId = FirebaseAuth.Auth.auth().currentUser?.uid ?? ""
        return allProducts.filter { product in
            product.isLiked && product.userId == currentUserId
        }
    }
    
    var body: some View {
        NavigationStack {
            if likedProducts.isEmpty {
                // Empty State
                VStack(spacing: 24) {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Circle()
                            .fill(.red.opacity(0.1))
                            .frame(width: 80, height: 80)
                            .overlay {
                                Image(systemName: "heart.slash")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.red.opacity(0.7))
                            }
                        
                        VStack(spacing: 8) {
                            Text("No Liked Products")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            Text("Products you like will appear here")
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
                    LazyVStack(spacing: 20) {
                        ForEach(likedProducts, id: \.self) { product in
                            NavigationLink(destination: DetailProductView(product: product)) {
                                LikedProductCardView(product: product)
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
        .navigationTitle("Liked Products")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Liked Product Card Component (Home View Style)
struct LikedProductCardView: View {
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
            
            // Product Info
            VStack(alignment: .leading, spacing: 6) {
                Text(product.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
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
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(product.borderColor.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    AllLikedProductsView()
}
