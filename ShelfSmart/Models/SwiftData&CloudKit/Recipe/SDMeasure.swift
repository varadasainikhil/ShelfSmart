//
//  SDMeasure.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/16/25.
//

import Foundation
import SwiftData

@Model
class SDMeasure {
    var amount: Double
    var unitShort: String
    var unitLong: String
    
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
