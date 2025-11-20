//
//  APIService.swift
//  VioletVibes
//

import Foundation

class APIService {
    static let shared = APIService()
    
    private let baseURL: String
    
    private init() {
        // Get base URL from environment or use default
        if let apiURL = ProcessInfo.processInfo.environment["API_URL"] {
            baseURL = apiURL
        } else if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
                  let config = NSDictionary(contentsOfFile: path),
                  let url = config["API_URL"] as? String {
            baseURL = url
        } else {
            baseURL = "http://localhost:5000"
        }
    }
    
    // MARK: - Chat
    func sendChatMessage(_ message: String, latitude: Double? = nil, longitude: Double? = nil) async throws -> ChatAPIResponse {
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
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let apiResponse = try decoder.decode(ChatAPIResponse.self, from: data)
            return apiResponse
        } catch {
            // Try to decode error message
            if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMsg = errorDict["error"] as? String {
                throw APIError.serverError(errorMsg)
            }
            throw APIError.decodingError(error.localizedDescription)
        }
    }
    
    // MARK: - Quick Recommendations
    func getQuickRecommendations(category: String, limit: Int = 10) async throws -> QuickRecsAPIResponse {
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
    func getDirections(lat: Double, lng: Double) async throws -> DirectionsAPIResponse {
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
    func getEvents() async throws -> EventsAPIResponse {
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

