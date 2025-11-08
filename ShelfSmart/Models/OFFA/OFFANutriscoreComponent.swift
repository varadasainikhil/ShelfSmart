//
//  OFFANutriscoreComponent.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 11/6/25.
//

import Foundation


// MARK: - Nutrient Component
struct OFFANutrientComponent: Codable, Identifiable {
    var id: String { nutrientId }
    let nutrientId: String
    let value: Double?
    let points: Int?
    let pointsMax: Int?
    let unit: String?
    
    enum CodingKeys: String, CodingKey {
        case nutrientId = "id"
        case value, points
        case pointsMax = "points_max"
        case unit
    }
}

