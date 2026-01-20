//
//  ConfigurationManager.swift
//  ShelfSmart
//
//  Created by Architecture Refactoring on 1/19/26.
//

import Foundation

/// Centralized configuration manager for API keys and app settings
/// Replaces duplicated plist reading code across ViewModels
final class ConfigurationManager {
    
    /// Shared singleton instance
    static let shared = ConfigurationManager()
    
    // MARK: - Cached Values
    private var cachedAPIKey: String?
    private var cachedPostHogKey: String?
    
    private init() {
        loadConfiguration()
    }
    
    // MARK: - Public Properties
    
    /// Spoonacular API key for product/recipe lookups
    var spoonacularAPIKey: String? {
        return cachedAPIKey
    }
    
    /// PostHog API key for analytics
    var postHogAPIKey: String? {
        return cachedPostHogKey
    }
    
    // MARK: - Validation
    
    /// Check if the Spoonacular API key is properly configured
    var isSpoonacularConfigured: Bool {
        guard let key = cachedAPIKey else { return false }
        return !key.isEmpty && key != "$(API_KEY)"
    }
    
    /// Check if PostHog is properly configured
    var isPostHogConfigured: Bool {
        guard let key = cachedPostHogKey else { return false }
        return !key.isEmpty && key != "$(POSTHOG_API_KEY)"
    }
    
    // MARK: - Private Methods
    
    private func loadConfiguration() {
        // Load Spoonacular API Key from Config.plist
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let apiKey = plist["API_KEY"] as? String {
            cachedAPIKey = apiKey
            print("✅ Spoonacular API key loaded")
        } else {
            print("⚠️ Spoonacular API key not found in Config.plist")
        }
        
        // Load PostHog API Key from Info.plist
        if let postHogKey = Bundle.main.object(forInfoDictionaryKey: "POSTHOG_API_KEY") as? String {
            cachedPostHogKey = postHogKey
            print("✅ PostHog API key loaded")
        } else {
            print("⚠️ PostHog API key not found in Info.plist")
        }
    }
    
    /// Force reload configuration (useful for testing)
    func reloadConfiguration() {
        cachedAPIKey = nil
        cachedPostHogKey = nil
        loadConfiguration()
    }
}
