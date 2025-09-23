//
//  SDEquipment.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/16/25.
//

import Foundation
import SwiftData

@Model
class SDEquipment {
    var id: Int?
    var name: String?
    var localizedName: String?
    var image: String?
    
    // Relationship back to steps
    var SDSteps: SDSteps?
    
    init(from equipment: Equipment) {
        self.id = equipment.id
        self.name = equipment.name
        self.localizedName = equipment.localizedName
        self.image = equipment.image
    }
    
    // Required for SwiftData
    init(id: Int, name: String, localizedName: String, image: String) {
        self.id = id
        self.name = name
        self.localizedName = localizedName
        self.image = image
    }
}
