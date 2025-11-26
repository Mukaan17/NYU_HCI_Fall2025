//
//  UserAccount.swift
//  VioletVibes
//

import Foundation

struct UserAccount: Codable, Equatable {
    var email: String
    var firstName: String
    var hasLoggedIn: Bool
    
    init(email: String, firstName: String, hasLoggedIn: Bool = false) {
        self.email = email
        self.firstName = firstName
        self.hasLoggedIn = hasLoggedIn
    }
}

