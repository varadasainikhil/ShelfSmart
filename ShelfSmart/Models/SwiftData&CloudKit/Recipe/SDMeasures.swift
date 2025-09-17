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
    var us: SDMeasure
    var metric: SDMeasure
    
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
