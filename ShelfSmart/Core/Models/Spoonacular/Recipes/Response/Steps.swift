//
//  Steps.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/15/25.
//

import Foundation

struct Steps : Codable{
    var number : Int
    var step : String
    var ingredients : [StepIngredient]?
    var equipments : [Equipment]?
}
