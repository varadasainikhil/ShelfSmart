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
    
    func deleteGroups(groups : [GroupedProducts], modelContext : ModelContext, notificationManager: NotificationManager){
        for group in groups{
            // Cancel notifications for all products in this group before deletion
            if let products = group.products {
                for product in products {
                    notificationManager.deleteScheduledNotifications(for: product)
                    print("🗑️ Cancelled notifications for product: \(product.title)")
                }
            }

            // With .nullify delete rule, liked recipes will automatically be preserved
            // when products are deleted (recipe.product will be set to nil automatically)
            modelContext.delete(group)
        }
        do{
            try modelContext.save()
            print("✅ Groups and their notifications deleted successfully")
        }
        catch{
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
