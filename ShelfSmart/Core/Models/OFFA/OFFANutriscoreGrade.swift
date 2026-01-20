//
//  OFFANutriscoreGrade.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 11/6/25.
//

import Foundation

// MARK: - Nutriscore Grade Enum
enum OFFANutriscoreGrade: String, CaseIterable {
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case e = "E"
    
    var color: String {
        switch self {
        case .a: return "#038141"
        case .b: return "#85BB2F"
        case .c: return "#FECB02"
        case .d: return "#EE8100"
        case .e: return "#E63E11"
        }
    }
    
    var description: String {
        switch self {
        case .a: return "Very good nutritional quality"
        case .b: return "Good nutritional quality"
        case .c: return "Average nutritional quality"
        case .d: return "Poor nutritional quality"
        case .e: return "Very poor nutritional quality"
        }
    }
}
