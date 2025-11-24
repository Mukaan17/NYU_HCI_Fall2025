//
//  TrustedContact.swift
//  VioletVibes
//

import Foundation

struct TrustedContact: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var phoneNumber: String?
    var email: String?
    
    init(id: UUID = UUID(), name: String, phoneNumber: String? = nil, email: String? = nil) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
    }
    
    // MARK: - Helper Methods
    
    /// Returns the primary contact identifier (phone number if available, otherwise email)
    var primaryIdentifier: String? {
        return phoneNumber ?? email
    }
    
    /// Returns formatted display string for the contact
    var displayInfo: String {
        var parts: [String] = []
        if let phone = phoneNumber {
            parts.append(phone)
        }
        if let email = email {
            parts.append(email)
        }
        return parts.joined(separator: " • ")
    }
    
    /// Returns true if contact has at least one contact method
    var hasContactMethod: Bool {
        return phoneNumber != nil || email != nil
    }
}

