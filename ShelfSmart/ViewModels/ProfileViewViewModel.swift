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
}
