//
//  SDStepIngredient.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/17/25.
//

import Foundation
import SwiftData

@Model
class SDStepIngredient {
    var id: Int?
    var name: String?
    var localizedName: String?
    var image: String?

    // Relationship back to steps
    var step: SDSteps?
    
    init(from stepIngredient: StepIngredient) {
        self.id = stepIngredient.id
        self.name = stepIngredient.name
        self.localizedName = stepIngredient.localizedName
        self.image = stepIngredient.image
    }
    
    // Required for SwiftData
    init(id: Int, name: String, localizedName: String, image: String) {
        self.id = id
        self.name = name
        self.localizedName = localizedName
        self.image = image
    }
}
