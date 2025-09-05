//
//  Product.swift
//  FreshAlert
//
//  Created by Sai Nikhil Varada on 9/3/25.
//

import Foundation

struct Product : Codable{
    let barcodeNumber : String
    let model : String
    let title : String
    let manufacturer : String
    let ingredients : String
    let nutritionFacts : String
    let description : String
    let images : [String]
    
    enum CodingKeys : String, CodingKey{
        case barcodeNumber = "barcode_number"
        case model
        case title
        case manufacturer
        case ingredients
        case nutritionFacts = "nutrition_facts"
        case description
        case images
    }
}
