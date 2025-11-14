//
//  EntryView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/21/25.
//

import SwiftUI
import FirebaseFirestore

struct EntryView: View {
    @State var viewModel : EntryViewViewModel
    @State private var pendingUserName: String = "User"

    /// Fetch pending user name from Firebase authUsers collection
    private func fetchPendingUserName() async {
        let hashedEmail = AuthHelpers.hashEmail(viewModel.currentUserEmail)
        let db = Firestore.firestore()

        do {
            let authUserDoc = try await db.collection("authUsers").document(hashedEmail).getDocument()
            if let pendingName = authUserDoc.data()?["pendingUserName"] as? String, !pendingName.isEmpty {
                await MainActor.run {
                    pendingUserName = pendingName
                }
                print("📥 Retrieved pending user name from Firebase: \(pendingName)")
            } else {
                print("⚠️ No pending user name found in authUsers")
            }
        } catch {
            print("❌ Error fetching pending user name: \(error.localizedDescription)")
        }
    }

    var body: some View {
        VStack{
            if viewModel.isLoggedIn && !viewModel.currentUserId.isEmpty {
                if viewModel.isEmailVerified {
                    // User is authenticated and email is verified
                    if let hasCompleted = viewModel.hasCompletedOnboarding {
                        // We know the onboarding status
                        if hasCompleted {
                            // User has completed onboarding - show main app
                            AuthenticatedView(userId: viewModel.currentUserId)
                        } else {
                            // User needs to complete onboarding
                            AllergiesOnboardingView(
                                userId: viewModel.currentUserId,
                                onComplete: {
                                    await viewModel.refreshUserStatus()
                                }
                            )
                        }
                    } else {
                        // Onboarding status unknown - show loading
                        VStack(spacing: 16) {
                            ProgressView()
                            Text("Loading your profile...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    // User is authenticated but email is not verified
                    EmailVerificationView(
                        viewModel: EmailVerificationViewModel(
                            userEmail: viewModel.currentUserEmail,
                            userFullName: pendingUserName
                        ),
                        onVerificationSuccess: {
                            await viewModel.refreshUserStatus()
                        }
                    )
                    .task {
                        // Fetch pending user name when email verification view appears
                        await fetchPendingUserName()
                    }
                }
            } else {
                // User is not authenticated
                WelcomeAuthView()
            }
        }
        .onDisappear {
            viewModel.stopHandler()
        }
        // Note: No need for .onAppear refresh since data is fetched during splash screen
        // Only refresh when user authentication state changes
        .onChange(of: viewModel.isLoggedIn) { oldValue, newValue in
            // When user signs in (including via Apple Sign In), refresh their onboarding status
            if newValue == true && oldValue == false {
                print("🔄 User signed in - refreshing onboarding status")
                Task {
                    await viewModel.refreshUserStatus()
                }
            }
            // When user signs out, reset is handled in EntryViewViewModel
        }
    }
}

#Preview {
    let entryViewModel = EntryViewViewModel()
    EntryView(viewModel: entryViewModel)
}
