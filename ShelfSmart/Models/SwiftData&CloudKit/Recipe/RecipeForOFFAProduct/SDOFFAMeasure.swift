//
//  SDMeasure.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/16/25.
//

import Foundation
import SwiftData

@Model
class SDOFFAMeasure {
    var amount: Double?
    var unitShort: String?
    var unitLong: String?

    // Inverse relationships - one measure can belong to one SDMeasures as either us or metric
    var owningMeasures: SDOFFAMeasures?  // When this measure is the "us" measurement
    var owningMeasuresMetric: SDOFFAMeasures?  // When this measure is the "metric" measurement

    init(from measure: MeasureResponse) {
        self.amount = measure.amount
        self.unitShort = measure.unitShort
        self.unitLong = measure.unitLong
    }

    // Required for SwiftData
    init(amount: Double, unitShort: String, unitLong: String) {
        self.amount = amount
        self.unitShort = unitShort
        self.unitLong = unitLong
    }

}
