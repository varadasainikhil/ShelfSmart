//
//  SDAnalyzedInstructionsModel.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/16/25.
//

import Foundation
import SwiftData

@Model
class SDOFFAAnalyzedInstructions {
    var name: String?

    // One-to-many relationship with SDSteps
    @Relationship(deleteRule: .cascade, inverse: \SDOFFASteps.analyzedInstruction)
    var steps : [SDOFFASteps]? = [SDOFFASteps]()

    // Relationship back to recipe
    var recipe: SDOFFARecipe?

    init(from analyzedInstructions: AnalyzedInstructions) {
        self.name = analyzedInstructions.name
        // Convert array of Steps structs to array of StepsModel
        self.steps = analyzedInstructions.steps?.map { SDOFFASteps(from: $0) } ?? []
    }
    
    // Required for SwiftData
    init(name: String, steps: [SDOFFASteps]) {
        self.name = name
        self.steps = steps
    }
}
