//
//  CalendarService.swift
//  VioletVibes
//

import Foundation

actor CalendarService {
    static let shared = CalendarService()

    private init() {}

    // MARK: - Fetch Next Free Time Block
    func fetchNextFree(jwt: String) async throws -> NextFreeResponse {
        guard let url = URL(string: "\(APIService.serverURL)/api/calendar/next_free") else {
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
            // Try to pull a message from server JSON
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = json["error"] as? String {
                throw APIError.serverError(msg)
            }
            throw APIError.invalidResponse
        }

        return try JSONDecoder().decode(NextFreeResponse.self, from: data)
    }

    // MARK: - Fetch Free Blocks (optional helper)
    func fetchFreeBlocks(jwt: String) async throws -> FreeBlocksResponse {
        guard let url = URL(string: "\(APIService.serverURL)/api/calendar/free_time") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        return try JSONDecoder().decode(FreeBlocksResponse.self, from: data)
    }
}

// MARK: - Backend DTOs

struct NextFreeResponse: Codable {
    let has_free_time: Bool
    let next_free: FreeBlock?
    let suggestion: Recommendation?
    let suggestion_type: String?
    let message: String
}

struct FreeBlocksResponse: Codable {
    let free_blocks: [FreeBlock]
}

struct FreeBlock: Codable {
    let start: String
    let end: String
}

