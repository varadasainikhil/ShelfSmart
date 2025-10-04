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
            } catch {
                // This should never happen, but provide ultimate fallback
                preconditionFailure("Failed to create even in-memory ModelContainer: \(error)")
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
