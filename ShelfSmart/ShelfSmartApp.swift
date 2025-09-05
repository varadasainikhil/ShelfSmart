//
//  ShelfSmartApp.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/4/25.
//

import SwiftData
import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct ShelfSmartApp: App {
    // Register app delegate for Firebase Setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            EntryView()
        }
        .modelContainer(for: [GroupedProducts.self])
    }
}
