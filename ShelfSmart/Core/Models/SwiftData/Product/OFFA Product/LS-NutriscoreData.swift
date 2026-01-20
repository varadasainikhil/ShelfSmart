//
//  LS-NutriscoreData.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 11/7/25.
//

import Foundation
import SwiftData

/// SwiftData model for nutriscore calculation data
/// Wrapper for nutriscore component groups
@Model
final class LSNutriscoreData {
    /// Nutriscore components (negative and positive nutrient factors)
    @Relationship(deleteRule: .cascade, inverse: \LSNutriscoreComponents.nutriscoreData)
    var components: LSNutriscoreComponents?

    /// Inverse relationship to the product that has this nutriscore data
    var product: LSProduct?

    init(components: LSNutriscoreComponents? = nil) {
        self.components = components
    }

    /// Convenience initializer from OFFA API model
    convenience init(from offa: OFFANutriscoreData) {
        let components = offa.components.map { LSNutriscoreComponents(from: $0) }
        self.init(components: components)
    }
}

