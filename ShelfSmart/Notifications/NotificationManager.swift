//
//  NotificationManager.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/30/25.
//

import Foundation
import SwiftData
import SwiftUI
import UserNotifications

// MARK: - Notification Errors
enum NotificationError: Error, LocalizedError {
    case unauthorized(status: UNAuthorizationStatus)
    case schedulingFailed(reason: String)

    var errorDescription: String? {
        switch self {
        case .unauthorized(let status):
            return "Notification permission not granted (status: \(status.rawValue))"
        case .schedulingFailed(let reason):
            return "Failed to schedule notification: \(reason)"
        }
    }
}

@Observable
class NotificationManager{
    // Function to check authorization status
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    func scheduleNotifications(for product: Product) async {
        // 1. Check authorization status first
        let authStatus = await checkAuthorizationStatus()
        guard authStatus == .authorized else {
            print("⚠️ Cannot schedule notifications - Permission not granted (status: \(authStatus.rawValue))")
            return
        }

        // 2. Delete any existing notifications for this product first to prevent duplication of notifications
        deleteScheduledNotifications(for: product)

        // 3. We have to check how many days left for expiry
        // Based on that we have to set the warning and the actual expiry notification
        // If the expiry is less than one week, then we directly send the expiry notification no warning.

        await scheduleNotificationsInternal(for: product)
    }

    private func scheduleNotificationsInternal(for product: Product) async {
        let daysLeft = product.daysTillExpiry().count
        let productTitle = product.title
        let productWarningNotificationId = product.warningNotificationId
        let productExpirationNotificationId = product.expirationNotificationId

        // Create date formatter once for reuse
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        print("🔍 DEBUG: Product '\(productTitle)' expires in \(daysLeft) days")
        print("🔍 DEBUG: Expiration date: \(product.expirationDate)")

        // Notification 1 : Warning notification
        if daysLeft >= 7 {
            // Schedule warning notification only if it's in the future
            if let warningDate = product.warningDate {
                var warningComponents = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: warningDate)

                // Setting the time to 3:06 PM
                warningComponents.hour = 15
                warningComponents.minute = 06
                warningComponents.timeZone = TimeZone.current

                // Check if warning date is in the future
                if let scheduledWarningDate = Calendar.current.date(from: warningComponents), scheduledWarningDate > Date.now {
                    // Scheduling the warning notification
                    let warningContent = UNMutableNotificationContent()
                    warningContent.title = "Expiring In a Week"
                    warningContent.body = "\(productTitle) is expiring in a week"
                    warningContent.sound = .default

                    let warningTrigger = UNCalendarNotificationTrigger(dateMatching: warningComponents, repeats: false)
                    let warningRequest = UNNotificationRequest(identifier: productWarningNotificationId, content: warningContent, trigger: warningTrigger)

                    do {
                        try await UNUserNotificationCenter.current().add(warningRequest)
                        print("✅ Warning notification scheduled for \(productTitle) at \(dateFormatter.string(from: scheduledWarningDate))")
                    } catch {
                        print("❌ Failed to schedule warning notification for \(productTitle): \(error.localizedDescription)")
                    }
                } else if let scheduledWarningDate = Calendar.current.date(from: warningComponents) {
                    print("⚠️ SKIPPED: Warning notification time (\(dateFormatter.string(from: scheduledWarningDate))) is in the past. Not scheduling.")
                }
            } else {
                print("⚠️ Could not calculate the warningDate")
            }

            // Notification 2 : Expiration Notification
            var expirationComponents = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: product.expirationDate)

            // Setting the time to 3:06 PM
            expirationComponents.hour = 15
            expirationComponents.minute = 06
            expirationComponents.timeZone = TimeZone.current

            // Check if expiration date is in the future
            if let scheduledExpirationDate = Calendar.current.date(from: expirationComponents), scheduledExpirationDate > Date.now {
                let expirationContent = UNMutableNotificationContent()
                expirationContent.title = "Expired"
                expirationContent.body = "\(productTitle) is expired"
                expirationContent.sound = .default

                let expirationTrigger = UNCalendarNotificationTrigger(dateMatching: expirationComponents, repeats: false)
                let expirationRequest = UNNotificationRequest(identifier: productExpirationNotificationId, content: expirationContent, trigger: expirationTrigger)

                do {
                    try await UNUserNotificationCenter.current().add(expirationRequest)
                    print("✅ Expiration notification scheduled for \(productTitle) at \(dateFormatter.string(from: scheduledExpirationDate))")
                } catch {
                    print("❌ Failed to schedule expiration notification for \(productTitle): \(error.localizedDescription)")
                }
            } else if let scheduledExpirationDate = Calendar.current.date(from: expirationComponents) {
                print("⚠️ SKIPPED: Expiration notification time (\(dateFormatter.string(from: scheduledExpirationDate))) is in the past. Not scheduling.")
            }
        }
        else {
            // For products expiring in 1-6 days or already expired
            // Expiration Notification
            var expirationComponents = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: product.expirationDate)

            print("🔍 DEBUG: Original components - Year: \(expirationComponents.year ?? 0), Month: \(expirationComponents.month ?? 0), Day: \(expirationComponents.day ?? 0)")

            // Setting the time to 3:06 PM
            expirationComponents.hour = 15
            expirationComponents.minute = 06
            expirationComponents.timeZone = TimeZone.current

            print("🔍 DEBUG: Modified components - Year: \(expirationComponents.year ?? 0), Month: \(expirationComponents.month ?? 0), Day: \(expirationComponents.day ?? 0), Hour: \(expirationComponents.hour ?? 0), Minute: \(expirationComponents.minute ?? 0)")

            // Check if expiration date is in the future
            if let scheduledExpirationDate = Calendar.current.date(from: expirationComponents), scheduledExpirationDate > Date.now {
                let expirationContent = UNMutableNotificationContent()
                expirationContent.title = "Expired"
                expirationContent.body = "\(productTitle) is expired"
                expirationContent.sound = .default

                let expirationTrigger = UNCalendarNotificationTrigger(dateMatching: expirationComponents, repeats: false)
                let expirationRequest = UNNotificationRequest(identifier: productExpirationNotificationId, content: expirationContent, trigger: expirationTrigger)

                do {
                    try await UNUserNotificationCenter.current().add(expirationRequest)
                    print("🔍 DEBUG: Trigger date will be: \(scheduledExpirationDate)")
                    print("✅ Expiration notification scheduled for \(productTitle) at \(dateFormatter.string(from: scheduledExpirationDate))")
                } catch {
                    print("❌ Failed to schedule expiration notification for \(productTitle): \(error.localizedDescription)")
                }
            } else if let scheduledExpirationDate = Calendar.current.date(from: expirationComponents) {
                print("🔍 DEBUG: Trigger date would be: \(scheduledExpirationDate)")
                print("⚠️ SKIPPED: Expiration notification time (\(dateFormatter.string(from: scheduledExpirationDate))) is in the past. Not scheduling.")
            }
        }
    }
    
    // Delete the scheduled notifications
    func deleteScheduledNotifications(for product : Product){
        let ids = [product.warningNotificationId, product.expirationNotificationId]

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // Verify pending notifications (for debugging)
    func verifyPendingNotifications() async {
        let pendingRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        print("🔔 Total pending notifications: \(pendingRequests.count)")
        for request in pendingRequests {
            if let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let nextTriggerDate = trigger.nextTriggerDate() {
                print("  - \(request.identifier): \(nextTriggerDate)")
            }
        }
    }

    // MARK: - Cross-Device Notification Sync

    /// Syncs notifications for all products across devices
    /// This ensures products synced via CloudKit also have their notifications scheduled
    /// - Parameter products: All products to check and sync notifications for
    /// - Throws: Error if notification sync fails
    func syncNotificationsForAllProducts(products: [Product]) async throws {
        // 1. Check authorization status first
        let authStatus = await checkAuthorizationStatus()
        guard authStatus == .authorized else {
            print("⚠️ Cannot sync notifications - Permission not granted (status: \(authStatus.rawValue))")
            throw NotificationError.unauthorized(status: authStatus)
        }

        // 2. Get all pending notifications from the system
        let pendingRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let pendingIds = Set(pendingRequests.map { $0.identifier })

        print("🔄 Starting notification sync...")
        print("📱 Found \(pendingRequests.count) pending notifications in system")
        print("📦 Found \(products.count) products to check")

        var scheduledCount = 0
        var skippedCount = 0

        // 3. Check each product and schedule missing notifications
        for product in products {
            // Skip used or expired products - they shouldn't have notifications
            if product.isUsed || product.isExpired {
                skippedCount += 1
                continue
            }

            // Check if notifications are already scheduled for this product
            let hasWarning = pendingIds.contains(product.warningNotificationId)
            let hasExpiration = pendingIds.contains(product.expirationNotificationId)

            // Determine if we need to schedule based on days until expiry
            let daysLeft = product.daysTillExpiry().count

            // For products expiring in 7+ days, both notifications should exist
            if daysLeft >= 7 {
                if hasWarning && hasExpiration {
                    // Both notifications already scheduled, skip
                    continue
                } else if !hasWarning && !hasExpiration {
                    // Neither exists - schedule both
                    print("📅 Scheduling notifications for: \(product.title) (both missing)")
                    await scheduleNotifications(for: product)
                    scheduledCount += 1
                } else {
                    // Partial state - reschedule both to ensure consistency
                    print("⚠️ Partial notification state detected for: \(product.title) - rescheduling")
                    await scheduleNotifications(for: product)
                    scheduledCount += 1
                }
            } else if daysLeft >= 0 {
                // For products expiring in 0-6 days, only expiration notification should exist
                if hasExpiration {
                    // Expiration notification already scheduled, skip
                    continue
                } else {
                    // Missing expiration notification - schedule it
                    print("📅 Scheduling expiration notification for: \(product.title)")
                    await scheduleNotifications(for: product)
                    scheduledCount += 1
                }
            } else {
                // Product expiration date is in the past, skip
                skippedCount += 1
                continue
            }
        }

        print("✅ Notification sync complete: \(scheduledCount) products scheduled, \(skippedCount) skipped")

        // 4. Clean up orphaned notifications (notifications for products that no longer exist)
        await cleanupOrphanedNotifications(products: products, pendingRequests: pendingRequests)
    }

    /// Removes notifications for products that have been deleted
    /// This prevents orphaned notifications from appearing when products are deleted on another device
    /// - Parameters:
    ///   - products: Current list of all products
    ///   - pendingRequests: Current pending notification requests
    private func cleanupOrphanedNotifications(products: [Product], pendingRequests: [UNNotificationRequest]) async {
        // Create a set of all valid product IDs for quick lookup
        let validProductIds = Set(products.map { $0.id })

        // Find orphaned notification IDs
        var orphanedIds: [String] = []

        for request in pendingRequests {
            let identifier = request.identifier

            // Extract product ID from notification ID
            // Notification ID format: "{productId}_warning_notification_id" or "{productId}_expiration_notification_id"
            var productId = identifier

            if productId.hasSuffix("_warning_notification_id") {
                productId = String(productId.dropLast("_warning_notification_id".count))
            } else if productId.hasSuffix("_expiration_notification_id") {
                productId = String(productId.dropLast("_expiration_notification_id".count))
            } else {
                // Not a product notification (might be from another feature), skip
                continue
            }

            // If the product no longer exists, mark notification for deletion
            if !validProductIds.contains(productId) {
                orphanedIds.append(identifier)
            }
        }

        // Remove orphaned notifications from the system
        if !orphanedIds.isEmpty {
            print("🧹 Cleaning up \(orphanedIds.count) orphaned notification(s)")
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: orphanedIds)
        } else {
            print("✨ No orphaned notifications found")
        }
    }
}
