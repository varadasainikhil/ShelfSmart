//
//  ProfileViewViewModel.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/5/25.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftData

@Observable
class ProfileViewViewModel{
    
    var userName : String = ""
    
    func getUserName() async{
        guard let userId = Auth.auth().currentUser?.uid else{
            print("Could not get userId")
            return
        }
        
        let db = Firestore.firestore()
        do{
            let user = try await db.collection("users").document(userId).getDocument(as: User.self)
            userName = user.name
        }
        catch{
            print(error.localizedDescription)
        }
        
        
    }
    
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
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found")
            return
        }

        ProductHelpers.unlikeRecipe(recipe, userId: userId, modelContext: modelContext)
    }

    // Signing Out
    func signOut(){
        do{
            try Auth.auth().signOut()
            print("User signed out successfully.")
        }
        catch{
            print(error.localizedDescription)
        }
    }

    // MARK: - Account Deletion

    /// Deletes the user's account completely from all systems
    /// This includes: Firebase Auth, Firestore, SwiftData, and all notifications
    func deleteAccount(groups: [GroupedProducts], products: [Product], recipes: [SDRecipe], modelContext: ModelContext, notificationManager: NotificationManager) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "ProfileViewViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
        }

        let userId = user.uid
        let db = Firestore.firestore()

        print("🗑️ Starting account deletion for user: \(userId)")

        // Step 1: Delete Firebase Auth account FIRST
        // This ensures that if re-authentication is required, no data is deleted yet
        print("🗑️ Step 1: Deleting Firebase Auth account...")
        do {
            try await user.delete()
            print("✅ Firebase Auth account deleted successfully")
        } catch let error as NSError {
            // Check if re-authentication is required
            if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                print("⚠️ Re-authentication required for account deletion")
                throw NSError(domain: "ProfileViewViewModel", code: AuthErrorCode.requiresRecentLogin.rawValue, userInfo: [NSLocalizedDescriptionKey: "Recent login required. Please re-authenticate to delete your account."])
            } else {
                print("❌ Failed to delete Firebase Auth account: \(error.localizedDescription)")
                throw error
            }
        }

        // Step 2: Delete Firestore user document
        // Only reached if Firebase Auth deletion succeeded
        print("🗑️ Step 2: Deleting Firestore user document...")
        do {
            try await db.collection("users").document(userId).delete()
            print("✅ Firestore user document deleted successfully")
        } catch {
            print("⚠️ Failed to delete Firestore document: \(error.localizedDescription)")
            // Continue even if Firestore fails - account is already deleted
        }

        // Step 3: Delete all local SwiftData (products, groups, recipes)
        // Only reached if Firebase Auth deletion succeeded
        print("🗑️ Step 3: Deleting local SwiftData...")
        deleteAllData(groups: groups, products: products, recipes: recipes, modelContext: modelContext, notificationManager: notificationManager)

        print("✅ Account deletion completed successfully")
    }

    /// Re-authenticates the user with email/password
    /// Required by Firebase before account deletion for security
    func reauthenticateWithEmail(email: String, password: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "ProfileViewViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: password)

        do {
            try await user.reauthenticate(with: credential)
            print("✅ User re-authenticated successfully")
        } catch {
            print("❌ Re-authentication failed: \(error.localizedDescription)")
            throw error
        }
    }

    /// Re-authenticates the user with Apple Sign-In
    /// Required by Firebase before account deletion for security
    func reauthenticateWithApple(idToken: String, nonce: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "ProfileViewViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
        }

        let credential = OAuthProvider.appleCredential(withIDToken: idToken, rawNonce: nonce, fullName: nil)

        do {
            try await user.reauthenticate(with: credential)
            print("✅ User re-authenticated with Apple Sign-In successfully")
        } catch {
            print("❌ Re-authentication with Apple failed: \(error.localizedDescription)")
            throw error
        }
    }
}
