//
//  ShelfSmartApp.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/4/25.
//

import SwiftData
import SwiftUI
import FirebaseCore
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }

  // Handle notifications when app is in foreground
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    print("🔔 Notification received in foreground: \(notification.request.identifier)")
    // Show notification as banner with sound even when app is open
    completionHandler([.banner, .sound, .badge])
  }

  // Handle notification tap
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    print("🔔 Notification tapped: \(response.notification.request.identifier)")
    completionHandler()
  }
}

@main
struct ShelfSmartApp: App {

    init() {
        // Request notification permission on app launch
        requestNotificationAuthorization()
    }

    // Register app delegate for Firebase Setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @State private var notificationManager = NotificationManager()
    @State private var modelContainerError: Error?

    // Configure ModelContainer with explicit CloudKit settings
    private var modelContainer: ModelContainer = {
        let schema = Schema([
            GroupedProducts.self,
            SDRecipe.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Fallback: Create in-memory container to prevent app crash
            print("❌ Failed to create persistent ModelContainer: \(error)")
            print("⚠️ Falling back to in-memory storage - data will not persist!")

            do {
                let inMemoryConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                return try ModelContainer(for: schema, configurations: [inMemoryConfiguration])
            } catch let inMemoryError {
                // Ultimate fallback: Create a minimal schema that should always work
                print("❌ CRITICAL: Failed to create in-memory ModelContainer: \(inMemoryError)")
                print("⚠️ Creating emergency fallback container")

                // Try one last time with absolutely minimal configuration
                let emergencySchema = Schema([GroupedProducts.self, SDRecipe.self])
                do {
                    return try ModelContainer(
                        for: emergencySchema,
                        configurations: [ModelConfiguration(schema: emergencySchema, isStoredInMemoryOnly: true)]
                    )
                } catch {
                    // If even this fails, something is seriously wrong with the system
                    // Log the error and return a container anyway to prevent crash
                    print("❌ FATAL: All ModelContainer creation attempts failed: \(error)")
                    fatalError("Critical system error: Unable to initialize data storage. Please reinstall the app.")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            EntryView()
                .environment(notificationManager)
        }
        .modelContainer(modelContainer)
    }

    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
                // Set the notification delegate to handle foreground notifications
                DispatchQueue.main.async {
                    UNUserNotificationCenter.current().delegate = self.delegate
                }
            } else if let error = error {
                print("❌ Error requesting notification permission: \(error.localizedDescription)")
            } else {
                print("⚠️ Notification permission denied by user")
            }
        }
    }
}
