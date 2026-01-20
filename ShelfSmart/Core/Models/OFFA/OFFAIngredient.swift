//
//  OFFAIngredients.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 11/6/25.
//

import Foundation

// MARK: - Ingredient Model
struct OFFAIngredient: Codable, Identifiable {
    let id: String
    let text: String
    let percentEstimate: Double?
    let vegan: String?
    let vegetarian: String?
    
    enum CodingKeys: String, CodingKey {
        case id, text
        case percentEstimate = "percent_estimate"
        case vegan, vegetarian
    }
}

extension OFFAIngredient {
    static var mockData: OFFAIngredient {
        OFFAIngredient(id: "en:wheat-flour", text: "wheat flour", percentEstimate: nil, vegan: nil, vegetarian: nil)
    }
}
