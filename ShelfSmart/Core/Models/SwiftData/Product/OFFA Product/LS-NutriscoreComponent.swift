//
//  LS-NutriscoreComponent.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 11/7/25.
//

import Foundation
import SwiftData

/// SwiftData model for individual nutrient component in nutriscore calculation
/// Represents either a positive or negative nutrient factor
@Model
final class LSNutrientComponent {
    /// Unique identifier for the nutrient (e.g., "energy", "saturated_fat")
    /// Note: CloudKit doesn't support unique constraints, so this is just a regular attribute
    var nutrientId: String = ""

    /// Nutrient value
    var value: Double?

    /// Points assigned for this nutrient in nutriscore calculation
    var points: Int?

    /// Maximum possible points for this nutrient
    var pointsMax: Int?

    /// Measurement unit (e.g., "g", "kcal")
    var unit: String?

    /// Inverse relationship to the components group (for negative list)
    var negativeComponentsGroup: LSNutriscoreComponents?
    
    /// Inverse relationship to the components group (for positive list)
    var positiveComponentsGroup: LSNutriscoreComponents?

    init(
        nutrientId: String = "",
        value: Double? = nil,
        points: Int? = nil,
        pointsMax: Int? = nil,
        unit: String? = nil
    ) {
        self.nutrientId = nutrientId
        self.value = value
        self.points = points
        self.pointsMax = pointsMax
        self.unit = unit
    }

    /// Convenience initializer from OFFA API model
    convenience init(from offa: OFFANutrientComponent) {
        self.init(
            nutrientId: offa.nutrientId,
            value: offa.value,
            points: offa.points,
            pointsMax: offa.pointsMax,
            unit: offa.unit
        )
    }
}

