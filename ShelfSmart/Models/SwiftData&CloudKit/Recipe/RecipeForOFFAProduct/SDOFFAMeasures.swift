//
//  SDMeasures.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/16/25.
//

import Foundation
import SwiftData

@Model
class SDOFFAMeasures {
    @Relationship(deleteRule: .cascade, inverse: \SDOFFAMeasure.owningMeasures)
    var us: SDOFFAMeasure?

    @Relationship(deleteRule: .cascade, inverse: \SDOFFAMeasure.owningMeasuresMetric)
    var metric: SDOFFAMeasure?

    // Relationship back to ingredients
    var SDIngredients: SDOFFAIngredients?

    init(from measures: Measures) {
        self.us = SDOFFAMeasure(from: measures.us)
        self.metric = SDOFFAMeasure(from: measures.metric)
    }

    // Required for SwiftData
    init(us: SDOFFAMeasure, metric: SDOFFAMeasure) {
        self.us = us
        self.metric = metric
    }

}
