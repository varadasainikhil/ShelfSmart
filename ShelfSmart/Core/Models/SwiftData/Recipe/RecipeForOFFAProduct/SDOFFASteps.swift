//
//  SDStepsModel.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/16/25.
//

import Foundation
import SwiftData

@Model
class SDOFFASteps {
    var number: Int?
    var step: String?

    // Child collections
    @Relationship(deleteRule: .cascade, inverse: \SDOFFAStepIngredient.step)
    var ingredients : [SDOFFAStepIngredient]? = [SDOFFAStepIngredient]()

    @Relationship(deleteRule: .cascade, inverse: \SDOFFAEquipment.step)
    var equipments : [SDOFFAEquipment]? = [SDOFFAEquipment]()

    // Relationship back to analyzed instructions
    var analyzedInstruction: SDOFFAAnalyzedInstructions?
    
    init(from steps: Steps) {
        self.number = steps.number
        self.step = steps.step
        // Convert arrays of structs to arrays of models
        self.ingredients = steps.ingredients?.map { SDOFFAStepIngredient(from: $0) } ?? []
        self.equipments = steps.equipments?.map { SDOFFAEquipment(from: $0) } ?? []
    }
    
    // Required for SwiftData
    init(number: Int, step: String, ingredients: [SDOFFAStepIngredient], equipments: [SDOFFAEquipment]) {
        self.number = number
        self.step = step
        self.ingredients = ingredients
        self.equipments = equipments
    }
}
