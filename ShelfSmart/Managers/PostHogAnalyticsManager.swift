//
//  PostHogAnalyticsManager.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 11/20/25.
//

import Foundation
import PostHog

/// Event names are strongly typed to avoid mistakes in tracking.
enum AnalyticsEvent: String {
    // Barcode Scanning
    case scanSuccess = "scan_success"
    case scanFailed = "scan_failed"

    // Product Management
    case productInfoLoaded = "product_info_loaded"
    case productAdded = "product_added"

    // Recipe Interactions
    case recipeViewed = "recipe_viewed"

    // Random Recipe Generation
    case randomRecipeSaved = "random_recipe_saved"
    case customRecipeGenerated = "custom_recipe_generated"
    case completelyRandomRecipeGenerated = "completely_random_recipe_generated"
}

/// Screen names are strongly typed to avoid mistakes in tracking.
enum AnalyticsScreen: String {
    case home = "home"
    case addProduct = "add_product"
    case productDetail = "product_detail"
    case profile = "profile"
    case recipeDiscovery = "recipe_discovery"
    case recipeDetail = "recipe_detail"
    case editAllergies = "edit_allergies"
    case login = "login"
    case signup = "signup"
    case onboarding = "onboarding"
}

@Observable
class PostHogAnalyticsManager{
    static let shared = PostHogAnalyticsManager()

    private init() {}

    // MARK: - Track Events
    func track(_ event: AnalyticsEvent, properties: [String: Any] = [:]) {
        PostHogSDK.shared.capture(event.rawValue, properties: properties)
    }
    
    // MARK: - Track Screens
    func screen(_ screen: AnalyticsScreen, properties: [String: Any] = [:]) {
        PostHogSDK.shared.screen(screen.rawValue, properties: properties)
    }
    
    // MARK: - Identify User
    func identify(userId: String, properties: [String: Any] = [:]) {
        PostHogSDK.shared.identify(userId, userProperties: properties)
    }
    
    // MARK: - Reset on logout
    func reset() {
        PostHogSDK.shared.reset()
    }
    
    // MARK: - Feature Flags
    func isFeatureEnabled(_ flag: String) -> Bool {
        return PostHogSDK.shared.isFeatureEnabled(flag)
    }
    
    // MARK: - Capture Errors (Optional)
    func trackError(_ message: String, details: [String: Any] = [:]) {
        var props = details
        props["message"] = message
        track(.scanFailed, properties: props)
    }

}
