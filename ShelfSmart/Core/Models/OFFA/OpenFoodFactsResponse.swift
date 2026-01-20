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

extension OpenFoodFactsResponse {
    static var mockData: OpenFoodFactsResponse {
        OpenFoodFactsResponse(code: "0009800800049", product: .mockData, status: 2, statusVerbose: nil)
    }
    
    // TODO: Implement API failure Mock Data
}



