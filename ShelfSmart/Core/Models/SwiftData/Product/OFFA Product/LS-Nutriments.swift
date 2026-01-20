//
//  LS-Nutriments.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 11/7/25.
//

import Foundation
import SwiftData

/// SwiftData model for nutritional information per 100g of product
@Model
final class LSNutriments {
    // Energy
    var energyKcal: Double?
    var energyKcalUnit: String?

    // Fat
    var fat: Double?
    var fatUnit: String?

    // Saturated Fat
    var saturatedFat: Double?
    var saturatedFatUnit: String?

    // Carbohydrates
    var carbohydrates: Double?
    var carbohydratesUnit: String?

    // Sugars
    var sugars: Double?
    var sugarsUnit: String?

    // Fiber (note: no unit field for fiber in API)
    var fiber: Double?

    // Proteins
    var proteins: Double?
    var proteinsUnit: String?

    // Salt
    var salt: Double?
    var saltUnit: String?

    // Sodium
    var sodium: Double?
    var sodiumUnit: String?

    /// Inverse relationship to the product that has this nutritional data
    var product: LSProduct?

    init(
        energyKcal: Double? = nil,
        energyKcalUnit: String? = nil,
        fat: Double? = nil,
        fatUnit: String? = nil,
        saturatedFat: Double? = nil,
        saturatedFatUnit: String? = nil,
        carbohydrates: Double? = nil,
        carbohydratesUnit: String? = nil,
        sugars: Double? = nil,
        sugarsUnit: String? = nil,
        fiber: Double? = nil,
        proteins: Double? = nil,
        proteinsUnit: String? = nil,
        salt: Double? = nil,
        saltUnit: String? = nil,
        sodium: Double? = nil,
        sodiumUnit: String? = nil
    ) {
        self.energyKcal = energyKcal
        self.energyKcalUnit = energyKcalUnit
        self.fat = fat
        self.fatUnit = fatUnit
        self.saturatedFat = saturatedFat
        self.saturatedFatUnit = saturatedFatUnit
        self.carbohydrates = carbohydrates
        self.carbohydratesUnit = carbohydratesUnit
        self.sugars = sugars
        self.sugarsUnit = sugarsUnit
        self.fiber = fiber
        self.proteins = proteins
        self.proteinsUnit = proteinsUnit
        self.salt = salt
        self.saltUnit = saltUnit
        self.sodium = sodium
        self.sodiumUnit = sodiumUnit
    }

    /// Convenience initializer from OFFA API model
    convenience init(from offa: OFFANutriments) {
        self.init(
            energyKcal: offa.energyKcal,
            energyKcalUnit: offa.energyKcalUnit,
            fat: offa.fat,
            fatUnit: offa.fatUnit,
            saturatedFat: offa.saturatedFat,
            saturatedFatUnit: offa.saturatedFatUnit,
            carbohydrates: offa.carbohydrates,
            carbohydratesUnit: offa.carbohydratesUnit,
            sugars: offa.sugars,
            sugarsUnit: offa.sugarsUnit,
            fiber: offa.fiber,
            proteins: offa.proteins,
            proteinsUnit: offa.proteinsUnit,
            salt: offa.salt,
            saltUnit: offa.saltUnit,
            sodium: offa.sodium,
            sodiumUnit: offa.sodiumUnit
        )
    }
}

