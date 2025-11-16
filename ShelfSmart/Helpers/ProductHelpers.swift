//
//  ProductHelpers.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 10/2/25.
//

import Foundation
import SwiftData

/// Shared helper functions for product and recipe operations
struct ProductHelpers {

    // MARK: - Product Operations

    /// Unlike a product and optionally delete it if it's standalone and not used
    /// - Parameters:
    ///   - product: The product to unlike
    ///   - modelContext: The SwiftData model context
    ///   - completion: Closure called with true if product was deleted, false otherwise
    static func unlikeProduct(_ product: Product, modelContext: ModelContext, completion: ((Bool) -> Void)? = nil) {
        // Check state BEFORE making any changes to avoid accessing invalid backing data
        // Delete only if: liked + standalone (not in group) + not used
        let willBeDeletedOnUnlike = product.isLiked && product.groupedProducts == nil && !product.isUsed

        if willBeDeletedOnUnlike {
            // Product is standalone, not used, and will be unliked - just delete it
            do {
                modelContext.delete(product)
                try modelContext.save()
                print("✅ Product unliked and deleted successfully")
                completion?(true)
            } catch {
                print("❌ Failed to delete product: \(error)")
                completion?(false)
            }
        } else {
            // Product is either in a group, used, or will remain standalone
            // Just toggle the like status
            do {
                product.LikeProduct()
                try modelContext.save()
                print("✅ Product like status toggled successfully")
                completion?(false)
            } catch {
                print("❌ Failed to toggle product like status: \(error)")
                completion?(false)
            }
        }
    }

    /// Deletes a product and handles all necessary cleanup
    /// - Parameters:
    ///   - product: The product to delete
    ///   - modelContext: The SwiftData model context
    ///   - notificationManager: The notification manager to cancel notifications
    /// - Throws: An error if the save operation fails
    static func deleteProduct(_ product: Product, modelContext: ModelContext, notificationManager: NotificationManager) throws {
        // IMPORTANT: Perform ALL deletion work in the correct order
        // All changes are made in-memory, then saved atomically at the end

        // 1. Cancel scheduled notifications for this product
        notificationManager.deleteScheduledNotifications(for: product)

        // 2. If the product is part of a group, handle group logic
        if let group = product.groupedProducts {
            // Remove product from the group's list of products
            if let index = group.products?.firstIndex(where: { $0.id == product.id }) {
                group.products?.remove(at: index)
            }

            // If the group is now empty, delete the group
            if group.products?.isEmpty ?? true {
                modelContext.delete(group)
            }

            // Break the relationship from the product side
            product.groupedProducts = nil
        }

        // 3. Handle recipes: Delete non-liked recipes only
        // Note: The @Relationship(deleteRule: .nullify) will automatically
        // set recipe.product = nil for liked recipes when product is deleted
        if let recipes = product.recipes {
            let recipesToDelete = recipes.filter { !$0.isLiked }

            // Clear the recipes array from product first to prevent accessing deleted objects
            product.recipes?.removeAll(where: { !$0.isLiked })

            // Delete non-liked recipes
            for recipe in recipesToDelete {
                modelContext.delete(recipe)
            }

            // Liked recipes are handled automatically by the .nullify delete rule
        }

        // 4. Delete the product (this triggers .nullify rule for remaining recipes)
        modelContext.delete(product)

        // 5. Save all changes atomically
        try modelContext.save()
    }

    /// Marks a product as used and handles all necessary cleanup
    /// - Parameters:
    ///   - product: The product to mark as used
    ///   - modelContext: The SwiftData model context
    ///   - notificationManager: The notification manager to cancel notifications
    static func markProductAsUsed(product: Product, modelContext: ModelContext, notificationManager: NotificationManager) {
        // 1. Mark as used
        product.markUsed()

        // 2. Cancel notifications
        notificationManager.deleteScheduledNotifications(for: product)

        // 3. Remove from GroupedProducts
        if let group = product.groupedProducts {
            // Remove product from group's array
            if let products = group.products,
               let index = products.firstIndex(where: { $0.id == product.id }) {
                group.products?.remove(at: index)
            }

            // Check if group is now empty
            if let products = group.products, products.isEmpty {
                modelContext.delete(group)
            }
        }

        // 4. Keep product as standalone regardless of liked status
        // All used products are now kept and moved to "Used Products" section
        product.groupedProducts = nil

        // 5. Save
        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save after marking product as used: \(error)")
        }
    }

    // MARK: - OFFA Product Operations

    /// Deletes an OFFA product and handles all necessary cleanup
    /// - Parameters:
    ///   - product: The OFFA product to delete
    ///   - modelContext: The SwiftData model context
    ///   - notificationManager: The notification manager to cancel notifications
    /// - Throws: An error if the save operation fails
    static func deleteOFFAProduct(_ product: LSProduct, modelContext: ModelContext, notificationManager: NotificationManager) throws {
        // IMPORTANT: Perform ALL deletion work in the correct order
        // All changes are made in-memory, then saved atomically at the end

        // 1. Cancel scheduled notifications for this product
        notificationManager.deleteScheduledNotifications(for: product)

        // 2. If the product is part of a group, handle group logic
        if let group = product.groupedProducts {
            // Remove product from the group's list of products
            if let index = group.offaProducts?.firstIndex(where: { $0.id == product.id }) {
                group.offaProducts?.remove(at: index)
            }

            // If the group is now empty, delete the group
            if group.offaProducts?.isEmpty ?? true {
                modelContext.delete(group)
            }

            // Break the relationship from the product side
            product.groupedProducts = nil
        }

        // 3. Handle recipes: Delete non-liked recipes only
        // Note: The @Relationship(deleteRule: .nullify) will automatically
        // set recipe.product = nil for liked recipes when product is deleted
        if let recipes = product.recipes {
            let recipesToDelete = recipes.filter { !$0.isLiked }

            // Clear the recipes array from product first to prevent accessing deleted objects
            product.recipes?.removeAll(where: { !$0.isLiked })

            // Delete non-liked recipes
            for recipe in recipesToDelete {
                modelContext.delete(recipe)
            }

            // Liked recipes are handled automatically by the .nullify delete rule
        }

        // 4. Delete the product (this triggers .nullify rule for remaining recipes)
        modelContext.delete(product)

        // 5. Save all changes atomically
        try modelContext.save()
    }

    /// Marks an OFFA product as used and handles all necessary cleanup
    /// - Parameters:
    ///   - product: The OFFA product to mark as used
    ///   - modelContext: The SwiftData model context
    ///   - notificationManager: The notification manager to cancel notifications
    static func markOFFAProductAsUsed(product: LSProduct, modelContext: ModelContext, notificationManager: NotificationManager) {
        // 1. Mark as used
        product.markUsed()

        // 2. Cancel notifications
        notificationManager.deleteScheduledNotifications(for: product)

        // 3. Remove from GroupedOFFAProducts
        if let group = product.groupedProducts {
            // Remove product from group's array
            if let products = group.offaProducts,
               let index = products.firstIndex(where: { $0.id == product.id }) {
                group.offaProducts?.remove(at: index)
            }

            // Check if group is now empty
            if let products = group.offaProducts, products.isEmpty {
                modelContext.delete(group)
            }
        }

        // 4. Keep product as standalone regardless of liked status
        // All used products are now kept and moved to "Used Products" section
        product.groupedProducts = nil

        // 5. Save
        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save after marking OFFA product as used: \(error)")
        }
    }

    // MARK: - Data Cleanup Operations

    /// Cleans up orphaned group records (groups without any products)
    /// This function should be called once per app launch after user login and onboarding
    /// - Parameters:
    ///   - userId: The current user ID
    ///   - modelContext: The SwiftData model context
    static func cleanupOrphanedGroups(for userId: String, modelContext: ModelContext) async {
        print("🧹 Starting cleanup of orphaned groups for user: \(userId)")

        do {
            // Fetch all GroupedProducts for this user
            let spoonacularPredicate = #Predicate<GroupedProducts> { group in
                group.userId == userId
            }
            let spoonacularDescriptor = FetchDescriptor<GroupedProducts>(predicate: spoonacularPredicate)
            let allSpoonacularGroups = try modelContext.fetch(spoonacularDescriptor)

            // Filter groups without products
            let orphanedSpoonacularGroups = allSpoonacularGroups.filter { group in
                group.products?.isEmpty ?? true
            }

            // Delete orphaned Spoonacular groups
            var spoonacularDeletedCount = 0
            for group in orphanedSpoonacularGroups {
                modelContext.delete(group)
                spoonacularDeletedCount += 1
            }

            // Fetch all GroupedOFFAProducts for this user
            let offaPredicate = #Predicate<GroupedOFFAProducts> { group in
                group.userId == userId
            }
            let offaDescriptor = FetchDescriptor<GroupedOFFAProducts>(predicate: offaPredicate)
            let allOFFAGroups = try modelContext.fetch(offaDescriptor)

            // Filter groups without products
            let orphanedOFFAGroups = allOFFAGroups.filter { group in
                group.offaProducts?.isEmpty ?? true
            }

            // Delete orphaned OFFA groups
            var offaDeletedCount = 0
            for group in orphanedOFFAGroups {
                modelContext.delete(group)
                offaDeletedCount += 1
            }

            // Save all changes
            if spoonacularDeletedCount > 0 || offaDeletedCount > 0 {
                try modelContext.save()
                print("✅ Cleanup completed: Deleted \(spoonacularDeletedCount) Spoonacular group(s) and \(offaDeletedCount) OFFA group(s)")
            } else {
                print("✅ Cleanup completed: No orphaned groups found")
            }

        } catch {
            print("❌ Failed to cleanup orphaned groups: \(error.localizedDescription)")
        }
    }

    // MARK: - Recipe Operations

    /// Unlike a recipe and delete it if it's standalone (not associated with a product)
    /// - Parameters:
    ///   - recipe: The recipe to unlike
    ///   - userId: The current user ID
    ///   - modelContext: The SwiftData model context
    ///   - completion: Closure called with true if recipe was deleted, false otherwise
    static func unlikeRecipe(_ recipe: SDRecipe, userId: String, modelContext: ModelContext, completion: ((Bool) -> Void)? = nil) {
        // Check state BEFORE making any changes to avoid accessing invalid backing data
        let willBeDeletedOnUnlike = recipe.isLiked && recipe.product == nil

        if willBeDeletedOnUnlike {
            // Recipe is standalone and will be deleted - don't bother toggling, just delete
            do {
                modelContext.delete(recipe)
                try modelContext.save()
                print("✅ Recipe unliked and deleted successfully")
                completion?(true)
            } catch {
                print("❌ Failed to delete recipe: \(error)")
                completion?(false)
            }
        } else {
            // Recipe is either attached to a product or will remain standalone
            // Just toggle the like status
            do {
                recipe.likeRecipe(userId: userId)
                try modelContext.save()
                print("✅ Recipe like status toggled successfully")
                completion?(false)
            } catch {
                print("❌ Failed to toggle recipe like status: \(error)")
                completion?(false)
            }
        }
    }

    /// Unlike an OFFA recipe and delete it if it's standalone (not associated with a product)
    /// - Parameters:
    ///   - recipe: The OFFA recipe to unlike
    ///   - userId: The current user ID
    ///   - modelContext: The SwiftData model context
    ///   - completion: Closure called with true if recipe was deleted, false otherwise
    static func unlikeOFFARecipe(_ recipe: SDOFFARecipe, userId: String, modelContext: ModelContext, completion: ((Bool) -> Void)? = nil) {
        // Check state BEFORE making any changes to avoid accessing invalid backing data
        let willBeDeletedOnUnlike = recipe.isLiked && recipe.product == nil

        if willBeDeletedOnUnlike {
            // Recipe is standalone and will be deleted - don't bother toggling, just delete
            do {
                modelContext.delete(recipe)
                try modelContext.save()
                print("✅ OFFA Recipe unliked and deleted successfully")
                completion?(true)
            } catch {
                print("❌ Failed to delete OFFA recipe: \(error)")
                completion?(false)
            }
        } else {
            // Recipe is either attached to a product or will remain standalone
            // Just toggle the like status
            do {
                recipe.likeRecipe(userId: userId)
                try modelContext.save()
                print("✅ OFFA Recipe like status toggled successfully")
                completion?(false)
            } catch {
                print("❌ Failed to toggle OFFA recipe like status: \(error)")
                completion?(false)
            }
        }
    }
}
