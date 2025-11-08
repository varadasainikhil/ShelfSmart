//
//  OFFANutriscoreData.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 11/6/25.
//

import Foundation

// MARK: - Nutriscore Data
struct OFFANutriscoreData: Codable {
    let components: OFFANutriscoreComponents?
    
    enum CodingKeys: String, CodingKey {
        case components
    }
}

