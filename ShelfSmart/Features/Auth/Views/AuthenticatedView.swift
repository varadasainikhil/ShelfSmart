//
//  ContentView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/21/25.
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct AuthenticatedView: View {
    let userId: String  // Explicit parameter to ensure correct user filtering

    // Environment
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.modelContext) var modelContext
    @Environment(NotificationManager.self) var notificationManager
    @State var selectedTab : Int = 0

    // Query all products for current user (for notification sync)
    @Query private var allProducts: [Product]

    // Track if initial sync has been performed
    @State private var hasPerformedInitialSync = false

    // Track if cleanup has been performed for this app session
    @State private var hasPerformedCleanup = false

    // Rate limiting for foreground sync (minimum 60 seconds between syncs)
    @State private var lastSyncTime: Date?

    init(userId: String) {
        self.userId = userId

        // Query all products for the current user using explicit userId
        let predicate = #Predicate<Product> { product in
            product.userId == userId
        }
        self._allProducts = Query(filter: predicate)
    }

    var body: some View {
        TabView(selection: $selectedTab){
            Tab(value: 0) {
                HomeView(userId: userId)
            } label: {
                VStack{
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            }
            
            Tab(value: 1) {
                ProductCompareView(userId: userId)
            } label: {
                VStack{
                    Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                    Text("Compare")
                }
                
            }
            
            Tab(value: 2) {
                DietsView(userId: userId)
            } label: {
                VStack{
                    Image(systemName: "shuffle")
                    Text("Random Recipes")
                }
                
            }
            
            Tab(value: 3) {
                ProfileView(userId: userId)
            } label: {
                VStack{
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
            }
        }
        .onAppear {
            // Perform cleanup of orphaned groups once per app launch
            if !hasPerformedCleanup {
                Task {
                    await ProductHelpers.cleanupOrphanedGroups(for: userId, modelContext: modelContext)
                    hasPerformedCleanup = true
                }
            }

            // Perform initial notification sync when view appears
            if !hasPerformedInitialSync {
                Task {
                    do {
                        try await notificationManager.syncNotificationsForAllProducts(products: allProducts)
                        hasPerformedInitialSync = true
                        lastSyncTime = Date()
                        print("✅ Initial notification sync completed successfully")
                    } catch {
                        print("❌ Initial notification sync failed: \(error.localizedDescription)")
                    }
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Sync notifications when app returns to foreground (rate-limited)
            // This handles the case where user switches between devices
            if newPhase == .active {
                Task {
                    // Rate limiting: only sync if 60+ seconds have passed since last sync
                    let now = Date()
                    if let lastSync = lastSyncTime, now.timeIntervalSince(lastSync) < 60 {
                        let timeRemaining = 60 - Int(now.timeIntervalSince(lastSync))
                        print("⏳ Skipping sync - rate limited (retry in \(timeRemaining)s)")
                        return
                    }

                    do {
                        try await notificationManager.syncNotificationsForAllProducts(products: allProducts)
                        lastSyncTime = now
                        print("✅ Foreground notification sync completed successfully")
                    } catch {
                        print("❌ Foreground notification sync failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

#Preview {
    AuthenticatedView(userId: "preview_user_id")
}
