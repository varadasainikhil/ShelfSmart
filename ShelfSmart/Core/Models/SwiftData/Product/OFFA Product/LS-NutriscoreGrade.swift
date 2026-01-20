//
//  LS-NutriscoreGrade.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 11/7/25.
//

import Foundation

/// Nutriscore grade enum for SwiftData storage
/// Represents nutritional quality rating from A (best) to E (worst)
enum LSNutriscoreGrade: String, Codable, CaseIterable {
    case a = "a"
    case b = "b"
    case c = "c"
    case d = "d"
    case e = "e"

    /// Hex color code associated with the grade
    var color: String {
        switch self {
        case .a:
            return "#038141" // Dark green
        case .b:
            return "#85BB2F" // Light green
        case .c:
            return "#FECB02" // Yellow
        case .d:
            return "#EE8100" // Orange
        case .e:
            return "#E63E11" // Red
        }
    }

    /// Human-readable description of nutritional quality
    var description: String {
        switch self {
        case .a:
            return "Very good nutritional quality"
        case .b:
            return "Good nutritional quality"
        case .c:
            return "Average nutritional quality"
        case .d:
            return "Poor nutritional quality"
        case .e:
            return "Very poor nutritional quality"
        }
    }
}
