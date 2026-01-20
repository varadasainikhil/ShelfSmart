//
//  ProfileViewViewModel.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/5/25.
//  Refactored to use service layer on 1/19/26.
//

import Foundation
import SwiftData

@Observable
class ProfileViewViewModel {
    // MARK: - User ID (Single source of truth)
    let userId: String

    var userName: String = ""

    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    private let userService: UserServiceProtocol
    private let analyticsManager = PostHogAnalyticsManager.shared

    // MARK: - Initialization
    
    /// Initialize with default services (for production)
    convenience init(userId: String) {
        self.init(userId: userId, authService: AuthService.shared, userService: UserService.shared)
    }
    
    /// Initialize with injectable services (for testing)
    init(userId: String, authService: AuthServiceProtocol, userService: UserServiceProtocol) {
        self.userId = userId
        self.authService = authService
        self.userService = userService
    }

    // MARK: - User Data
    
    func getUserName() async {
        // Guard: Check if user is still authenticated
        guard authService.isLoggedIn else {
            print("ℹ️ User not authenticated - skipping user name fetch")
            return
        }

        do {
            let user = try await userService.fetchUser(userId: userId)
            await MainActor.run {
                self.userName = user.name
            }
        } catch {
            print("❌ Error fetching user name: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Data Deletion
    
    func deleteAllData(groups: [GroupedProducts], products: [Product], recipes: [SDRecipe], modelContext: ModelContext, notificationManager: NotificationManager) {
        var deletedCount = 0

        // 1. Cancel notifications for all products (in groups and standalone)
        for group in groups {
            if let groupProducts = group.products {
                for product in groupProducts {
                    notificationManager.deleteScheduledNotifications(for: product)
                    print("🗑️ Cancelled notifications for product: \(product.title)")
                }
            }
        }

        for product in products {
            notificationManager.deleteScheduledNotifications(for: product)
            print("🗑️ Cancelled notifications for standalone product: \(product.title)")
        }

        // 2. Delete all groups (cascade will delete contained products)
        for group in groups {
            modelContext.delete(group)
            deletedCount += 1
        }

        // 3. Delete all standalone products (used, liked, etc.)
        for product in products {
            // Only delete if not already part of a group (to avoid double deletion)
            if product.groupedProducts == nil {
                modelContext.delete(product)
                deletedCount += 1
            }
        }

        // 4. Delete all recipes (including liked ones)
        for recipe in recipes {
            modelContext.delete(recipe)
            deletedCount += 1
        }

        // 5. Save changes
        do {
            try modelContext.save()
            print("✅ Successfully deleted \(deletedCount) items and cancelled all notifications")
        } catch {
            print("❌ Problem saving the modelContext: \(error.localizedDescription)")
        }
    }

    // Method to delete specific recipes while preserving liked ones
    func deleteRecipe(_ recipe: SDRecipe, modelContext: ModelContext) {
        guard !recipe.isLiked else {
            print("Cannot delete liked recipe: \(recipe.title ?? "Unknown")")
            return
        }

        do {
            modelContext.delete(recipe)
            try modelContext.save()
            print("✅ Recipe deleted successfully")
        } catch {
            print("❌ Failed to delete recipe: \(error)")
        }
    }

    // Method to unlike and optionally delete a recipe
    func unlikeRecipe(_ recipe: SDRecipe, modelContext: ModelContext) {
        ProductHelpers.unlikeRecipe(recipe, userId: userId, modelContext: modelContext)
    }

    // MARK: - Sign Out
    
    func signOut() {
        do {
            try authService.signOut()
            print("User signed out successfully.")
            analyticsManager.reset()
        } catch {
            print("❌ Sign out error: \(error.localizedDescription)")
        }
    }

    // MARK: - Account Deletion

    /// Deletes the user's account completely from all systems
    /// This includes: Firebase Auth, Firestore, SwiftData, and all notifications
    func deleteAccount(groups: [GroupedProducts], products: [Product], recipes: [SDRecipe], modelContext: ModelContext, notificationManager: NotificationManager) async throws {
        guard authService.isLoggedIn else {
            throw NSError(domain: "ProfileViewViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
        }

        let userEmail = authService.currentUserEmail

        print("🗑️ Starting account deletion for user: \(userId)")

        // Step 1: Delete Firestore documents FIRST (while user is still authenticated)
        print("🗑️ Step 1: Deleting Firestore user document...")
        do {
            try await userService.deleteUser(userId: userId)
            print("✅ Firestore user document deleted successfully")
        } catch {
            print("⚠️ Failed to delete Firestore document: \(error.localizedDescription)")
            // Continue with deletion process even if Firestore fails
        }

        // Step 1.5: Delete authUsers document
        print("🗑️ Step 1.5: Deleting authUsers document...")
        if let userEmail = userEmail {
            do {
                try await userService.deleteAuthMethod(email: userEmail)
                print("✅ authUsers document deleted successfully")
            } catch {
                print("⚠️ Failed to delete authUsers document: \(error.localizedDescription)")
                // Continue with deletion process even if authUsers fails
            }
        } else {
            print("⚠️ No email found for user - skipping authUsers deletion")
        }

        // Step 2: Delete Firebase Auth account
        print("🗑️ Step 2: Deleting Firebase Auth account...")
        do {
            try await authService.deleteAccount()
            print("✅ Firebase Auth account deleted successfully")
        } catch let error as AuthServiceError {
            if case .requiresRecentLogin = error {
                print("⚠️ Re-authentication required for account deletion")
                throw NSError(domain: "ProfileViewViewModel", code: 17014, userInfo: [NSLocalizedDescriptionKey: "Recent login required. Please re-authenticate to delete your account."])
            } else {
                print("❌ Failed to delete Firebase Auth account: \(error.localizedDescription)")
                throw error
            }
        }

        // Step 3: Delete all local SwiftData (products, groups, recipes)
        print("🗑️ Step 3: Deleting local SwiftData...")
        deleteAllData(groups: groups, products: products, recipes: recipes, modelContext: modelContext, notificationManager: notificationManager)

        print("✅ Account deletion completed successfully")
    }

    /// Re-authenticates the user with email/password
    func reauthenticateWithEmail(email: String, password: String) async throws {
        try await authService.reauthenticate(email: email, password: password)
        print("✅ User re-authenticated successfully")
    }

    /// Re-authenticates the user with Apple Sign-In
    func reauthenticateWithApple(idToken: String, nonce: String) async throws {
        try await authService.reauthenticateWithApple(idToken: idToken, nonce: nonce)
        print("✅ User re-authenticated with Apple Sign-In successfully")
    }
}
