//
//  MealTypesView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/15/25.
//

import SwiftUI

struct MealTypesView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: RandomRecipeViewModel
    @State private var selectedMealTypes = Set<String>()
    
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
                            Text("Choose Your")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("Meal Types")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        
                        // Selection counter
                        if !viewModel.selectedMealTypes.isEmpty {
                            Text("\(viewModel.selectedMealTypes.count) selected")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Subtitle
                    Text("Select the types of meals you're interested in")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
                
                // Meal Types Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(MealType.allCases, id: \.self) { mealType in
                            MealTypeCard(
                                mealType: mealType,
                                isSelected: viewModel.selectedMealTypes.contains(mealType.apiValue)
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if viewModel.selectedMealTypes.contains(mealType.apiValue) {
                                        viewModel.removeMealType(mealType: mealType)
                                    } else {
                                        viewModel.addMealType(mealType: mealType)
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
                                    .foregroundStyle(.green)
                                
                                HStack {
                                    Image(systemName: "arrow.left")
                                    Text("Back")
                                }
                                .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .shadow(radius: 5)
                        }
                        .padding(.trailing, 3)
                        
                        // Next Button
                        NavigationLink(destination: CuisinesView(viewModel: viewModel)) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .foregroundStyle(.green)
                                
                                HStack {
                                    Text("Next")
                                    Image(systemName: "arrow.right")
                                }
                                .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .shadow(radius: 5)
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

// MARK: - Meal Type Card Component
struct MealTypeCard: View {
    let mealType: MealType
    let isSelected: Bool
    let action: () -> Void
    @State private var uiImage: UIImage?

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Image Container
                ZStack {
                    // Background image
                    if let uiImage = uiImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 110, height: 110)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        Rectangle()
                            .foregroundStyle(.gray.opacity(0.3))
                            .frame(width: 110, height: 110)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay {
                                ProgressView()
                            }
                    }
                    
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
                
                // Label
                Text(mealType.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? .green : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .onAppear(perform: loadImage)
    }

    private func loadImage() {
        DispatchQueue.global().async {
            if let loadedImage = UIImage(named: mealType.apiValue) {
                DispatchQueue.main.async {
                    self.uiImage = loadedImage
                }
            }
        }
    }
}

#Preview {
    MealTypesView(viewModel: RandomRecipeViewModel())
}
