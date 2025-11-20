//
//  Weather.swift
//  VioletVibes
//

import Foundation

struct Weather: Codable {
    let temp: Int
    let emoji: String
    
    enum CodingKeys: String, CodingKey {
        case temp, emoji
        case main, weather
    }
    
    init(temp: Int, emoji: String) {
        self.temp = temp
        self.emoji = emoji
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle OpenWeather API response
        if let mainDict = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .main),
           let tempDouble = try? mainDict.decode(Double.self, forKey: .temp) {
            temp = Int(round(tempDouble))
        } else {
            temp = try container.decode(Int.self, forKey: .temp)
        }
        
        // Handle weather condition
        if let weatherArray = try? container.decode([[String: String]].self, forKey: .weather),
           let condition = weatherArray.first?["main"]?.lowercased() {
            switch condition {
            case let c where c.contains("cloud"):
                emoji = "☁️"
            case let c where c.contains("rain"):
                emoji = "🌧️"
            case let c where c.contains("snow"):
                emoji = "❄️"
            case let c where c.contains("storm"):
                emoji = "⛈️"
            default:
                emoji = "☀️"
            }
        } else {
            emoji = try container.decode(String.self, forKey: .emoji)
        }
    }
}

