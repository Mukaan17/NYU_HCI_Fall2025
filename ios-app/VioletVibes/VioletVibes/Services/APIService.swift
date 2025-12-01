//
//  APIService.swift
//  VioletVibes
//

import Foundation

actor APIService {
    static let shared = APIService()
    
    // Stored base URL
    nonisolated private let baseURL: String
    
    // MARK: - Init
    nonisolated private init() {
        // Priority 1 — Xcode environment variable
        if let apiURL = ProcessInfo.processInfo.environment["API_URL"] {
            baseURL = apiURL
        
        // Priority 2 — Config.plist
        } else if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
                  let config = NSDictionary(contentsOfFile: path),
                  let url = config["API_URL"] as? String {
            baseURL = url
        
        // Fallback — localhost
        } else {
            baseURL = "http://localhost:5001"
        }
    }

    // MARK: - Dashboard API Models
    struct DashboardAPIResponse: Codable {
        let weather: WeatherInfo?
        let quick_bites: [PlaceResult]?
        let cozy_cafes: [PlaceResult]?
        let events: [EventResult]?
        let explore: [PlaceResult]?
        let next_free: FreeTimeBlock?
        let free_time_recommendation: FreeTimeRecommendation?
    }

    struct WeatherInfo: Codable {
        let condition: String?
        let temperature: Double?
        let feels_like: Double?
    }

    struct PlaceResult: Codable {
        let name: String?
        let rating: Double?
        let walk_time: String?
        let location: String?
        let photo: String?
    }

    struct EventResult: Codable {
        let name: String?
        let start: String?
        let location: String?
        let url: String?
    }

    struct FreeTimeBlock: Codable {
        let start: String?
        let end: String?
    }

    struct FreeTimeRecommendation: Codable {
        let type: String?
        let title: String?
        let subtitle: String?
        let duration: Int?
        let url: String?
    }
    
    // MARK: - Chat
    nonisolated func sendChatMessage(_ message: String, latitude: Double? = nil, longitude: Double? = nil) async throws -> ChatAPIResponse {
        let url = URL(string: "\(baseURL)/api/chat")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var payload: [String: Any] = ["message": message]
        if let lat = latitude, let lng = longitude {
            payload["latitude"] = lat
            payload["longitude"] = lng
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            print("❌ Invalid HTTP response:", response)
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(ChatAPIResponse.self, from: data)
        } catch {
            print("❌ Chat decode error:", error)
            
            // Attempt minimal fallback decoding
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return ChatAPIResponse(
                    reply: json["reply"] as? String,
                    places: nil,
                    vibe: json["vibe"] as? String,
                    weather: nil,
                    error: json["error"] as? String
                )
            }
            
            throw APIError.decodingError(error.localizedDescription)
        }
    }
    
    // MARK: - Quick Recommendations
    nonisolated func getQuickRecommendations(category: String, limit: Int = 10) async throws -> QuickRecsAPIResponse {
        var urlComponents = URLComponents(string: "\(baseURL)/api/quick_recs")!
        urlComponents.queryItems = [
            URLQueryItem(name: "category", value: category.lowercased()),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        let (data, response) = try await URLSession.shared.data(from: urlComponents.url!)
        
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(QuickRecsAPIResponse.self, from: data)
    }
    
    // MARK: - Directions
    nonisolated func getDirections(lat: Double, lng: Double) async throws -> DirectionsAPIResponse {
        var urlComponents = URLComponents(string: "\(baseURL)/api/directions")!
        urlComponents.queryItems = [
            URLQueryItem(name: "lat", value: "\(lat)"),
            URLQueryItem(name: "lng", value: "\(lng)")
        ]
        
        let (data, response) = try await URLSession.shared.data(from: urlComponents.url!)
        
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(DirectionsAPIResponse.self, from: data)
    }
    
    // MARK: - Events
    nonisolated func getEvents() async throws -> EventsAPIResponse {
        guard let url = URL(string: "\(baseURL)/api/events") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(EventsAPIResponse.self, from: data)
    }

    // MARK: - Push Notifications
    nonisolated func registerPushToken(_ token: String, jwt: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/notifications/register_token") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")

        // MUST match backend: { "device_token": "..." }
        let body = ["device_token": token]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if http.statusCode != 200 {
            if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = errorDict["error"] as? String {
                throw APIError.serverError(msg)
            }
            throw APIError.invalidResponse
        }

        print("✅ Push token saved to backend!")
    }
}

// MARK: - API Error Types
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError(String)
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Server returned invalid response"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}
