//
//  Weather.swift
//  VioletVibes
//

import Foundation

struct WeatherCondition: Codable, Sendable {
    let main: String
    let description: String?
}

struct Weather: Codable, Sendable {
    let temp: Int
    let emoji: String
    
    enum CodingKeys: String, CodingKey {
        case temp, emoji
        case temp_f, desc, icon
        case main, weather
    }
    
    init(temp: Int, emoji: String) {
        self.temp = temp
        self.emoji = emoji
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle server format: temp_f (from weather service)
        if let tempF = try? container.decodeIfPresent(Double.self, forKey: .temp_f) {
            temp = Int(round(tempF))
        }
        // Handle OpenWeather API response format: main.temp
        else if let mainDict = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .main),
           let tempDouble = try? mainDict.decode(Double.self, forKey: .temp) {
            temp = Int(round(tempDouble))
        }
        // Handle direct temp field
        else if let tempInt = try? container.decodeIfPresent(Int.self, forKey: .temp) {
            temp = tempInt
        } else {
            // Default if no temperature found
            temp = 0
        }
        
        // Handle server format: desc/icon (from weather service)
        if let desc = try? container.decodeIfPresent(String.self, forKey: .desc) {
            let descLower = desc.lowercased()
            if descLower.contains("cloud") {
                emoji = "☁️"
            } else if descLower.contains("rain") {
                emoji = "🌧️"
            } else if descLower.contains("snow") {
                emoji = "❄️"
            } else if descLower.contains("storm") {
                emoji = "⛈️"
            } else {
                emoji = "☀️"
            }
        }
        // Handle OpenWeather API response format: weather array
        else if let weatherList = try? container.decode([WeatherCondition].self, forKey: .weather),
                let condition = weatherList.first?.main.lowercased() {
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
        }
        // Handle direct emoji field
        else if let emojiValue = try? container.decodeIfPresent(String.self, forKey: .emoji) {
            emoji = emojiValue
        } else {
            // Default emoji
            emoji = "☀️"
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(temp, forKey: .temp)
        try container.encode(emoji, forKey: .emoji)
    }
}

