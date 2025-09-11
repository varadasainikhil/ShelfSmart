//
//  OFFAProduct.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/5/25.
//

import Foundation

struct OFFAProduct : Codable{
    var productName : String
    var brands : String
    var imageURL : String
    var ingredientsText : String
    var nutriments : OFFANutriments
    var nutritionGrade : String
    
    
    enum CodingKeys : String, CodingKey{
        case productName = "product_name"
        case brands
        case imageURL = "image_url"
        case ingredientsText = "ingredients_text"
        case nutriments 
        case nutritionGrade = "nutrition_grades"
    }
}
