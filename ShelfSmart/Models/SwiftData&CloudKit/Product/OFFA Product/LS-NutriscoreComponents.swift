//
//  LS-NutriscoreComponents.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 11/7/25.
//

import Foundation
import SwiftData

/// SwiftData model for nutriscore component groups
/// Contains arrays of negative and positive nutrient components
@Model
final class LSNutriscoreComponents {
    /// Negative nutrient components (decrease nutriscore)
    /// E.g., energy, saturated fat, sugars, sodium
    @Relationship(deleteRule: .cascade, inverse: \LSNutrientComponent.negativeComponentsGroup)
    var negative: [LSNutrientComponent]?

    /// Positive nutrient components (increase nutriscore)
    /// E.g., fiber, proteins, fruits/vegetables
    @Relationship(deleteRule: .cascade, inverse: \LSNutrientComponent.positiveComponentsGroup)
    var positive: [LSNutrientComponent]?

    /// Inverse relationship to the nutriscore data that contains these components
    var nutriscoreData: LSNutriscoreData?

    init(
        negative: [LSNutrientComponent]? = nil,
        positive: [LSNutrientComponent]? = nil
    ) {
        self.negative = negative
        self.positive = positive
    }

    /// Convenience initializer from OFFA API model
    convenience init(from offa: OFFANutriscoreComponents) {
        let negativeComponents = offa.negative?.map { LSNutrientComponent(from: $0) }
        let positiveComponents = offa.positive?.map { LSNutrientComponent(from: $0) }

        self.init(
            negative: negativeComponents,
            positive: positiveComponents
        )
    }
}

