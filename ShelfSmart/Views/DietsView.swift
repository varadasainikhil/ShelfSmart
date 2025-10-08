//
//  DietsView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/15/25.
//

import SwiftUI

struct DietsView: View {
    @State private var viewModel = RandomRecipeViewModel()
    @State private var navigateToMealTypes = false
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
                            Text("Select Your")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("Diets")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        
                        // Selection counter
                        if !viewModel.selectedDiets.isEmpty {
                            Text("\(viewModel.selectedDiets.count) selected")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Subtitle
                    Text("Choose dietary preferences that match your lifestyle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
                
                // Diets Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(Diet.allCases, id: \.self) { diet in
                            DietCard(
                                diet: diet,
                                isSelected: viewModel.selectedDiets.contains(diet.apiValue)
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if viewModel.selectedDiets.contains(diet.apiValue) {
                                        viewModel.removeDiet(diet: diet)
                                    } else {
                                        viewModel.addDiet(diet: diet)
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
                        // Surprise Me Button
                        Button(action: {
                            Task {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()

                                await viewModel.completelyRandomRecipe()
                                navigateToRandomRecipe = true
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.green)
                                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))

                                if viewModel.isLoading {
                                    HStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .scaleEffect(0.8)
                                            .tint(Color(.systemBackground))
                                        Text("Loading...")
                                            .foregroundStyle(Color(.systemBackground))
                                    }
                                } else {
                                    HStack {
                                        Image(systemName: "sparkles")
                                        Text("Surprise Me!")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundStyle(Color(.systemBackground))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        .disabled(viewModel.isLoading)
                        .padding(.trailing, 3)
                        
                        // Next Button
                        NavigationLink(destination: MealTypesView(viewModel: viewModel)) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.green)
                                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))

                                HStack {
                                    Text("Next")
                                        .fontWeight(.semibold)
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
            .navigationDestination(isPresented: $navigateToRandomRecipe) {
                RandomRecipeView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Diet Card Component
struct DietCard: View {
    let diet: Diet
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Content Container
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(width: 110, height: 110)
                    
                    // Content
                    VStack(spacing: 6) {
                        // Diet icon/emoji based on type
                        Text(diet.emoji)
                            .font(.system(size: 28))
                        
                        Text(diet.displayName)
                            .font(.system(size: 11, weight: .medium))
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
                
                // Optional: Brief description (can be shown on tap or as tooltip)
                if isSelected {
                    Text(diet.description)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 4)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    DietsView()
}
