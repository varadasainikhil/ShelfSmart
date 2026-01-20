//
//  DishTypes.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/15/25.
//

import Foundation

enum MealType: String, CaseIterable, Codable {
    case mainCourse = "main_course"
    case sideDish = "side_dish"
    case dessert = "dessert"
    case appetizer = "appetizer"
    case salad = "salad"
    case bread = "bread"
    case breakfast = "breakfast"
    case soup = "soup"
    case beverage = "beverage"
    case sauce = "sauce"
    case marinade = "marinade"
    case fingerfood = "fingerfood"
    case snack = "snack"
    case drink = "drink"
    
    // Display name for UI
    var displayName: String {
        switch self {
        case .mainCourse: return "Main Course"
        case .sideDish: return "Side Dish"
        case .dessert: return "Dessert"
        case .appetizer: return "Appetizer"
        case .salad: return "Salad"
        case .bread: return "Bread"
        case .breakfast: return "Breakfast"
        case .soup: return "Soup"
        case .beverage: return "Beverage"
        case .sauce: return "Sauce"
        case .marinade: return "Marinade"
        case .fingerfood: return "Fingerfood"
        case .snack: return "Snack"
        case .drink: return "Drink"
        }
    }
    
    // API value (same as rawValue, but explicit)
    var apiValue: String {
        return self.rawValue
    }
    
}
