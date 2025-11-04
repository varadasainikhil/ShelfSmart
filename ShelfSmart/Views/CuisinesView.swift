//
//  Cuisines.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/15/25.
//

import SwiftUI

struct CuisinesView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: RandomRecipeViewModel
    @State private var navigateToIntolerances = false
    
    // Adaptive grid with better spacing
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Select Your")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("Cuisines")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        
                        // Selection counter
                        if !viewModel.selectedCuisines.isEmpty {
                            Text("\(viewModel.selectedCuisines.count) selected")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Subtitle
                    Text("Choose cuisines that match your taste preferences")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
                
                // Cuisines Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(Cuisine.allCases, id: \.self) { cuisine in
                            CuisineCard(
                                cuisine: cuisine,
                                isSelected: viewModel.selectedCuisines.contains(cuisine.apiValue)
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if viewModel.selectedCuisines.contains(cuisine.apiValue) {
                                        viewModel.removeCuisine(cuisine: cuisine)
                                    } else {
                                        viewModel.addCuisine(cuisine: cuisine)
                                    }
                                }
                                
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 100) // Extra space for bottom buttons
                }
                
                Spacer()
            }
            .overlay(alignment: .bottom) {
                // Bottom Action Buttons
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        // Back Button
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            dismiss()
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.green)
                                    .conditionalGlassEffect()

                                HStack {
                                    Image(systemName: "arrow.left")
                                    Text("Back")
                                        .fontWeight(.bold)
                                }
                                .foregroundStyle(Color(.systemBackground))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        .padding(.trailing, 3)

                        // Next Button
                        NavigationLink(destination: IntolerancesView(viewModel: viewModel)) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.green)
                                    .conditionalGlassEffect()

                                HStack {
                                    Text("Next")
                                        .fontWeight(.bold)
                                    Image(systemName: "arrow.right")
                                }
                                .foregroundStyle(Color(.systemBackground))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        .padding(.leading, 3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 34)
                .background(
                    ZStack {
                        // Slight blur at the top
                        Rectangle()
                            .fill(.regularMaterial)
                            .mask(
                                LinearGradient(
                                    colors: [.black.opacity(0.3), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // Solid color gradient (white/black based on color scheme)
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
            .navigationBarBackButtonHidden(true)
        }
    }
}

// MARK: - Cuisine Card Component
struct CuisineCard: View {
    let cuisine: Cuisine
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Emoji and Content Container
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(width: 110, height: 110)
                    
                    // Content
                    VStack(spacing: 8) {
                        Text(cuisine.flagEmoji)
                            .font(.system(size: 32))
                        
                        Text(cuisine.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(width: 110, height: 110)
                    
                    // Selection indicator
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.green, lineWidth: 3)
                            .frame(width: 110, height: 110)
                        
                        // Checkmark
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(Color(.systemBackground))
                                    .background(
                                        Circle()
                                            .fill(.green)
                                            .frame(width: 24, height: 24)
                                    )
                                    .offset(x: 6, y: -6)
                            }
                            Spacer()
                        }
                        .frame(width: 110, height: 110)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    CuisinesView(viewModel: RandomRecipeViewModel(userId: "preview_user_id"))
}
