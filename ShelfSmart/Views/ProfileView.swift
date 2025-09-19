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
    @Environment(\.modelContext) var modelContext
    @State var viewModel = ProfileViewViewModel()
    @State private var currentUserId: String = Auth.auth().currentUser?.uid ?? ""
    @State private var showDeleteConfirmation = false
    
    
    // Get all groups and filter in the view - this will be reactive to changes
    @Query(sort: \GroupedProducts.expirationDate) private var allGroups: [GroupedProducts]
    
    // Computed property that filters groups by current user
    var groups: [GroupedProducts] {
        return allGroups.filter { group in
            group.userId == currentUserId
        }
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
                        Circle()
                            .fill(.green.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.green)
                            }
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
                
                // Content Section - Centered
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 32) {
                        // Welcome message or placeholder content
                        VStack(spacing: 16) {
                            Circle()
                                .fill(.green.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay {
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(.green)
                                }
                            
                            VStack(spacing: 8) {
                                Text("Keep your shelf organized")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                
                                Text("Track your products and never let food go to waste")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                        }
                    }
                    
                    Spacer()
                    Spacer()
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
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.red)
                        )
                        .shadow(color: .red.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .disabled(groups.isEmpty)
                    .opacity(groups.isEmpty ? 0.6 : 1.0)
                    
                    // Sign Out Button
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        Task {
                            viewModel.signOut()
                        }
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
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 34)
                .background(
                    ZStack {
                        // Gradient background for overlay
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
            .onAppear {
                currentUserId = Auth.auth().currentUser?.uid ?? ""
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
                    viewModel.deleteGroups(groups: groups, modelContext: modelContext)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all \(groups.count) items from your shelf. This action cannot be undone.")
            }
        }
    }
}


#Preview {
    ProfileView(viewModel: ProfileViewViewModel())
}
