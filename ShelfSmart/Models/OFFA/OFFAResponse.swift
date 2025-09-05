//
//  OFFAResponse.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/5/25.
//

import Foundation

struct OFFAResponse : Codable{
    var code: String
    var product : OFFAProduct
    var status : Int
}
