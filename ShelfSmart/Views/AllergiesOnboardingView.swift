//
//  AllergiesOnboardingView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 10/13/25.
//

import SwiftUI

struct AllergiesOnboardingView: View {
    let userId: String  // Passed from EntryView
    @State private var viewModel = AllergiesOnboardingViewModel()
    var onComplete: () async -> Void

    // Adaptive grid with better spacing
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Section
                VStack(alignment: .leading, spacing: 16) {
                    // Welcome Section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome to")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("ShelfSmart")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Question Section
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Do you have any")
                                .font(.title3)
                                .foregroundStyle(.primary)
                            Text("Food Intolerances?")
                                .font(.title2)
                                .fontWeight(.semibold)
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

                    // Subtitle
                    Text("Select any allergies or intolerances. We'll use this to personalize your recipes.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }

                // Intolerances Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(Intolerances.allCases, id: \.self) { intolerance in
                            OnboardingIntoleranceCard(
                                intolerance: intolerance,
                                isSelected: viewModel.isSelected(intolerance)
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.toggleIntolerance(intolerance)
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
                    // Error message if any
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    HStack(spacing: 12) {
                        // Continue Button
                        Button(action: {
                            Task {
                                do {
                                    try await viewModel.saveAllergiesAndCompleteOnboarding(userId: userId)
                                    // Call completion handler to refresh entry view
                                    await onComplete()
                                } catch {
                                    print("❌ Failed to complete onboarding: \(error)")
                                }
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.green)
                                    .conditionalGlassEffect()

                                if viewModel.isSaving {
                                    HStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .scaleEffect(0.8)
                                            .tint(.white)
                                        Text("Saving...")
                                            .foregroundStyle(Color(.systemBackground))
                                            .fontWeight(.semibold)
                                    }
                                } else {
                                    HStack {
                                        Text("Continue")
                                            .fontWeight(.bold)
                                        Image(systemName: "arrow.right")
                                    }
                                    .foregroundStyle(Color(.systemBackground))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        .disabled(viewModel.isSaving)
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
            .navigationBarBackButtonHidden(true) // Prevent going back
        }
    }
}

// MARK: - Onboarding Intolerance Card Component
struct OnboardingIntoleranceCard: View {
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
    AllergiesOnboardingView(userId: "preview_user_id", onComplete: {
        print("Onboarding completed!")
    })
}
