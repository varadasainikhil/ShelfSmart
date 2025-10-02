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

@Observable
class NotificationManager{
    // Function to check authorization status
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    func scheduleNotifications(for product : Product){
        // 1. Check authorization status first
        Task {
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

            // Verify notifications were actually scheduled
            await verifyPendingNotifications()
        }
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
}
