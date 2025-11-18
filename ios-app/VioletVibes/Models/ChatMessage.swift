//
//  ChatMessage.swift
//  VioletVibes
//

import Foundation

enum ChatMessageType {
    case text
    case recommendations
}

enum ChatMessageRole {
    case user
    case ai
}

struct ChatMessage: Identifiable, Codable {
    let id: Int
    let type: ChatMessageType
    let role: ChatMessageRole
    var content: String?
    var recommendations: [Recommendation]?
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id, type, role, content, recommendations, timestamp
    }
    
    init(id: Int, type: ChatMessageType, role: ChatMessageRole, content: String? = nil, recommendations: [Recommendation]? = nil, timestamp: Date = Date()) {
        self.id = id
        self.type = type
        self.role = role
        self.content = content
        self.recommendations = recommendations
        self.timestamp = timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        
        // Handle timestamp - could be Date, Double, or String
        if let date = try? container.decode(Date.self, forKey: .timestamp) {
            timestamp = date
        } else if let timeInterval = try? container.decode(Double.self, forKey: .timestamp) {
            timestamp = Date(timeIntervalSince1970: timeInterval)
        } else {
            timestamp = Date()
        }
        
        let typeString = try container.decode(String.self, forKey: .type)
        type = typeString == "recommendations" ? .recommendations : .text
        
        let roleString = try container.decode(String.self, forKey: .role)
        role = roleString == "user" ? .user : .ai
        
        if type == .text {
            content = try container.decodeIfPresent(String.self, forKey: .content)
        } else {
            recommendations = try container.decodeIfPresent([Recommendation].self, forKey: .recommendations)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(type == .recommendations ? "recommendations" : "text", forKey: .type)
        try container.encode(role == .user ? "user" : "ai", forKey: .role)
        try container.encodeIfPresent(content, forKey: .content)
        try container.encodeIfPresent(recommendations, forKey: .recommendations)
    }
}

