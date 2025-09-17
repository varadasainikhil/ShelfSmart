//
//  SDStepsModel.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/16/25.
//

import Foundation
import SwiftData

@Model
class SDSteps {
    var number: Int
    var step: String
    var ingredients: [SDStepIngredient]
    var equipments: [SDEquipment]
    
    init(from steps: Steps) {
        self.number = steps.number
        self.step = steps.step
        // Convert arrays of structs to arrays of models
        self.ingredients = steps.ingredients?.map { SDStepIngredient(from: $0) } ?? []
        self.equipments = steps.equipments?.map { SDEquipment(from: $0) } ?? []
    }
    
    // Required for SwiftData
    init(number: Int, step: String, ingredients: [SDStepIngredient], equipments: [SDEquipment]) {
        self.number = number
        self.step = step
        self.ingredients = ingredients
        self.equipments = equipments
    }
}
