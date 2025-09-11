//
//  OFFANutriments.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/5/25.
//

import Foundation

struct OFFANutriments : Codable {
    var nutritionScore : Int
    
    enum CodingKeys : String, CodingKey{
        case nutritionScore = "nutrition-score-fr"
    }
}
