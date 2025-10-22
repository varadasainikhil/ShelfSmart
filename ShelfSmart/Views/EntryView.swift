//
//  EntryView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/21/25.
//

import SwiftUI

struct EntryView: View {
    @State var viewModel = EntryViewViewModel()
    @State var authManager = SignUpViewViewModel()
    var body: some View {
        VStack{
            if viewModel.isLoggedIn && !viewModel.currentUserId.isEmpty {
                if viewModel.isEmailVerified {
                    // User is authenticated and email is verified
                    if viewModel.hasCompletedOnboarding {
                        // User has completed onboarding - show main app
                        AuthenticatedView(authManager: authManager, userId: viewModel.currentUserId)
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
                    // User is authenticated but email is not verified
                    EmailVerificationView(
                        viewModel: EmailVerificationViewModel(
                            userEmail: viewModel.currentUserEmail,
                            userFullName: authManager.fullName
                        ),
                        onVerificationSuccess: {
                            await viewModel.refreshUserStatus()
                        }
                    )
                }
            } else {
                // User is not authenticated
                SignUpView(viewModel: authManager)
            }
        }
        .onDisappear {
            viewModel.stopHandler()
        }
        .onAppear {
            // Refresh user status when view appears
            Task {
                await viewModel.refreshUserStatus()
            }
        }
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
    EntryView()
}
