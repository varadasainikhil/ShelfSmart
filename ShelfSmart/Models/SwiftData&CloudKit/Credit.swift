//
//  Credit.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/11/25.
//

import Foundation
import SwiftData

@Model
class Credit {
    var text : String?
    var link : String?
    var image : String?
    var imageLink : String?
    
    // Relationship: One Credit belongs to one Product
    @Relationship(inverse: \Product.credits)
    var product: Product?
    
    init(text: String? = nil, link: String? = nil, image: String? = nil, imageLink: String? = nil) {
        self.text = text
        self.link = link
        self.image = image
        self.imageLink = imageLink
    }
}
