//
//  ChatViewModel.swift
//  VioletVibes
//

import Foundation
import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping: Bool = false
    
    private let apiService = APIService.shared
    
    init() {
        // Initialize with welcome message
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
    
    func sendMessage(_ text: String, latitude: Double? = nil, longitude: Double? = nil) async {
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
        
        await MainActor.run {
            messages.append(userMessage)
            isTyping = true
        }
        
        do {
            let response = try await apiService.sendChatMessage(trimmed, latitude: latitude, longitude: longitude)
            
            // Add AI text reply
            let aiMessage = ChatMessage(
                id: Int(Date().timeIntervalSince1970) + 1,
                type: .text,
                role: .ai,
                content: response.reply,
                timestamp: Date()
            )
            
            await MainActor.run {
                messages.append(aiMessage)
            }
            
            // Add recommendations if present
            if let places = response.places, !places.isEmpty {
                let recommendations = places.enumerated().map { index, place in
                    Recommendation(
                        id: index,
                        title: place.title,
                        description: place.description,
                        walkTime: place.walkTime,
                        distance: place.distance,
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
                
                await MainActor.run {
                    messages.append(recommendationsMessage)
                    isTyping = false
                }
            } else {
                await MainActor.run {
                    isTyping = false
                }
            }
        } catch {
            print("Chat error: \(error)")
            let errorMessage = ChatMessage(
                id: Int(Date().timeIntervalSince1970) + 1,
                type: .text,
                role: .ai,
                content: "I'm having trouble connecting right now. Please try again!",
                timestamp: Date()
            )
            
            await MainActor.run {
                messages.append(errorMessage)
                isTyping = false
            }
        }
    }
}

