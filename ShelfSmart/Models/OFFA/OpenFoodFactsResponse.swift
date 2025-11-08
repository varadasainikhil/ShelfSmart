//
//  OpenFoodFactsResponse.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 11/6/25.
//

import Foundation


// MARK: - Main Response Model
struct OpenFoodFactsResponse: Codable {
    let code: String
    let product: OFFAProduct?
    let status: Int
    let statusVerbose: String?  // Optional since API doesn't always return this

    enum CodingKeys: String, CodingKey {
        case code
        case product
        case status
        case statusVerbose = "status_verbose"
    }
}



