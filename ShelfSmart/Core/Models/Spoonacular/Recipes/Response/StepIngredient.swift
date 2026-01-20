//
//  StepIngredient.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/17/25.
//

import Foundation

// Simplified ingredient structure used in recipe steps
struct StepIngredient : Codable{
    var id : Int
    var name : String
    var localizedName : String
    var image : String
}
