//
//  OFFANutriments.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 11/6/25.
//

import Foundation

// MARK: - Nutriments (Nutrition per 100g)
struct OFFANutriments: Codable {
    // Added sugars
    let addedSugars: Double?
    let addedSugarsUnit: String?

    // Energy
    let energyKcal: Double?
    let energyKcalUnit: String?
    
    // Macronutrients
    let fat: Double?
    let fatUnit: String?
    
    let saturatedFat: Double?
    let saturatedFatUnit: String?
    
    let carbohydrates: Double?
    let carbohydratesUnit: String?
    
    let sugars: Double?
    let sugarsUnit: String?
    
    let fiber: Double? // Fiber values and units are sometimes missing so left without unit fields
    
    let proteins: Double?
    let proteinsUnit: String?
    
    let salt: Double?
    let saltUnit: String?
    
    let sodium: Double?
    let sodiumUnit: String?
    
    enum CodingKeys: String, CodingKey {
        case addedSugars = "added_sugars_100g"
        case addedSugarsUnit = "added_sugars_unit"
        
        case energyKcal = "energy-kcal_100g"
        case energyKcalUnit = "energy-kcal_unit"
        
        case fat = "fat_100g"
        case fatUnit = "fat_unit"
        
        case saturatedFat = "saturated-fat_100g"
        case saturatedFatUnit = "saturated-fat_unit"
        
        case carbohydrates = "carbohydrates_100g"
        case carbohydratesUnit = "carbohydrates_unit"
        
        case sugars = "sugars_100g"
        case sugarsUnit = "sugars_unit"
        
        case fiber = "fiber_100g"
        
        case proteins = "protiens_100g"
        case proteinsUnit = "proteins_unit"
        
        case salt = "salt_100g"
        case saltUnit = "salt_unit"
        
        case sodium = "sodium_100g"
        case sodiumUnit = "sodium_unit"
    }
}
