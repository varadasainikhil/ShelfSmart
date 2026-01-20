//
//  EntryViewViewModel.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/21/25.
//  Refactored to use service layer on 1/19/26.
//

import Foundation
import FirebaseAuth

@Observable
class EntryViewViewModel {
    var isLoggedIn: Bool = false
    var isEmailVerified: Bool = false
    var hasCompletedOnboarding: Bool? = nil  // nil = unknown, false = not completed, true = completed
    var currentUserId: String = ""
    var currentUserEmail: String = ""

    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    private let userService: UserServiceProtocol
    private let analyticsManager = PostHogAnalyticsManager.shared
    
    private var handler: AuthStateDidChangeListenerHandle? = nil

    // MARK: - Initialization
    
    /// Initialize with default services (for production)
    convenience init() {
        self.init(authService: AuthService.shared, userService: UserService.shared)
    }
    
    /// Initialize with injectable services (for testing)
    init(authService: AuthServiceProtocol, userService: UserServiceProtocol) {
        self.authService = authService
        self.userService = userService
        
        self.handler = authService.addAuthStateListener { [weak self] userId, email, isLoggedIn, isEmailVerified in
            guard let self = self else { return }
            
            self.currentUserId = userId ?? ""
            self.currentUserEmail = email ?? ""
            self.isLoggedIn = isLoggedIn
            self.isEmailVerified = isEmailVerified

            if let userId = userId {
                // Identify user in PostHog for already-signed-in users
                self.analyticsManager.identify(
                    userId: userId,
                    properties: [
                        "email": email ?? ""
                    ]
                )
            } else {
                // User signed out - reset all state
                self.hasCompletedOnboarding = nil
                print("🚪 User signed out - state reset")
            }
        }
    }
    
    // MARK: - Public Methods
    
    func stopHandler() {
        if let handler = handler {
            authService.removeAuthStateListener(handler)
            self.handler = nil
        }
    }

    func refreshUserStatus() async {
        guard authService.isLoggedIn, let userId = authService.currentUserId else {
            // User not authenticated - silently return
            return
        }

        do {
            // Reload user to get latest verification status
            try await authService.reloadCurrentUser()
            
            // Fetch onboarding status from UserService
            let hasCompleted = try await userService.hasCompletedOnboarding(userId: userId)

            await MainActor.run {
                self.isEmailVerified = self.authService.isEmailVerified

                // Get hasCompletedOnboarding from service
                if let hasCompleted = hasCompleted {
                    self.hasCompletedOnboarding = hasCompleted
                    print("✅ Onboarding status fetched: \(hasCompleted)")
                } else {
                    self.hasCompletedOnboarding = false
                    print("⚠️ Onboarding status not found - treating as incomplete (existing user migration)")
                }
            }
        } catch let error as UserServiceError {
            if case .permissionDenied = error {
                // Expected during deletion/sign-out
                print("ℹ️ Permission denied during user status refresh (expected during sign-out)")
            } else {
                print("❌ Error refreshing user status: \(error.localizedDescription)")
            }

            // On error, keep status as unknown (don't assume not completed)
            await MainActor.run {
                self.hasCompletedOnboarding = nil
            }
        } catch {
            print("❌ Error refreshing user status: \(error.localizedDescription)")
            await MainActor.run {
                self.hasCompletedOnboarding = nil
            }
        }
    }
    
    deinit {
        // Ensure cleanup happens even if stopHandler() isn't called
        stopHandler()
    }
}
