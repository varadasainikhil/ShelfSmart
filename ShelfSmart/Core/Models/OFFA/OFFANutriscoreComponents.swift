//
//  OFFANutriscoreComponents.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 11/6/25.
//

import Foundation

// MARK: - Nutriscore Components
struct OFFANutriscoreComponents: Codable {
    let negative: [OFFANutrientComponent]?
    let positive: [OFFANutrientComponent]?
}

extension OFFANutriscoreComponents {
    static var mockData : OFFANutriscoreComponents {
        OFFANutriscoreComponents(negative: [.mockData], positive: [.mockData])
    }
}
