//
//  ShelfSmartApp.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/4/25.
//  Refactored on 1/19/26 to use ModelContainerFactory.
//

import FirebaseCore
import SwiftData
import SwiftUI
import UserNotifications
import PostHog

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Initialize PostHog using ConfigurationManager
        initializePostHog()

        return true
    }

    // MARK: - PostHog Initialization
    private func initializePostHog() {
        guard let apiKey = ConfigurationManager.shared.postHogAPIKey,
              !apiKey.isEmpty,
              apiKey != "$(POSTHOG_API_KEY)" else {
            print("⚠️ PostHog API key not configured")
            return
        }
        
        let config = PostHogConfig(apiKey: apiKey, host: "https://us.i.posthog.com")
        
        #if DEBUG
        config.debug = true
        #endif
        
        PostHogSDK.shared.setup(config)
        print("✅ PostHog initialized successfully")
    }
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🔔 Notification received in foreground: \(notification.request.identifier)")
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
        requestNotificationAuthorization()
    }

    // Register app delegate for Firebase Setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @State private var notificationManager = NotificationManager()
    @State private var showSplash = true
    @State private var isDataReady = false
    @State private var entryViewViewModel: EntryViewViewModel? = nil
    
    // Use ModelContainerFactory for container creation
    private var modelContainer: ModelContainer = ModelContainerFactory.createWithFallback()

    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashScreenView()
                    .task {
                        // Create EntryViewViewModel here as Firebase is ready
                        if entryViewViewModel == nil { 
                            entryViewViewModel = EntryViewViewModel()
                        }
                        // Fetch data during splash
                        await entryViewViewModel?.refreshUserStatus()
                        isDataReady = true
                        
                        // Wait for the animation
                        try? await Task.sleep(for: .seconds(1.8))
                        showSplash = false
                    }
            } else if let viewModel = entryViewViewModel {
                EntryView(viewModel: viewModel)
                    .environment(notificationManager)
            }
        }
        .modelContainer(modelContainer)
    }

    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
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
