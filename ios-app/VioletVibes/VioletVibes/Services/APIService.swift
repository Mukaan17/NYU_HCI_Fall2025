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
        if let apiURL = ProcessInfo.processInfo.environment["API_URL"], !apiURL.isEmpty {
            baseURL = apiURL
        } else if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
                  let config = NSDictionary(contentsOfFile: path),
                  let url = config["API_URL"] as? String,
                  !url.isEmpty {
            baseURL = url
        } else {
            baseURL = "http://localhost:5001"
        }
        
        print("🔗 APIService using baseURL → \(baseURL)")
    }
    
    // MARK: - Authentication
    
    nonisolated func signup(email: String, password: String, firstName: String? = nil) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/api/auth/signup") else {
            print("❌ Invalid URL: \(baseURL)/api/auth/signup")
            throw APIError.invalidURL
        }
        
        print("📤 Signup request to: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "email": email,
            "password": password
        ]
        if let firstName = firstName, !firstName.isEmpty {
            body["first_name"] = firstName
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        print("📤 Request body: email=\(email), firstName=\(firstName ?? "nil")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw APIError.invalidResponse
        }
        
        print("📥 Response status: \(http.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Response body: \(responseString.prefix(500))")
        }
        
        // Accept both 200 and 201 for signup (some servers return 200)
        guard http.statusCode == 201 || http.statusCode == 200 else {
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                print("❌ Server error: \(msg)")
                throw APIError.serverError(msg)
            }
            print("❌ Invalid response status: \(http.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("   Full response: \(responseString)")
            }
            throw APIError.invalidResponse
        }
        
        do {
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            print("✅ Signup successful for: \(email)")
            return authResponse
        } catch {
            print("❌ Decoding error: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("   Missing key: \(key.stringValue) at path: \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    print("   Type mismatch: expected \(type) at path: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("   Value not found: \(type) at path: \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("   Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("   Unknown decoding error")
                }
            }
            
            // Try to show what we actually received
            if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("   Received JSON keys: \(Array(jsonObject.keys))")
            }
            
            throw APIError.decodingError(error.localizedDescription)
        }
    }
    
    nonisolated func login(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/api/auth/login") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard http.statusCode == 200 else {
            // Handle rate limiting (429)
            if http.statusCode == 429 {
                throw APIError.serverError("Rate limit exceeded. Please try again in a moment.")
            }
            // Handle authentication errors (401)
            if http.statusCode == 401 {
                throw APIError.serverError("Authentication required. Please log in again.")
            }
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw APIError.serverError(msg)
            }
            throw APIError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode(AuthResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }
    
    // MARK: - Chat
    
    /// Clear the chat session on the backend (starts fresh conversation)
    nonisolated func clearChatSession(jwt: String? = nil) async throws {
        guard let url = URL(string: "\(baseURL)/api/chat") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "X-Clear-Session")
        
        if let token = jwt {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Send a minimal payload to trigger session clear
        let payload: [String: Any] = ["message": "", "clear_session": true]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Accept 200 (session cleared successfully) - backend now handles empty message with clear_session
        if httpResponse.statusCode != 200 {
            throw APIError.invalidResponse
        }
    }
    
    nonisolated func sendChatMessage(
        _ message: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        jwt: String? = nil,
        preferences: UserPreferences? = nil,
        vibe: String? = nil,  // Selected vibe from vibe picker
        clearSession: Bool = false  // Signal to clear previous session context
    ) async throws -> ChatAPIResponse {
        guard let url = URL(string: "\(baseURL)/api/chat") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if clearSession {
            request.setValue("true", forHTTPHeaderField: "X-Clear-Session")
        }
        
        if let token = jwt {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Build request body with optional preferences
        let backendPrefs = preferences?.toBackendPreferencesPayload()
        var payload: [String: Any] = ["message": message]
        if clearSession {
            payload["clear_session"] = true
        }
        if let lat = latitude, let lng = longitude {
            payload["latitude"] = lat
            payload["longitude"] = lng
        }
        if let vibe = vibe {
            payload["vibe"] = vibe
        }
        if let prefs = backendPrefs {
            // Encode preferences to JSON
            if let prefsData = try? JSONEncoder().encode(prefs),
               let prefsDict = try? JSONSerialization.jsonObject(with: prefsData) as? [String: Any] {
                payload["preferences"] = prefsDict
            }
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
    nonisolated func getDirections(
        lat: Double,
        lng: Double,
        originLat: Double? = nil,
        originLng: Double? = nil
    ) async throws -> DirectionsAPIResponse {
        var urlComponents = URLComponents(string: "\(baseURL)/api/directions")!
        var queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lng", value: String(lng))
        ]
        
        // Add origin coordinates if provided
        if let originLat = originLat, let originLng = originLng {
            queryItems.append(URLQueryItem(name: "origin_lat", value: String(originLat)))
            queryItems.append(URLQueryItem(name: "origin_lng", value: String(originLng)))
        }
        
        urlComponents.queryItems = queryItems
        
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
    
    // MARK: - Dashboard
    nonisolated func getDashboard(jwt: String, latitude: Double? = nil, longitude: Double? = nil) async throws -> DashboardAPIResponse {
        var urlComponents = URLComponents(string: "\(baseURL)/api/dashboard")
        
        // Add location parameters if provided
        if let lat = latitude, let lng = longitude {
            urlComponents?.queryItems = [
                URLQueryItem(name: "latitude", value: String(lat)),
                URLQueryItem(name: "longitude", value: String(lng))
            ]
        }
        
        guard let url = urlComponents?.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10.0 // Add timeout to prevent hanging
        
        do {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
            
            // Log response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Dashboard response (\(http.statusCode)): \(responseString.prefix(500))")
            }
        
        guard http.statusCode == 200 else {
                // Handle rate limiting (429)
                if http.statusCode == 429 {
                    throw APIError.serverError("Rate limit exceeded. Please try again in a moment.")
                }
                // Handle authentication errors (401)
                if http.statusCode == 401 {
                    throw APIError.serverError("Authentication required. Please log in again.")
                }
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw APIError.serverError(msg)
            }
            throw APIError.invalidResponse
        }
        
            // Check if data is empty
            guard !data.isEmpty else {
                print("⚠️ Dashboard response is empty")
                throw APIError.decodingError("Empty response from server")
            }
            
            do {
                let decoder = JSONDecoder()
                // Use lenient decoding to handle missing optional fields
                // Note: Don't use convertFromSnakeCase for Weather model as it has custom decoding
                // Weather model expects temp_f, desc, icon in snake_case
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                // Create a custom decoder for Weather that doesn't use snake_case conversion
                let weatherDecoder = JSONDecoder()
                return try decoder.decode(DashboardAPIResponse.self, from: data)
            } catch let decodingError as DecodingError {
                // Provide detailed decoding error information
                print("❌ Dashboard decoding error: \(decodingError)")
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("   Missing key: \(key.stringValue) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .typeMismatch(let type, let context):
                    print("   Type mismatch: expected \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .valueNotFound(let type, let context):
                    print("   Value not found: \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .dataCorrupted(let context):
                    print("   Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("   Unknown decoding error")
                }
                if let responseString = String(data: data, encoding: .utf8) {
                    print("   Response body: \(responseString)")
                }
                throw APIError.decodingError(decodingError.localizedDescription)
            }
        } catch let urlError as URLError {
            // Handle URL errors (including cancellation)
            if urlError.code == .cancelled {
                print("⚠️ Dashboard request was cancelled")
                throw APIError.serverError("Request was cancelled")
            }
            print("❌ Dashboard URL error: \(urlError.localizedDescription)")
            throw APIError.serverError(urlError.localizedDescription)
        }
    }
    
    // MARK: - Top Recommendations
    nonisolated func getTopRecommendations(
        limit: Int = 10,
        jwt: String? = nil,
        preferences: UserPreferences? = nil,
        weather: String? = nil,
        vibe: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) async throws -> [Recommendation] {
        // Use the new top_recommendations endpoint
        var comps = URLComponents(string: "\(baseURL)/api/top_recommendations")!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(min(limit, 10))")  // Max 10 per backend
        ]
        
        // Add weather parameter if provided
        if let weather = weather {
            items.append(URLQueryItem(name: "weather", value: weather))
        }
        
        // Add vibe parameter if provided
        if let vibe = vibe {
            items.append(URLQueryItem(name: "vibe", value: vibe))
        }
        
        // Add location parameters if provided
        if let lat = latitude, let lng = longitude {
            items.append(URLQueryItem(name: "latitude", value: String(lat)))
            items.append(URLQueryItem(name: "longitude", value: String(lng)))
            print("📍 getTopRecommendations: Sending location lat=\(lat), lng=\(lng)")
        } else {
            print("⚠️ getTopRecommendations: No location provided")
        }
        
        comps.queryItems = items
        
        guard let url = comps.url else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = jwt {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard http.statusCode == 200 else {
            // Handle rate limiting (429)
            if http.statusCode == 429 {
                throw APIError.serverError("Rate limit exceeded. Please try again in a moment.")
            }
            // Handle authentication errors (401)
            if http.statusCode == 401 {
                throw APIError.serverError("Authentication required. Please log in again.")
            }
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw APIError.serverError(msg)
            }
            throw APIError.invalidResponse
        }
        
        do {
            // top_recommendations returns { "category": "top", "places": [...] }
            let decoded = try JSONDecoder().decode(QuickRecsAPIResponse.self, from: data)
            return decoded.places
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }
    
    // MARK: - User Profile
    nonisolated func fetchUserProfile(jwt: String) async throws -> UserProfileResponse {
        guard let url = URL(string: "\(baseURL)/api/user/profile") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard http.statusCode == 200 else {
            // Handle rate limiting (429)
            if http.statusCode == 429 {
                throw APIError.serverError("Rate limit exceeded. Please try again in a moment.")
            }
            // Handle authentication errors (401)
            if http.statusCode == 401 {
                throw APIError.serverError("Authentication required. Please log in again.")
            }
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw APIError.serverError(msg)
            }
            throw APIError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode(UserProfileResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }
    
    nonisolated func saveUserProfile(
        firstName: String?,
        homeAddress: String?,
        jwt: String
    ) async throws -> UserProfileResponse {
        guard let url = URL(string: "\(baseURL)/api/user/profile") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var payload: [String: Any] = [:]
        if let firstName = firstName {
            payload["first_name"] = firstName
        }
        if let homeAddress = homeAddress {
            payload["home_address"] = homeAddress
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard http.statusCode == 200 else {
            // Handle rate limiting (429)
            if http.statusCode == 429 {
                throw APIError.serverError("Rate limit exceeded. Please try again in a moment.")
            }
            // Handle authentication errors (401)
            if http.statusCode == 401 {
                throw APIError.serverError("Authentication required. Please log in again.")
            }
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw APIError.serverError(msg)
            }
            throw APIError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode(UserProfileResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }
    
    // MARK: - User Preferences
    nonisolated func fetchUserPreferences(jwt: String) async throws -> BackendPreferencesPayload {
        guard let url = URL(string: "\(baseURL)/api/user/preferences") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard http.statusCode == 200 else {
            // Handle rate limiting (429)
            if http.statusCode == 429 {
                throw APIError.serverError("Rate limit exceeded. Please try again in a moment.")
            }
            // Handle authentication errors (401)
            if http.statusCode == 401 {
                throw APIError.serverError("Authentication required. Please log in again.")
            }
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw APIError.serverError(msg)
            }
            throw APIError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode(BackendPreferencesPayload.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }
    
    nonisolated func saveUserPreferences(
        preferences: UserPreferences,
        jwt: String
    ) async throws -> BackendPreferencesPayload {
        guard let url = URL(string: "\(baseURL)/api/user/preferences") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = preferences.toBackendPreferencesPayload()
        let encoder = JSONEncoder()
        let body = try encoder.encode(payload)
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard http.statusCode == 200 else {
            // Handle rate limiting (429)
            if http.statusCode == 429 {
                throw APIError.serverError("Rate limit exceeded. Please try again in a moment.")
            }
            // Handle authentication errors (401)
            if http.statusCode == 401 {
                throw APIError.serverError("Authentication required. Please log in again.")
            }
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw APIError.serverError(msg)
            }
            throw APIError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode(BackendPreferencesPayload.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }
    
    // MARK: - User Settings
    nonisolated func fetchUserSettings(jwt: String) async throws -> BackendSettingsPayload {
        guard let url = URL(string: "\(baseURL)/api/user/settings") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard http.statusCode == 200 else {
            // Handle rate limiting (429)
            if http.statusCode == 429 {
                throw APIError.serverError("Rate limit exceeded. Please try again in a moment.")
            }
            // Handle authentication errors (401)
            if http.statusCode == 401 {
                throw APIError.serverError("Authentication required. Please log in again.")
            }
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw APIError.serverError(msg)
            }
            throw APIError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode(BackendSettingsPayload.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }
    
    nonisolated func saveUserSettings(
        settings: BackendSettingsPayload,
        jwt: String
    ) async throws -> BackendSettingsPayload {
        guard let url = URL(string: "\(baseURL)/api/user/settings") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        let body = try encoder.encode(settings)
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard http.statusCode == 200 else {
            // Handle rate limiting (429)
            if http.statusCode == 429 {
                throw APIError.serverError("Rate limit exceeded. Please try again in a moment.")
            }
            // Handle authentication errors (401)
            if http.statusCode == 401 {
                throw APIError.serverError("Authentication required. Please log in again.")
            }
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw APIError.serverError(msg)
            }
            throw APIError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode(BackendSettingsPayload.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }
    
    // MARK: - Push Notifications
    nonisolated func registerPushToken(_ token: String, jwt: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/user/notification_token") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: ["token": token])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 else {
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw APIError.serverError(msg)
            }
            throw APIError.invalidResponse
        }
        
        print("✅ Push token registered!")
    }
    
    // MARK: - Calendar
    nonisolated func fetchTodayCalendarEvents(jwt: String) async throws -> CalendarEventsResponse {
        guard let url = URL(string: "\(baseURL)/api/calendar/today") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if http.statusCode != 200 {
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw APIError.serverError(msg)
            }
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(CalendarEventsResponse.self, from: data)
    }
    
    // MARK: - Calendar Notifications
    nonisolated func checkCalendarNotifications(jwt: String) async throws -> NotificationCheckResponse {
        guard let url = URL(string: "\(baseURL)/api/calendar/notifications/check") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if http.statusCode != 200 {
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw APIError.serverError(msg)
            }
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(NotificationCheckResponse.self, from: data)
    }
    
    // MARK: - Calendar Free Time
    nonisolated func getFreeTimeBlocks(jwt: String) async throws -> FreeTimeBlocksResponse {
        guard let url = URL(string: "\(baseURL)/api/calendar/free_time") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard http.statusCode == 200 else {
            // Handle rate limiting (429)
            if http.statusCode == 429 {
                throw APIError.serverError("Rate limit exceeded. Please try again in a moment.")
            }
            // Handle authentication errors (401)
            if http.statusCode == 401 {
                throw APIError.serverError("Authentication required. Please log in again.")
            }
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw APIError.serverError(msg)
            }
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(FreeTimeBlocksResponse.self, from: data)
    }
    
    nonisolated func getNextFreeBlock(jwt: String) async throws -> NextFreeBlockResponse {
        guard let url = URL(string: "\(baseURL)/api/calendar/next_free_block") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard http.statusCode == 200 else {
            // Handle rate limiting (429)
            if http.statusCode == 429 {
                throw APIError.serverError("Rate limit exceeded. Please try again in a moment.")
            }
            // Handle authentication errors (401)
            if http.statusCode == 401 {
                throw APIError.serverError("Authentication required. Please log in again.")
            }
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw APIError.serverError(msg)
            }
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(NextFreeBlockResponse.self, from: data)
    }
    
    nonisolated func getNextFreeWithRecommendation(jwt: String) async throws -> NextFreeRecommendationResponse {
        guard let url = URL(string: "\(baseURL)/api/calendar/next_free") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard http.statusCode == 200 else {
            // Handle rate limiting (429)
            if http.statusCode == 429 {
                throw APIError.serverError("Rate limit exceeded. Please try again in a moment.")
            }
            // Handle authentication errors (401)
            if http.statusCode == 401 {
                throw APIError.serverError("Authentication required. Please log in again.")
            }
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw APIError.serverError(msg)
            }
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(NextFreeRecommendationResponse.self, from: data)
    }
    
    nonisolated func getFullRecommendation(jwt: String) async throws -> FullRecommendationResponse {
        guard let url = URL(string: "\(baseURL)/api/calendar/recommendation") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard http.statusCode == 200 else {
            // Handle rate limiting (429)
            if http.statusCode == 429 {
                throw APIError.serverError("Rate limit exceeded. Please try again in a moment.")
            }
            // Handle authentication errors (401)
            if http.statusCode == 401 {
                throw APIError.serverError("Authentication required. Please log in again.")
            }
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw APIError.serverError(msg)
            }
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(FullRecommendationResponse.self, from: data)
    }
    
    // MARK: - User Activity
    nonisolated func logUserActivity(
        type: String,
        placeId: String? = nil,
        name: String? = nil,
        vibe: String? = nil,
        score: Double? = nil,
        jwt: String
    ) async throws {
        guard let url = URL(string: "\(baseURL)/api/user/activity") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        
        var payload: [String: Any] = ["type": type]
        if let placeId = placeId {
            payload["place_id"] = placeId
        }
        if let name = name {
            payload["name"] = name
        }
        if let vibe = vibe {
            payload["vibe"] = vibe
        }
        if let score = score {
            payload["score"] = score
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 else {
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw APIError.serverError(msg)
            }
            throw APIError.invalidResponse
        }
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
            return message
        }
    }
}

