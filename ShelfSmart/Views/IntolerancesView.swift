//
//  IntolerancesView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/15/25.
//

import SwiftUI

struct IntolerancesView: View {
    @State var viewModel: RandomRecipeViewModel
    @State private var navigateToRandomRecipe = false
    
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
                            Text("Any")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("Allergies?")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        
                        // Selection counter
                        if !viewModel.selectedIntolerances.isEmpty {
                            Text("\(viewModel.selectedIntolerances.count) selected")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Subtitle
                    Text("Select any food allergies or intolerances you have")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
                
                // Intolerances Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(Intolerances.allCases, id: \.self) { intolerance in
                            IntoleranceCard(
                                intolerance: intolerance,
                                isSelected: viewModel.selectedIntolerances.contains(intolerance.apiValue)
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if viewModel.selectedIntolerances.contains(intolerance.apiValue) {
                                        viewModel.removeIntolerance(intolerance: intolerance)
                                    } else {
                                        viewModel.addIntolerance(intolerance: intolerance)
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
                // Bottom Action Button
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        // Next Button
                        Button(action: {
                            // Call the function first, then navigate
                            Task {
                                await viewModel.customRandomRecipe()
                                // Navigate only after the API call completes
                                await MainActor.run {
                                    navigateToRandomRecipe = true
                                }
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .foregroundStyle(.green)
                                
                                if viewModel.isLoading {
                                    HStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .scaleEffect(0.8)
                                            .tint(.white)
                                        Text("Loading...")
                                            .foregroundStyle(.white)
                                    }
                                } else {
                                    HStack {
                                        Text("Get Recipes")
                                        Image(systemName: "arrow.right")
                                    }
                                    .foregroundStyle(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .shadow(radius: 5)
                        }
                        .disabled(viewModel.isLoading)
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
            .navigationDestination(isPresented: $navigateToRandomRecipe) {
                RandomRecipeView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Intolerance Card Component
struct IntoleranceCard: View {
    let intolerance: Intolerances
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
                        Text(intolerance.emoji)
                            .font(.system(size: 32))
                        
                        Text(intolerance.displayName)
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
                                    .foregroundStyle(.white)
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
    IntolerancesView(viewModel: RandomRecipeViewModel())
}
