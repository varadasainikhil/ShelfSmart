//
//  ProfileViewFixed.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/18/25.
//

import FirebaseAuth
import SwiftData
import SwiftUI

struct ProfileViewFixed: View {
    @Environment(\.modelContext) var modelContext
    @State var viewModel = ProfileViewViewModel()
    @State private var currentUserId: String = Auth.auth().currentUser?.uid ?? ""
    @State private var showDeleteConfirmation = false

    // Date of Birth fields
    @State private var selectedDay: Int = 1
    @State private var selectedMonth: Int = 1
    @State private var selectedYear: Int = 2000

    // Get all groups and filter in the view - this will be reactive to changes
    @Query(sort: \GroupedProducts.expirationDate) private var allGroups: [GroupedProducts]

    // Computed property that filters groups by current user
    var groups: [GroupedProducts] {
        return allGroups.filter { group in
            group.userId == currentUserId
        }
    }

    // Date ranges
    private let days = Array(1...31)
    private let months = Array(1...12)
    private var years: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(1900...currentYear).reversed()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
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

                    // Date of Birth Section
                    VStack(spacing: 32) {
                        // Date of Birth Title
                        Text("Date of birth")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        // Date Picker Fields
                        VStack(spacing: 20) {
                            HStack(spacing: 20) {
                                // Day Picker
                                VStack(spacing: 8) {
                                    Text("DD")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)

                                    Picker("Day", selection: $selectedDay) {
                                        ForEach(days, id: \.self) { day in
                                            Text("\(day)").tag(day)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 120)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                    )
                                    .clipped()
                                    .frame(maxWidth: .infinity)
                                }

                                // Month Picker
                                VStack(spacing: 8) {
                                    Text("MM")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)

                                    Picker("Month", selection: $selectedMonth) {
                                        ForEach(months, id: \.self) { month in
                                            Text("\(month)").tag(month)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 120)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                    )
                                    .clipped()
                                    .frame(maxWidth: .infinity)
                                }

                                // Year Picker
                                VStack(spacing: 8) {
                                    Text("YYYY")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)

                                    Picker("Year", selection: $selectedYear) {
                                        ForEach(years, id: \.self) { year in
                                            Text(String(year)).tag(year)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 120)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                    )
                                    .clipped()
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 60)

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
                    .padding(.bottom, 40)
                }
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
    ProfileViewFixed(viewModel: ProfileViewViewModel())
}