//
//  Credit.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/25/25.
//

import Foundation
import SwiftData

@Model
class Credit {
    var text: String?
    var link: String?
    var image: String?
    var imageLink: String?
    
    // Inverse relationship back to Product
    var product: Product?
    
    init(text: String?, link: String?, image: String?, imageLink: String?) {
        self.text = text
        self.link = link
        self.image = image
        self.imageLink = imageLink
    }
    
    // Convenience initializer from SpoonacularCredit
    convenience init(from credit: SpoonacularCredit) {
        self.init(
            text: credit.text,
            link: credit.link,
            image: credit.image,
            imageLink: credit.imageLink
        )
    }
}

