//
//  SDAnalyzedInstructionsModel.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/16/25.
//

import Foundation
import SwiftData

@Model
class SDAnalyzedInstructions {
    var name: String
    var steps: [SDSteps]
    
    init(from analyzedInstructions: AnalyzedInstructions) {
        self.name = analyzedInstructions.name
        // Convert array of Steps structs to array of StepsModel
        self.steps = analyzedInstructions.steps?.map { SDSteps(from: $0) } ?? []
    }
    
    // Required for SwiftData
    init(name: String, steps: [SDSteps]) {
        self.name = name
        self.steps = steps
    }
}
