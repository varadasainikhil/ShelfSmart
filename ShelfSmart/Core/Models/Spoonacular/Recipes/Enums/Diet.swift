//
//  Diet.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/15/25.
//

import Foundation

enum Diet: String, CaseIterable, Codable {
    case glutenFree = "gluten_free"
    case ketogenic = "ketogenic"
    case vegetarian = "vegetarian"
    case lactoVegetarian = "lacto_vegetarian"
    case ovoVegetarian = "ovo_vegetarian"
    case vegan = "vegan"
    case pescetarian = "pescetarian"
    case paleo = "paleo"
    case primal = "primal"
    case lowFODMAP = "low_fodmap"
    case whole30 = "whole30"
    
    // Display name for UI
    var displayName: String {
        switch self {
        case .glutenFree: return "Gluten Free"
        case .ketogenic: return "Ketogenic"
        case .vegetarian: return "Vegetarian"
        case .lactoVegetarian: return "Lacto-Vegetarian"
        case .ovoVegetarian: return "Ovo-Vegetarian"
        case .vegan: return "Vegan"
        case .pescetarian: return "Pescetarian"
        case .paleo: return "Paleo"
        case .primal: return "Primal"
        case .lowFODMAP: return "Low FODMAP"
        case .whole30: return "Whole30"
        }
    }
    
    // API value (same as rawValue, but explicit)
    var apiValue: String {
        return self.rawValue
    }
    
    // Associated emoji for better UX
    var emoji: String {
        switch self {
        case .glutenFree: return "🌾"
        case .ketogenic: return "🥑"
        case .vegetarian: return "🥕"
        case .lactoVegetarian: return "🥛"
        case .ovoVegetarian: return "🥚"
        case .vegan: return "🌱"
        case .pescetarian: return "🐟"
        case .paleo: return "🦴"
        case .primal: return "🥩"
        case .lowFODMAP: return "🍃"
        case .whole30: return "🌿"
        }
    }
    
    // Optional: Brief description for each diet
    var description: String {
        switch self {
        case .glutenFree:
            return "Excludes gluten-containing grains like wheat, barley, and rye"
        case .ketogenic:
            return "Very low carb, high fat diet that puts body into ketosis"
        case .vegetarian:
            return "Excludes meat, poultry, and fish but includes dairy and eggs"
        case .lactoVegetarian:
            return "Vegetarian diet that includes dairy but excludes eggs"
        case .ovoVegetarian:
            return "Vegetarian diet that includes eggs but excludes dairy"
        case .vegan:
            return "Excludes all animal products including meat, dairy, and eggs"
        case .pescetarian:
            return "Vegetarian diet that includes fish and seafood"
        case .paleo:
            return "Based on foods available during Paleolithic era"
        case .primal:
            return "Similar to paleo but allows some dairy and natural sweeteners"
        case .lowFODMAP:
            return "Restricts fermentable carbs to reduce digestive symptoms"
        case .whole30:
            return "30-day elimination diet focusing on whole foods"
        }
    }
}
