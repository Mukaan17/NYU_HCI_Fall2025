//
//  ChatViewModel.swift
//  VioletVibes
//

import Foundation
import SwiftUI
import Observation

@Observable
final class ChatViewModel {

    // MARK: - UI State
    var messages: [ChatMessage] = []
    var isTyping: Bool = false

    private let apiService = APIService.shared

    // MARK: - Init (welcome)
    init() {
        messages = [
            ChatMessage(
                id: 1,
                type: .text,
                role: .ai,
                content: "Hey Tandon! I'm VioletVibes. Tell me what you're in the mood for — drinks, food, coffee, or something fun.",
                timestamp: Date()
            )
        ]
    }

    // MARK: - Main Send Function
    func sendMessage(
        _ text: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        session: UserSession,
        preferences: UserPreferences
    ) async {

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // ------------------------------------------
        // Add USER message
        // ------------------------------------------
        let userMessage = ChatMessage(
            id: Int(Date().timeIntervalSince1970),
            type: .text,
            role: .user,
            content: trimmed,
            timestamp: Date()
        )

        messages.append(userMessage)
        isTyping = true

        // ------------------------------------------
        // Call BACKEND
        // ------------------------------------------
        do {
            let response = try await apiService.sendChatMessage(
                trimmed,
                latitude: latitude,
                longitude: longitude,
                jwt: session.jwt
            )

            // ------------------------------------------
            // Add AI response
            // ------------------------------------------
            await MainActor.run {

                let aiMessage = ChatMessage(
                    id: Int(Date().timeIntervalSince1970) + 1,
                    type: .text,
                    role: .ai,
                    content: response.replyText,
                    timestamp: Date()
                )
                messages.append(aiMessage)

                // ------------------------------------------
                // Include recommendations
                // ------------------------------------------
                if let places = response.places, !places.isEmpty {

                    let timestamp = Int(Date().timeIntervalSince1970 * 1000)

                    let recommendations: [Recommendation] = places.enumerated().map { idx, p in
                        Recommendation(
                            id: "chat-\(timestamp)-\(idx)",
                            title: p.title,
                            description: p.description,
                            distance: p.distance,
                            walkTime: p.walkTime,
                            lat: p.lat,
                            lng: p.lng,
                            popularity: p.popularity,
                            image: p.image,
                            busyness: p.busyness,
                            rating: p.rating,
                            score: p.score,
                            mapsLink: p.mapsLink,
                            type: p.type,
                            source: p.source
                        )
                    }

                    let recMessage = ChatMessage(
                        id: Int(Date().timeIntervalSince1970) + 2,
                        type: .recommendations,
                        role: .ai,
                        recommendations: recommendations,
                        timestamp: Date()
                    )

                    messages.append(recMessage)
                }

                isTyping = false
            }

        } catch {
            print("Chat error:", error)
            await MainActor.run {
                let errorMessage = ChatMessage(
                    id: Int(Date().timeIntervalSince1970) + 1,
                    type: .text,
                    role: .ai,
                    content: "I'm having trouble connecting right now. Please try again!",
                    timestamp: Date()
                )
                messages.append(errorMessage)
                isTyping = false
            }
        }
    }
}
