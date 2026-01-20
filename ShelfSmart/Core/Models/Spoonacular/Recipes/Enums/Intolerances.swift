//
//  Enums.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/15/25.
//

import Foundation

enum Intolerances : String, CaseIterable, Codable{
    case dairy = "dairy"
    case egg = "egg"
    case gluten = "gluten"
    case grain = "grain"
    case peanut = "peanut"
    case seafood = "seafood"
    case sesame = "sesame"
    case shellfish = "shellfish"
    case soy = "soy"
    case sulfite = "sulfite"
    case treeNut = "tree_nut"
    case wheat = "wheat"
    
    // Display name for UI
    var displayName: String {
        switch self {
        case .dairy: return "Dairy"
        case .egg: return "Egg"
        case .gluten: return "Gluten"
        case .grain: return "Grain"
        case .peanut: return "Peanut"
        case .seafood: return "Seafood"
        case .sesame: return "Sesame"
        case .shellfish: return "Shellfish"
        case .soy: return "Soy"
        case .sulfite: return "Sulfite"
        case .treeNut: return "Tree Nut"
        case .wheat: return "Wheat"
        }
    }
    
    // API value (same as rawValue, but explicit)
    var apiValue: String {
        return self.rawValue
    }
    
    // Associated emoji for better UX
    var emoji: String {
        switch self {
        case .dairy: return "🥛"
        case .egg: return "🥚"
        case .gluten: return "🌾"
        case .grain: return "🌾"
        case .peanut: return "🥜"
        case .seafood: return "🐟"
        case .sesame: return "🌰"
        case .shellfish: return "🦐"
        case .soy: return "🫘"
        case .sulfite: return "🧪"
        case .treeNut: return "🌰"
        case .wheat: return "🌾"
        }
    }
}
