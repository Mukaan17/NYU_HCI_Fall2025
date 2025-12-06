//
//  ChatViewModel.swift
//  VioletVibes
//

import Foundation
import SwiftUI
import Observation

@Observable
final class ChatViewModel {
    var messages: [ChatMessage] = []
    var isTyping: Bool = false
    
    private let apiService = APIService.shared
    
    init() {
        // Initialize with welcome message - will be updated with user's first name
        messages = [
            ChatMessage(
                id: 1,
                type: .text,
                role: .ai,
                content: "Hey! I'm VioletVibes. Tell me what you're in the mood for — drinks, food, coffee, or something fun.",
                timestamp: Date()
            )
        ]
        
        // Load user's first name and update welcome message
        Task {
            await loadWelcomeMessage()
        }
    }
    
    private func loadWelcomeMessage() async {
        let storage = StorageService.shared
        if let account = await storage.userAccount, !account.firstName.isEmpty {
            let firstName = account.firstName
            await MainActor.run {
                // Update the first message with user's first name
                if !messages.isEmpty {
                    messages[0] = ChatMessage(
                        id: 1,
                        type: .text,
                        role: .ai,
                        content: "Hey \(firstName)! I'm VioletVibes. Tell me what you're in the mood for — drinks, food, coffee, or something fun.",
                        timestamp: messages[0].timestamp
                    )
                }
            }
        }
    }
    
    func sendMessage(
        _ text: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        jwt: String? = nil,
        preferences: UserPreferences? = nil,
        selectedVibe: String? = nil
    ) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(
            id: Int(Date().timeIntervalSince1970),
            type: .text,
            role: .user,
            content: trimmed,
            timestamp: Date()
        )
        
        messages.append(userMessage)
        isTyping = true
        
        do {
            let response = try await apiService.sendChatMessage(
                trimmed,
                latitude: latitude,
                longitude: longitude,
                jwt: jwt,
                preferences: preferences,
                vibe: selectedVibe
            )
            
            await MainActor.run {
                // Always add AI text reply (for both conversational and recommendation messages)
                let aiMessage = ChatMessage(
                    id: Int(Date().timeIntervalSince1970) + 1,
                    type: .text,
                    role: .ai,
                    content: response.replyText,
                    timestamp: Date()
                )
                
                messages.append(aiMessage)
                
                // Only add recommendation cards if places are present and not empty
                // Backend now returns empty array for conversational messages (greetings, follow-ups, etc.)
                // This prevents card displacement for non-recommendation messages
                if let places = response.places, !places.isEmpty {
                    let recommendations = places.enumerated().map { index, place in
                        // Use a unique ID based on timestamp and index to avoid duplicates
                        let uniqueId = Int(Date().timeIntervalSince1970 * 1000) + index
                        return Recommendation(
                            id: place.id != 0 ? place.id : uniqueId,
                            title: place.title,
                            description: place.description,
                            distance: place.distance,
                            walkTime: place.walkTime,
                            lat: place.lat,
                            lng: place.lng,
                            popularity: place.popularity,
                            image: place.image
                        )
                    }
                    
                    let recommendationsMessage = ChatMessage(
                        id: Int(Date().timeIntervalSince1970) + 2,
                        type: .recommendations,
                        role: .ai,
                        content: nil,
                        recommendations: recommendations,
                        timestamp: Date()
                    )
                    
                    messages.append(recommendationsMessage)
                }
                // If places is nil or empty, we only show the text reply (no cards)
                // This is the desired behavior for conversational messages
                
                isTyping = false
            }
        } catch {
            print("Chat error: \(error)")
            print("Error details: \(error.localizedDescription)")
            
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

