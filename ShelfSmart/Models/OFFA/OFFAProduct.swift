//
//  OFFAProduct.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 11/6/25.
//

import Foundation

// MARK: - Product Model
struct OFFAProduct: Codable, Identifiable {
    let id: String
    let code: String
    let productName: String?
    let brands: String?
    let quantity: String?
    
    // Images
    let imageURL: String?
    let imageFrontURL: String?
    let imageIngredientsURL: String?
    let imageNutritionURL: String?
    
    // Allergens
    let allergens: String?
    let allergensTags: [String]?
    
    // Ingredients
    let ingredientsText: String? // TODO: Implement as a backup for ingredients if Ingredient is not found
    let ingredients: [OFFAIngredient]?
    
    // Nutrition (per 100g)
    let nutriments: OFFANutriments?
    
    // Nutri-Score
    let nutriscoreGrade: String?
    let nutriscoreScore: Int?
    let nutriscoreData: OFFANutriscoreData?
        
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case code
        case productName = "product_name"
        case brands
        case quantity
        case imageURL = "image_url"
        case imageFrontURL = "image_front_url"
        case imageIngredientsURL = "image_ingredients_url"
        case imageNutritionURL = "image_nutrition_url"
        case allergens
        case allergensTags = "allergens_tags"
        case ingredientsText = "ingredients_text"
        case ingredients
        case nutriments
        case nutriscoreGrade = "nutriscore_grade"
        case nutriscoreScore = "nutriscore_score"
        case nutriscoreData = "nutriscore_data"
    }
}

