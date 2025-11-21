//
//  APIService.swift
//  VioletVibes
//

import Foundation

actor APIService {
    static let shared = APIService()
    
    nonisolated private let baseURL: String
    
    nonisolated private init() {
        // Get base URL from environment or use default
        if let apiURL = ProcessInfo.processInfo.environment["API_URL"] {
            baseURL = apiURL
        } else if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
                  let config = NSDictionary(contentsOfFile: path),
                  let url = config["API_URL"] as? String {
            baseURL = url
        } else {
            baseURL = "http://localhost:5001"
        }
    }
    
    // MARK: - Chat
    nonisolated func sendChatMessage(_ message: String, latitude: Double? = nil, longitude: Double? = nil) async throws -> ChatAPIResponse {
        var urlComponents = URLComponents(string: "\(baseURL)/api/chat")!
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var payload: [String: Any] = ["message": message]
        if let lat = latitude, let lng = longitude {
            payload["latitude"] = lat
            payload["longitude"] = lng
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("❌ Invalid HTTP response: \(response)")
            throw APIError.invalidResponse
        }
        
        // Check if data is empty
        guard !data.isEmpty else {
            print("❌ Received empty response data")
            throw APIError.decodingError("Empty response from server")
        }
        
        // Log raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Raw API Response (\(data.count) bytes): \(responseString.prefix(500))")
        } else {
            print("❌ Could not convert response data to string")
        }
        
        // Try to parse as JSON first to see structure
        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("📋 Parsed JSON keys: \(Array(jsonObject.keys))")
        } else {
            print("❌ Could not parse response as JSON")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let apiResponse = try decoder.decode(ChatAPIResponse.self, from: data)
            print("✅ Successfully decoded response")
            print("   - Reply: \(apiResponse.reply ?? "nil")")
            print("   - Places count: \(apiResponse.places?.count ?? 0)")
            return apiResponse
        } catch {
            print("❌ Decoding error: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("   Missing key: \(key.stringValue) at path: \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    print("   Type mismatch: expected \(type) at path: \(context.codingPath)")
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let pathString = context.codingPath.map { $0.stringValue }.joined(separator: ".")
                        print("   Actual value at \(pathString): \(jsonObject[pathString] ?? "not found")")
                    }
                case .valueNotFound(let type, let context):
                    print("   Value not found: \(type) at path: \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("   Data corrupted at path: \(context.codingPath)")
                    print("   Debug: \(context.debugDescription)")
                @unknown default:
                    print("   Unknown decoding error")
                }
            }
            
            // Try to decode error message
            if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMsg = errorDict["error"] as? String {
                throw APIError.serverError(errorMsg)
            }
            
            // If we can't decode, try to create a minimal response
            if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Create fallback response without decoding places (to avoid nested decoding errors)
                let fallbackResponse = ChatAPIResponse(
                    reply: jsonObject["reply"] as? String,
                    places: nil, // Don't try to decode places if main decode failed
                    vibe: jsonObject["vibe"] as? String,
                    weather: nil,
                    error: jsonObject["error"] as? String
                )
                print("⚠️ Using fallback response with reply: \(fallbackResponse.replyText)")
                return fallbackResponse
            }
            
            throw APIError.decodingError(error.localizedDescription)
        }
    }
    
    // MARK: - Quick Recommendations
    nonisolated func getQuickRecommendations(category: String, limit: Int = 10) async throws -> QuickRecsAPIResponse {
        var urlComponents = URLComponents(string: "\(baseURL)/api/quick_recs")!
        urlComponents.queryItems = [
            URLQueryItem(name: "category", value: category),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(QuickRecsAPIResponse.self, from: data)
    }
    
    // MARK: - Directions
    nonisolated func getDirections(lat: Double, lng: Double) async throws -> DirectionsAPIResponse {
        let originLat = 40.693393  // 2 MetroTech
        let originLng = -73.98555
        
        var urlComponents = URLComponents(string: "\(baseURL)/api/directions")!
        urlComponents.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lng", value: String(lng))
        ]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
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
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(EventsAPIResponse.self, from: data)
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError(String)
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

