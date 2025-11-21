//
//  ShelfSmartApp.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/4/25.
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
      
      // Initialize PostHog
      initializePostHog()


    return true
  }

    // MARK: - PostHog Initialization
    private func initializePostHog() {
        // Get API key from Info.plist
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "POSTHOG_API_KEY") as? String,
              !apiKey.isEmpty,
              apiKey != "$(POSTHOG_API_KEY)" else {
            print("⚠️ PostHog API key not configured in Info.plist")
            return
        }
        
        let config = PostHogConfig(apiKey: apiKey, host: "https://us.i.posthog.com")
        
        // Optional: Enable debug mode for testing
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
    @State private var showSplash = true
    @State private var isDataReady = false
    @State private var entryViewViewModel : EntryViewViewModel? = nil
    
    // Configure ModelContainer with explicit CloudKit settings
    private var modelContainer: ModelContainer = {
        let schema = Schema([
            // Spoonacular Products
            GroupedProducts.self,
            Product.self,
            Credit.self,
            SDRecipe.self,
            SDAnalyzedInstructions.self,
            SDSteps.self,
            SDStepIngredient.self,
            SDEquipment.self,
            SDIngredients.self,
            SDMeasures.self,
            SDMeasure.self,

            // OFFA Products
            GroupedOFFAProducts.self,
            LSProduct.self,
            LSIngredient.self,
            LSNutriments.self,
            LSNutriscoreData.self,
            LSNutriscoreComponents.self,
            LSNutrientComponent.self,
            SDOFFARecipe.self,
            SDOFFAAnalyzedInstructions.self,
            SDOFFASteps.self,
            SDOFFAStepIngredient.self,
            SDOFFAEquipment.self,
            SDOFFAIngredients.self,
            SDOFFAMeasures.self,
            SDOFFAMeasure.self
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
            print("❌ Error details: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("❌ Error domain: \(nsError.domain)")
                print("❌ Error code: \(nsError.code)")
                print("❌ Error userInfo: \(nsError.userInfo)")
                if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                    print("❌ Underlying error: \(underlyingError.localizedDescription)")
                    print("❌ Underlying error domain: \(underlyingError.domain)")
                    print("❌ Underlying error code: \(underlyingError.code)")
                }
            }
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
                let emergencySchema = Schema([
                    // Spoonacular Products (minimal)
                    GroupedProducts.self,
                    Product.self,
                    Credit.self,
                    SDRecipe.self,

                    // OFFA Products (minimal)
                    GroupedOFFAProducts.self,
                    LSProduct.self,
                    SDOFFARecipe.self
                ])
                do {
                    return try ModelContainer(
                        for: emergencySchema,
                        configurations: [ModelConfiguration(schema: emergencySchema, isStoredInMemoryOnly: true)]
                    )
                } catch {
                    // If even this fails, something is seriously wrong with the system
                    // Log the error and return a container anyway to prevent crash
                    print("❌ FATAL: All ModelContainer creation attempts failed: \(error)")
                    print("❌ FATAL Error details: \(error.localizedDescription)")
                    if let nsError = error as NSError? {
                        print("❌ FATAL Error domain: \(nsError.domain)")
                        print("❌ FATAL Error code: \(nsError.code)")
                        print("❌ FATAL Error userInfo: \(nsError.userInfo)")
                        if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                            print("❌ FATAL Underlying error: \(underlyingError.localizedDescription)")
                            print("❌ FATAL Underlying error domain: \(underlyingError.domain)")
                            print("❌ FATAL Underlying error code: \(underlyingError.code)")
                            print("❌ FATAL Underlying error userInfo: \(underlyingError.userInfo)")
                        }
                    }
                    fatalError("Critical system error: Unable to initialize data storage. Please reinstall the app.")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashScreenView()
                    .task {
                        // Create EntryViewViewModel here as firebase is ready
                        if entryViewViewModel == nil{ 
                            entryViewViewModel = EntryViewViewModel()
                        }
                        // Fetch Data during splash
                        await entryViewViewModel?.refreshUserStatus()
                        isDataReady = true
                        
                        // Wait for the animation
                        try? await Task.sleep(for: .seconds(1.8))
                        showSplash = false
                    }
            } else if  let viewModel = entryViewViewModel{
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
