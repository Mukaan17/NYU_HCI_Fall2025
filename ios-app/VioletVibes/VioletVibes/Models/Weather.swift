//
//  Weather.swift
//  VioletVibes
//

import Foundation

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
        
        var decodedTemp: Int? = nil
        
        // Handle server format: temp_f (from weather service) - supports negative temperatures
        if let tempF = try? container.decodeIfPresent(Double.self, forKey: .temp_f) {
            decodedTemp = Int(round(tempF))
            print("🌡️ Weather: Decoded temp_f = \(tempF) -> \(decodedTemp ?? 0)°F")
        }
        // Handle OpenWeather API response format: main.temp - supports negative temperatures
        else if let mainDict = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .main),
                let tempDouble = try? mainDict.decode(Double.self, forKey: .temp) {
            decodedTemp = Int(round(tempDouble))
            print("🌡️ Weather: Decoded main.temp = \(tempDouble) -> \(decodedTemp ?? 0)°F")
        }
        // Handle direct temp field (Int) - supports negative temperatures
        else if let tempInt = try? container.decodeIfPresent(Int.self, forKey: .temp) {
            decodedTemp = tempInt
            print("🌡️ Weather: Decoded temp (Int) = \(tempInt)°F")
        }
        // Handle temp as Double in root - supports negative temperatures
        else if let tempDouble = try? container.decodeIfPresent(Double.self, forKey: .temp) {
            decodedTemp = Int(round(tempDouble))
            print("🌡️ Weather: Decoded temp (Double) = \(tempDouble) -> \(decodedTemp ?? 0)°F")
        } else {
            print("⚠️ Weather: No temperature field found, defaulting to 0°F")
        }
        
        // Use decoded temperature or default to 0 if not found
        // Note: 0 is a valid temperature, but we use it as a fallback for missing data
        temp = decodedTemp ?? 0
        
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
        else if let weatherArray = try? container.decode([[String: String]].self, forKey: .weather),
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

// Forecast models for hourly weather data
struct HourlyForecast: Identifiable, Sendable {
    let id: UUID
    let time: Date
    let temp: Int
    let emoji: String
    let description: String
    let humidity: Int?
    let windSpeed: Double?
    
    init(id: UUID = UUID(), time: Date, temp: Int, emoji: String, description: String, humidity: Int? = nil, windSpeed: Double? = nil) {
        self.id = id
        self.time = time
        self.temp = temp
        self.emoji = emoji
        self.description = description
        self.humidity = humidity
        self.windSpeed = windSpeed
    }
}

// OpenWeather Forecast API Response Structure
struct ForecastResponse: Codable, Sendable {
    let list: [ForecastItem]
    
    struct ForecastItem: Codable, Sendable {
        let dt: TimeInterval // Unix timestamp
        let main: MainData
        let weather: [WeatherData]
        let wind: WindData?
        
        struct MainData: Codable, Sendable {
            let temp: Double
            let humidity: Int?
        }
        
        struct WeatherData: Codable, Sendable {
            let main: String
            let description: String
        }
        
        struct WindData: Codable, Sendable {
            let speed: Double?
        }
    }
}

// Helper function to convert weather condition to emoji
func weatherConditionToEmoji(_ condition: String) -> String {
    let conditionLower = condition.lowercased()
    if conditionLower.contains("cloud") {
        return "☁️"
    } else if conditionLower.contains("rain") {
        return "🌧️"
    } else if conditionLower.contains("snow") {
        return "❄️"
    } else if conditionLower.contains("storm") || conditionLower.contains("thunder") {
        return "⛈️"
    } else if conditionLower.contains("mist") || conditionLower.contains("fog") {
        return "🌫️"
    } else {
        return "☀️"
    }
}

