//
//  StorageService.swift
//  VioletVibes
//

import Foundation

enum StorageError: LocalizedError {
    case duplicateContact(String)
    
    var errorDescription: String? {
        switch self {
        case .duplicateContact(let message):
            return message
        }
    }
}

actor StorageService {
    static let shared = StorageService()
    
    nonisolated private let userDefaults = UserDefaults.standard
    
    private enum Keys {
        static let hasSeenWelcome = "hasSeenWelcome"
        static let hasCompletedPermissions = "hasCompletedPermissions"
        static let hasLoggedIn = "hasLoggedIn"
        static let hasCompletedOnboardingSurvey = "hasCompletedOnboardingSurvey"
        static let hasCompletedCalendarOAuth = "hasCompletedCalendarOAuth"
        static let homeAddress = "homeAddress"
        static let trustedContacts = "trustedContacts"
        static let userAccount = "userAccount"
        static let userPreferences = "userPreferences"
        
        // Session storage
        static let userSession = "vv_user_session"   // stores jwt + googleCalendarLinked
    }
    
    nonisolated private init() {}
    
    // MARK: - Welcome
    var hasSeenWelcome: Bool {
        get { userDefaults.bool(forKey: Keys.hasSeenWelcome) }
    }
    
    func setHasSeenWelcome(_ value: Bool) {
        userDefaults.set(value, forKey: Keys.hasSeenWelcome)
    }
    
    // MARK: - Permissions
    var hasCompletedPermissions: Bool {
        get { userDefaults.bool(forKey: Keys.hasCompletedPermissions) }
    }
    
    func setHasCompletedPermissions(_ value: Bool) {
        userDefaults.set(value, forKey: Keys.hasCompletedPermissions)
    }
    
    // MARK: - Login
    var hasLoggedIn: Bool {
        get { userDefaults.bool(forKey: Keys.hasLoggedIn) }
    }
    
    func setHasLoggedIn(_ value: Bool) {
        userDefaults.set(value, forKey: Keys.hasLoggedIn)
    }
    
    // MARK: - Onboarding Survey (User-Specific)
    var hasCompletedOnboardingSurvey: Bool {
        get {
            // Get user-specific onboarding survey completion status
            guard let userAccount = userAccount else {
                return false
            }
            let userKey = "\(Keys.hasCompletedOnboardingSurvey)_\(userAccount.email)"
            return userDefaults.bool(forKey: userKey)
        }
    }
    
    func setHasCompletedOnboardingSurvey(_ value: Bool) {
        // Get user-specific onboarding survey completion status key
        guard let userAccount = userAccount else {
            return // Can't save without a user account
        }
        let userKey = "\(Keys.hasCompletedOnboardingSurvey)_\(userAccount.email)"
        userDefaults.set(value, forKey: userKey)
    }
    
    /// Clear onboarding survey status for the current user (used during logout)
    func clearCurrentUserOnboardingStatus() {
        if let userAccount = userAccount {
            let userKey = "\(Keys.hasCompletedOnboardingSurvey)_\(userAccount.email)"
            userDefaults.removeObject(forKey: userKey)
        }
        // Also clear legacy global onboarding status if it exists
        userDefaults.removeObject(forKey: Keys.hasCompletedOnboardingSurvey)
    }
    
    /// Clear onboarding survey status for all users (used during reset)
    func clearAllOnboardingStatuses() {
        // Remove all onboarding survey keys (in case of migration)
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys {
            if key.hasPrefix(Keys.hasCompletedOnboardingSurvey + "_") {
                userDefaults.removeObject(forKey: key)
            }
        }
        // Also clear legacy global onboarding status
        userDefaults.removeObject(forKey: Keys.hasCompletedOnboardingSurvey)
    }
    
    // MARK: - Calendar OAuth (User-Specific)
    var hasCompletedCalendarOAuth: Bool {
        get {
            // Get user-specific calendar OAuth completion status
            guard let userAccount = userAccount else {
                return false
            }
            let userKey = "\(Keys.hasCompletedCalendarOAuth)_\(userAccount.email)"
            return userDefaults.bool(forKey: userKey)
        }
    }
    
    func setHasCompletedCalendarOAuth(_ value: Bool) {
        // Get user-specific calendar OAuth completion status key
        guard let userAccount = userAccount else {
            return // Can't save without a user account
        }
        let userKey = "\(Keys.hasCompletedCalendarOAuth)_\(userAccount.email)"
        userDefaults.set(value, forKey: userKey)
    }
    
    // MARK: - Reset Onboarding
    func resetOnboarding() {
        userDefaults.removeObject(forKey: Keys.hasSeenWelcome)
        userDefaults.removeObject(forKey: Keys.hasCompletedPermissions)
        userDefaults.removeObject(forKey: Keys.hasLoggedIn)
        userDefaults.removeObject(forKey: Keys.hasCompletedOnboardingSurvey)
        userDefaults.removeObject(forKey: Keys.userAccount)
        userDefaults.removeObject(forKey: Keys.userPreferences)
        userDefaults.removeObject(forKey: Keys.userSession)
        // Clear user-specific home address
        clearAllHomeAddresses()
        // Also clear legacy global home address if it exists
        userDefaults.removeObject(forKey: Keys.homeAddress)
    }
    
    // MARK: - Home Address (User-Specific)
    var homeAddress: String? {
        get {
            // Get user-specific home address key
            guard let userAccount = userAccount else {
                return nil
            }
            let userKey = "\(Keys.homeAddress)_\(userAccount.email)"
            return userDefaults.string(forKey: userKey)
        }
    }
    
    func setHomeAddress(_ address: String?) {
        // Get user-specific home address key
        guard let userAccount = userAccount else {
            return // Can't save address without a user account
        }
        let userKey = "\(Keys.homeAddress)_\(userAccount.email)"
        
        if let address = address {
            userDefaults.set(address, forKey: userKey)
        } else {
            userDefaults.removeObject(forKey: userKey)
        }
    }
    
    /// Clear home address for the current user (used during logout)
    func clearCurrentUserHomeAddress() {
        if let userAccount = userAccount {
            let userKey = "\(Keys.homeAddress)_\(userAccount.email)"
            userDefaults.removeObject(forKey: userKey)
        }
        // Also clear legacy global home address if it exists
        userDefaults.removeObject(forKey: Keys.homeAddress)
    }
    
    /// Clear home address for all users (used during reset)
    func clearAllHomeAddresses() {
        // Remove all home address keys (in case of migration)
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys {
            if key.hasPrefix(Keys.homeAddress + "_") {
                userDefaults.removeObject(forKey: key)
            }
        }
        // Also clear legacy global home address
        userDefaults.removeObject(forKey: Keys.homeAddress)
    }
    
    // MARK: - Trusted Contacts
    var trustedContacts: [TrustedContact] {
        get {
            guard let data = userDefaults.data(forKey: Keys.trustedContacts),
                  let contacts = try? JSONDecoder().decode([TrustedContact].self, from: data) else {
                return []
            }
            return contacts
        }
    }
    
    func setTrustedContacts(_ contacts: [TrustedContact]) {
        if let data = try? JSONEncoder().encode(contacts) {
            userDefaults.set(data, forKey: Keys.trustedContacts)
        } else {
            userDefaults.removeObject(forKey: Keys.trustedContacts)
        }
    }
    
    func addTrustedContact(_ contact: TrustedContact) throws {
        var contacts = trustedContacts
        
        // Check for duplicate ID
        if contacts.contains(where: { $0.id == contact.id }) {
            throw StorageError.duplicateContact("Contact with this ID already exists")
        }
        
        // Check for duplicate phone number (if provided)
        if let phoneNumber = contact.phoneNumber, !phoneNumber.isEmpty {
            let normalizedPhone = normalizePhoneNumber(phoneNumber)
            if contacts.contains(where: { existingContact in
                if let existingPhone = existingContact.phoneNumber, !existingPhone.isEmpty {
                    return normalizePhoneNumber(existingPhone) == normalizedPhone
                }
                return false
            }) {
                throw StorageError.duplicateContact("A contact with this phone number already exists")
            }
        }
        
        // Check for duplicate email (if provided)
        if let email = contact.email, !email.isEmpty {
            let normalizedEmail = email.lowercased().trimmingCharacters(in: CharacterSet.whitespaces)
            if contacts.contains(where: { existingContact in
                if let existingEmail = existingContact.email, !existingEmail.isEmpty {
                    return existingEmail.lowercased().trimmingCharacters(in: CharacterSet.whitespaces) == normalizedEmail
                }
                return false
            }) {
                throw StorageError.duplicateContact("A contact with this email already exists")
            }
        }
        
        // If we get here, no duplicates found - add the contact
        contacts.append(contact)
        setTrustedContacts(contacts)
    }
    
    /// Normalizes phone number by removing non-digit characters for comparison
    private func normalizePhoneNumber(_ phone: String) -> String {
        return phone.filter { $0.isNumber }
    }
    
    func removeTrustedContact(_ id: UUID) {
        var contacts = trustedContacts
        contacts.removeAll { $0.id == id }
        setTrustedContacts(contacts)
    }
    
    // MARK: - User Account (User-Specific)
    var userAccount: UserAccount? {
        get {
            // Try to get current user account from global key first (for backward compatibility)
            if let data = userDefaults.data(forKey: Keys.userAccount),
               let account = try? JSONDecoder().decode(UserAccount.self, from: data) {
                return account
            }
            return nil
        }
    }
    
    func saveUserAccount(_ account: UserAccount) {
        if let data = try? JSONEncoder().encode(account) {
            // Save to global key (current user)
            userDefaults.set(data, forKey: Keys.userAccount)
            
            // Migrate old global home address to user-specific key if it exists
            if let oldAddress = userDefaults.string(forKey: Keys.homeAddress), !oldAddress.isEmpty {
                let userKey = "\(Keys.homeAddress)_\(account.email)"
                userDefaults.set(oldAddress, forKey: userKey)
                // Remove old global key
                userDefaults.removeObject(forKey: Keys.homeAddress)
            }
            
            // Migrate old global onboarding survey status to user-specific key if it exists
            let oldOnboardingStatus = userDefaults.bool(forKey: Keys.hasCompletedOnboardingSurvey)
            if oldOnboardingStatus {
                let userKey = "\(Keys.hasCompletedOnboardingSurvey)_\(account.email)"
                userDefaults.set(true, forKey: userKey)
                // Remove old global key
                userDefaults.removeObject(forKey: Keys.hasCompletedOnboardingSurvey)
            }
        } else {
            userDefaults.removeObject(forKey: Keys.userAccount)
        }
    }
    
    // MARK: - User Preferences (User-Specific)
    var userPreferences: UserPreferences {
        get {
            // Get user-specific preferences
            guard let userAccount = userAccount else {
                return UserPreferences() // Return default if no user account
            }
            let userKey = "\(Keys.userPreferences)_\(userAccount.email)"
            
            guard let data = userDefaults.data(forKey: userKey),
                  let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
                // Try legacy global key for backward compatibility
                if let data = userDefaults.data(forKey: Keys.userPreferences),
                   let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
                    // Migrate to user-specific key
                    if let migratedData = try? JSONEncoder().encode(preferences) {
                        userDefaults.set(migratedData, forKey: userKey)
                        userDefaults.removeObject(forKey: Keys.userPreferences)
                    }
                    return preferences
                }
                return UserPreferences()
            }
            return preferences
        }
    }
    
    func saveUserPreferences(_ preferences: UserPreferences) {
        // Get user-specific preferences key
        guard let userAccount = userAccount else {
            return // Can't save preferences without a user account
        }
        let userKey = "\(Keys.userPreferences)_\(userAccount.email)"
        
        if let data = try? JSONEncoder().encode(preferences) {
            userDefaults.set(data, forKey: userKey)
            // Also remove legacy global key if it exists
            userDefaults.removeObject(forKey: Keys.userPreferences)
        } else {
            userDefaults.removeObject(forKey: userKey)
        }
    }
    
    /// Clear preferences for the current user (used during logout)
    func clearCurrentUserPreferences() {
        if let userAccount = userAccount {
            let userKey = "\(Keys.userPreferences)_\(userAccount.email)"
            userDefaults.removeObject(forKey: userKey)
        }
        // Also clear legacy global preferences if they exist
        userDefaults.removeObject(forKey: Keys.userPreferences)
    }
    
    // MARK: - Session Storage (jwt + googleCalendarLinked)
    
    func saveUserSession(_ session: UserSession) {
        let dict: [String: Any] = [
            "jwt": session.jwt ?? "",
            "googleCalendarLinked": session.googleCalendarLinked
        ]
        userDefaults.set(dict, forKey: Keys.userSession)
    }
    
    func loadUserSession() -> UserSession {
        let session = UserSession()
        
        if let dict = userDefaults.dictionary(forKey: Keys.userSession) {
            session.jwt = dict["jwt"] as? String
            session.googleCalendarLinked = dict["googleCalendarLinked"] as? Bool ?? false
        }
        
        return session
    }
}

