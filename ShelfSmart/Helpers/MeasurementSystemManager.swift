//
//  MeasurementSystemManager.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 11/17/25.
//

import Foundation

/// Manages measurement system preferences based on user's locale
class MeasurementSystemManager {

    /// Shared singleton instance
    static let shared = MeasurementSystemManager()

    private init() {}

    /// Determines the appropriate measurement system based on user's locale
    /// - Returns: "metric" for most countries, "us" for United States, Liberia, and Myanmar
    func getMeasurementSystem() -> String {
        let locale = Locale.current

        // Get the region code (e.g., "US", "GB", "FR")
        guard let regionCode = locale.region?.identifier ?? locale.language.region?.identifier else {
            // Default to metric if we can't determine region
            return "metric"
        }

        // Only US, Liberia (LR), and Myanmar (MM) primarily use imperial/US measurements
        let usSystemCountries = ["US", "LR", "MM"]

        return usSystemCountries.contains(regionCode) ? "us" : "metric"
    }

    /// Returns whether the current locale uses metric system
    var usesMetricSystem: Bool {
        return getMeasurementSystem() == "metric"
    }

    /// Returns whether the current locale uses US system
    var usesUSSystem: Bool {
        return getMeasurementSystem() == "us"
    }

    /// Returns a human-readable description of the current measurement system
    var systemDescription: String {
        return usesMetricSystem ? "Metric (g, ml, cm)" : "US (cups, oz, inches)"
    }
}
