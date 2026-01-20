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

    // Labels (organic, vegan, vegetarian, gluten-free, etc.)
    let labelsTags: [String]?

    // EcoScore
    let ecoScoreGrade : String?
    let ecoScoreScore : Int?
    
    // Ingredients
    let ingredientsText: String? // TODO: Implement as a backup for ingredients if Ingredient is not found
    let ingredients: [OFFAIngredient]?
    
    // NOVA GROUP
    let novaGroup : Int?
    
    // Nutrition (per 100g)
    let nutriments: OFFANutriments?
    
    // Nutri-Score
    let nutriscoreGrade: String?
    let nutriscoreScore: Int?
    let nutriscoreData: OFFANutriscoreData?
    
    // Serving Size
    let servingSize : String?
        
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
        case labelsTags = "labels_tags"
        case ecoScoreGrade = "ecoscore_grade"
        case ecoScoreScore = "ecoscore_score"
        case ingredientsText = "ingredients_text"
        case ingredients
        case novaGroup = "nova_group"
        case nutriments
        case nutriscoreGrade = "nutriscore_grade"
        case nutriscoreScore = "nutriscore_score"
        case nutriscoreData = "nutriscore_data"
        case servingSize = "serving_size"
    }
}

extension OFFAProduct {
    static var mockData : OFFAProduct {
        
        OFFAProduct(id: "0009800800049", code: "0009800800049", productName: "Nutella & go! hazelnut spread + breadsticks", brands: "Nutella", quantity: nil, imageURL: "https://images.openfoodfacts.net/images/products/000/980/080/0049/front_en.5.400.jpg", imageFrontURL: nil, imageIngredientsURL: nil, imageNutritionURL: nil, allergens: "en:gluten", allergensTags: ["en:gluten"], labelsTags: nil, ecoScoreGrade: "unknown", ecoScoreScore: nil, ingredientsText: "wheat flour, palm oil, salt, malt extract, baker's yeast.", ingredients: [.mockData], novaGroup: 3, nutriments: .mockData, nutriscoreGrade: "e", nutriscoreScore: 29, nutriscoreData: .mockData, servingSize: "1 UNIT(52g)")
    }
}
