//
//  Cuisines.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/15/25.
//

import Foundation

enum Cuisine: String, CaseIterable, Codable {
    case african = "african"
    case asian = "asian"
    case american = "american"
    case british = "british"
    case cajun = "cajun"
    case caribbean = "caribbean"
    case chinese = "chinese"
    case easternEuropean = "eastern_european"
    case european = "european"
    case french = "french"
    case german = "german"
    case greek = "greek"
    case indian = "indian"
    case irish = "irish"
    case italian = "italian"
    case japanese = "japanese"
    case jewish = "jewish"
    case korean = "korean"
    case latinAmerican = "latin_american"
    case mediterranean = "mediterranean"
    case mexican = "mexican"
    case middleEastern = "middle_eastern"
    case nordic = "nordic"
    case southern = "southern"
    case spanish = "spanish"
    case thai = "thai"
    case vietnamese = "vietnamese"
    
    // Display name for UI
    var displayName: String {
        switch self {
        case .african: return "African"
        case .asian: return "Asian"
        case .american: return "American"
        case .british: return "British"
        case .cajun: return "Cajun"
        case .caribbean: return "Caribbean"
        case .chinese: return "Chinese"
        case .easternEuropean: return "Eastern European"
        case .european: return "European"
        case .french: return "French"
        case .german: return "German"
        case .greek: return "Greek"
        case .indian: return "Indian"
        case .irish: return "Irish"
        case .italian: return "Italian"
        case .japanese: return "Japanese"
        case .jewish: return "Jewish"
        case .korean: return "Korean"
        case .latinAmerican: return "Latin American"
        case .mediterranean: return "Mediterranean"
        case .mexican: return "Mexican"
        case .middleEastern: return "Middle Eastern"
        case .nordic: return "Nordic"
        case .southern: return "Southern"
        case .spanish: return "Spanish"
        case .thai: return "Thai"
        case .vietnamese: return "Vietnamese"
        }
    }
    
    // API value (same as rawValue, but explicit)
    var apiValue: String {
        return self.rawValue
    }
    
    // Optional: Associated flag emoji for better UX
    var flagEmoji: String {
        switch self {
        case .african: return "🌍"
        case .asian: return "🌏"
        case .american: return "🇺🇸"
        case .british: return "🇬🇧"
        case .cajun: return "🎺"
        case .caribbean: return "🏝️"
        case .chinese: return "🇨🇳"
        case .easternEuropean: return "🏰"
        case .european: return "🇪🇺"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .greek: return "🇬🇷"
        case .indian: return "🇮🇳"
        case .irish: return "🇮🇪"
        case .italian: return "🇮🇹"
        case .japanese: return "🇯🇵"
        case .jewish: return "✡️"
        case .korean: return "🇰🇷"
        case .latinAmerican: return "🌎"
        case .mediterranean: return "🫒"
        case .mexican: return "🇲🇽"
        case .middleEastern: return "🕌"
        case .nordic: return "❄️"
        case .southern: return "🌾"
        case .spanish: return "🇪🇸"
        case .thai: return "🇹🇭"
        case .vietnamese: return "🇻🇳"
        }
    }
}
