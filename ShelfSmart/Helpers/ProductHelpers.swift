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
}
