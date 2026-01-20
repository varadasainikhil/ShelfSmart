//
//  SDMeasures.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/16/25.
//

import Foundation
import SwiftData

@Model
class SDMeasures {
    @Relationship(deleteRule: .cascade, inverse: \SDMeasure.owningMeasures)
    var us: SDMeasure?

    @Relationship(deleteRule: .cascade, inverse: \SDMeasure.owningMeasuresMetric)
    var metric: SDMeasure?

    // Relationship back to ingredients
    var SDIngredients: SDIngredients?

    init(from measures: Measures) {
        self.us = SDMeasure(from: measures.us)
        self.metric = SDMeasure(from: measures.metric)
    }

    // Required for SwiftData
    init(us: SDMeasure, metric: SDMeasure) {
        self.us = us
        self.metric = metric
    }

}
