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
    
    func deleteGroups(groups : [GroupedProducts], modelContext : ModelContext){
        for group in groups{
            // With .nullify delete rule, liked recipes will automatically be preserved
            // when products are deleted (recipe.product will be set to nil automatically)
            modelContext.delete(group)
        }
        do{
            try modelContext.save()
        }
        catch{
            print("Problem saving the modelContext")
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

        do {
            recipe.likeRecipe(userId: userId) // This will toggle to unlike

            // If the recipe is not associated with a product, delete it
            if recipe.product == nil {
                modelContext.delete(recipe)
            }

            try modelContext.save()
            print("✅ Recipe unliked successfully")
        } catch {
            print("❌ Failed to unlike recipe: \(error)")
        }
    }
    
    // Method to clean up orphaned non-liked recipes (optional maintenance)
    func cleanupOrphanedRecipes(modelContext: ModelContext) {
        // This method can be called periodically to clean up recipes that are:
        // - Not liked by any user (isLiked = false)
        // - Not associated with any product (product = nil)

        // Note: This is optional and can be called during app startup or periodically
        // For now, we'll keep orphaned recipes to avoid any data loss
        print("Cleanup method available for future use if needed")
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
