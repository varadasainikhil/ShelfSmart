//
//  Ingredients.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/15/25.
//

import Foundation

struct Ingredients : Codable{
    var id : Int
    var image : String?
    var consistency : String
    var name : String
    var original : String
    var originalName : String
    var amount : Double
    var unit : String
    var measures : Measures
    
}
