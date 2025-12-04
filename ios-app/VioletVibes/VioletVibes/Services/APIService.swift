//
//  APIService.swift
//  VioletVibes
//

import Foundation

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError(String)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .decodingError(let msg): return "Decoding error: \(msg)"
        case .serverError(let msg): return "Server error: \(msg)"
        }
    }
}

// MARK: - Shared DTOs (Auth, etc.)
struct DashboardAPIResponse: Codable, Sendable {
    let weather: Weather?
    let calendar_linked: Bool?
    let next_free: String?
    let free_time_suggestion: String?
    let quick_recommendations: [String: [Recommendation]]?
}

struct AuthUserPayload: Codable, Sendable {
    let id: Int
    let email: String
    let preferences: BackendPreferencesPayload?
    let settings: BackendSettingsPayload?
}

struct AuthResponse: Codable, Sendable {
    let token: String
    let user: AuthUserPayload
}

// Chat request with optional preferences
private struct ChatRequestBody: Codable, Sendable {
    let message: String
    let latitude: Double?
    let longitude: Double?
    let preferences: BackendPreferencesPayload?
}

// Wrapper for top recs
private struct TopWrapper: Codable, Sendable {
    let places: [Recommendation]
}

// NOTE: Backend DTOs for prefs/settings are defined in UserPreferences.swift:
// - BackendBudgetPayload
// - BackendPreferencesPayload
// - BackendSettingsPayload

// MARK: - APIService Actor

actor APIService {
    static let shared = APIService()

    public static var serverURL: String {
        APIService.shared.baseURL
    }

    private let baseURL: String

    // Swift 6 actor-safe init
    init() {
        if let apiURL = ProcessInfo.processInfo.environment["API_URL"], !apiURL.isEmpty {
            baseURL = apiURL
        } else if
            let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
            let config = NSDictionary(contentsOfFile: path),
            let url = config["API_URL"] as? String,
            !url.isEmpty {
            baseURL = url
        } else {
            baseURL = "http://localhost:5001"
        }

        print("🔗 APIService using baseURL → \(baseURL)")
    }

    // ----------------------------------------------------------
    // MARK: - AUTH
    // ----------------------------------------------------------

    func signup(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/api/auth/signup") else {
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

        guard http.statusCode == 201 else {
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

    func login(email: String, password: String) async throws -> AuthResponse {
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

    // ----------------------------------------------------------
    // MARK: - CHAT
    // ----------------------------------------------------------

    func sendChatMessage(
        _ message: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        jwt: String? = nil,
        preferences: UserPreferences? = nil
    ) async throws -> ChatAPIResponse {

        guard let url = URL(string: "\(baseURL)/api/chat") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = jwt {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let backendPrefs = preferences?.toBackendPreferencesPayload()
        let body = ChatRequestBody(
            message: message,
            latitude: latitude,
            longitude: longitude,
            preferences: backendPrefs
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard http.statusCode == 200 else {
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw APIError.serverError(msg)
            }
            throw APIError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(ChatAPIResponse.self, from: data)
        } catch {
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw APIError.serverError(msg)
            }
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    // ----------------------------------------------------------
    // MARK: - PUBLIC WEATHER (NO AUTH REQUIRED)
    // ----------------------------------------------------------
    func getPublicWeather() async throws -> Weather {
        guard let url = URL(string: "\(baseURL)/api/weather") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(Weather.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    // ----------------------------------------------------------
    // MARK: - DASHBOARD
    // ----------------------------------------------------------
    func getDashboard(jwt: String) async throws -> DashboardAPIResponse {
        guard let url = URL(string: "\(baseURL)/api/dashboard") else {
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
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let msg = dict["error"] as? String {
                throw APIError.serverError(msg)
            }
            throw APIError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(DashboardAPIResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }


    // ----------------------------------------------------------
    // MARK: - QUICK RECOMMENDATIONS
    // ----------------------------------------------------------

    func getQuickRecommendations(category: String, limit: Int = 10) async throws -> QuickRecsAPIResponse {
        var comps = URLComponents(string: "\(baseURL)/api/quick_recs")!
        comps.queryItems = [
            .init(name: "category", value: category),
            .init(name: "limit", value: "\(limit)")
        ]

        guard let url = comps.url else { throw APIError.invalidURL }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        return try JSONDecoder().decode(QuickRecsAPIResponse.self, from: data)
    }

    // ----------------------------------------------------------
    // MARK: - TOP RECOMMENDATIONS
    // ----------------------------------------------------------

    /// Backend route uses JWT to find user & prefs; we only pass limit (+ optional weather).
    func getTopRecommendations(
        limit: Int = 3,
        jwt: String? = nil,
        preferences: UserPreferences? = nil, // currently unused, kept for API symmetry
        weather: String? = nil
    ) async throws -> [Recommendation] {

        var comps = URLComponents(string: "\(baseURL)/api/top_recommendations")!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        if let w = weather, !w.isEmpty {
            items.append(URLQueryItem(name: "weather", value: w))
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
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = dict["error"] as? String {
                throw APIError.serverError(msg)
            }
            throw APIError.invalidResponse
        }

        do {
            let decoded = try JSONDecoder().decode(TopWrapper.self, from: data)
            return decoded.places
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    // ----------------------------------------------------------
    // MARK: - USER PREFERENCES (DB)
    // ----------------------------------------------------------

    func fetchUserPreferences(jwt: String) async throws -> BackendPreferencesPayload {
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

    func saveUserPreferences(
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

    // ----------------------------------------------------------
    // MARK: - USER SETTINGS (DB)
    // ----------------------------------------------------------

    func fetchUserSettings(jwt: String) async throws -> BackendSettingsPayload {
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

    func saveUserSettings(
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

    // ----------------------------------------------------------
    // MARK: - DIRECTIONS
    // ----------------------------------------------------------
    func getDirections(lat: Double, lng: Double) async throws -> DirectionsAPIResponse {
        var comps = URLComponents(string: "\(baseURL)/api/directions")!
        comps.queryItems = [
            .init(name: "lat", value: "\(lat)"),
            .init(name: "lng", value: "\(lng)")
        ]

        guard let url = comps.url else { throw APIError.invalidURL }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse,
            http.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        return try JSONDecoder().decode(DirectionsAPIResponse.self, from: data)
    }

    // ----------------------------------------------------------
    // MARK: - EVENTS
    // ----------------------------------------------------------

    func getEvents() async throws -> EventsAPIResponse {
        guard let url = URL(string: "\(baseURL)/api/events") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        return try JSONDecoder().decode(EventsAPIResponse.self, from: data)
    }

    // ----------------------------------------------------------
    // MARK: - PUSH NOTIFICATIONS
    // ----------------------------------------------------------

    func registerPushToken(_ token: String, jwt: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/notifications/register_token") else {
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
}

// MARK: - Global Helper

func registerPushToken(_ token: String, jwt: String) async throws {
    try await APIService.shared.registerPushToken(token, jwt: jwt)
}
