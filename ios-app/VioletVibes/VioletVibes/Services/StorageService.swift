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
    
    // MARK: - Welcome (User-Specific)
    var hasSeenWelcome: Bool {
        get {
            // Get user-specific welcome status
            guard let userAccount = userAccount else {
                // Fallback to global key for backward compatibility
                return userDefaults.bool(forKey: Keys.hasSeenWelcome)
            }
            let userKey = "\(Keys.hasSeenWelcome)_\(userAccount.email)"
            // Check user-specific key first, then fallback to global
            if userDefaults.object(forKey: userKey) != nil {
                return userDefaults.bool(forKey: userKey)
            }
            // Migrate global to user-specific if exists
            let globalValue = userDefaults.bool(forKey: Keys.hasSeenWelcome)
            if globalValue {
                userDefaults.set(true, forKey: userKey)
                userDefaults.removeObject(forKey: Keys.hasSeenWelcome)
            }
            return globalValue
        }
    }
    
    func setHasSeenWelcome(_ value: Bool) {
        guard let userAccount = userAccount else {
            // Fallback to global key if no user account
            userDefaults.set(value, forKey: Keys.hasSeenWelcome)
            return
        }
        let userKey = "\(Keys.hasSeenWelcome)_\(userAccount.email)"
        userDefaults.set(value, forKey: userKey)
        // Clear global key to prevent leakage
        userDefaults.removeObject(forKey: Keys.hasSeenWelcome)
    }
    
    // MARK: - Permissions (User-Specific)
    var hasCompletedPermissions: Bool {
        get {
            // Get user-specific permissions status
            guard let userAccount = userAccount else {
                // Fallback to global key for backward compatibility
                return userDefaults.bool(forKey: Keys.hasCompletedPermissions)
            }
            let userKey = "\(Keys.hasCompletedPermissions)_\(userAccount.email)"
            // Check user-specific key first, then fallback to global
            if userDefaults.object(forKey: userKey) != nil {
                return userDefaults.bool(forKey: userKey)
            }
            // Migrate global to user-specific if exists
            let globalValue = userDefaults.bool(forKey: Keys.hasCompletedPermissions)
            if globalValue {
                userDefaults.set(true, forKey: userKey)
                userDefaults.removeObject(forKey: Keys.hasCompletedPermissions)
            }
            return globalValue
        }
    }
    
    func setHasCompletedPermissions(_ value: Bool) {
        guard let userAccount = userAccount else {
            // Fallback to global key if no user account
            userDefaults.set(value, forKey: Keys.hasCompletedPermissions)
            return
        }
        let userKey = "\(Keys.hasCompletedPermissions)_\(userAccount.email)"
        userDefaults.set(value, forKey: userKey)
        // Clear global key to prevent leakage
        userDefaults.removeObject(forKey: Keys.hasCompletedPermissions)
    }
    
    // MARK: - Login (Global - indicates if ANY user is logged in)
    // This is kept global as it's a simple boolean flag for app state
    // The actual user identity is stored in userAccount and session
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
    
    // MARK: - Reset Onboarding (Clear all user-specific data)
    func resetOnboarding() {
        // Clear all user-specific data
        clearAllWelcomeStatuses()
        clearAllPermissionsStatuses()
        clearAllOnboardingStatuses()
        clearAllCalendarOAuthStatuses()
        clearAllHomeAddresses()
        clearAllTrustedContacts()
        clearAllUserPreferences()
        
        // Clear global flags
        userDefaults.removeObject(forKey: Keys.hasLoggedIn)
        userDefaults.removeObject(forKey: Keys.userAccount)
        userDefaults.removeObject(forKey: Keys.userSession)
        
        // Clear legacy global keys
        userDefaults.removeObject(forKey: Keys.hasSeenWelcome)
        userDefaults.removeObject(forKey: Keys.hasCompletedPermissions)
        userDefaults.removeObject(forKey: Keys.hasCompletedOnboardingSurvey)
        userDefaults.removeObject(forKey: Keys.userPreferences)
        userDefaults.removeObject(forKey: Keys.homeAddress)
        userDefaults.removeObject(forKey: Keys.trustedContacts)
    }
    
    /// Clear welcome status for the current user
    func clearCurrentUserWelcomeStatus() {
        if let userAccount = userAccount {
            let userKey = "\(Keys.hasSeenWelcome)_\(userAccount.email)"
            userDefaults.removeObject(forKey: userKey)
        }
        userDefaults.removeObject(forKey: Keys.hasSeenWelcome)
    }
    
    /// Clear welcome status for all users
    func clearAllWelcomeStatuses() {
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys {
            if key.hasPrefix(Keys.hasSeenWelcome + "_") {
                userDefaults.removeObject(forKey: key)
            }
        }
        userDefaults.removeObject(forKey: Keys.hasSeenWelcome)
    }
    
    /// Clear permissions status for the current user
    func clearCurrentUserPermissionsStatus() {
        if let userAccount = userAccount {
            let userKey = "\(Keys.hasCompletedPermissions)_\(userAccount.email)"
            userDefaults.removeObject(forKey: userKey)
        }
        userDefaults.removeObject(forKey: Keys.hasCompletedPermissions)
    }
    
    /// Clear permissions status for all users
    func clearAllPermissionsStatuses() {
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys {
            if key.hasPrefix(Keys.hasCompletedPermissions + "_") {
                userDefaults.removeObject(forKey: key)
            }
        }
        userDefaults.removeObject(forKey: Keys.hasCompletedPermissions)
    }
    
    /// Clear calendar OAuth status for the current user
    func clearCurrentUserCalendarOAuthStatus() {
        if let userAccount = userAccount {
            let userKey = "\(Keys.hasCompletedCalendarOAuth)_\(userAccount.email)"
            userDefaults.removeObject(forKey: userKey)
        }
        userDefaults.removeObject(forKey: Keys.hasCompletedCalendarOAuth)
    }
    
    /// Clear calendar OAuth status for all users
    func clearAllCalendarOAuthStatuses() {
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys {
            if key.hasPrefix(Keys.hasCompletedCalendarOAuth + "_") {
                userDefaults.removeObject(forKey: key)
            }
        }
        userDefaults.removeObject(forKey: Keys.hasCompletedCalendarOAuth)
    }
    
    /// Clear preferences for all users
    func clearAllUserPreferences() {
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys {
            if key.hasPrefix(Keys.userPreferences + "_") {
                userDefaults.removeObject(forKey: key)
            }
        }
        userDefaults.removeObject(forKey: Keys.userPreferences)
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
    
    // MARK: - Trusted Contacts (User-Specific)
    var trustedContacts: [TrustedContact] {
        get {
            // Get user-specific trusted contacts
            guard let userAccount = userAccount else {
                // Fallback to global key for backward compatibility
                if let data = userDefaults.data(forKey: Keys.trustedContacts),
                   let contacts = try? JSONDecoder().decode([TrustedContact].self, from: data) {
                    return contacts
                }
                return []
            }
            let userKey = "\(Keys.trustedContacts)_\(userAccount.email)"
            
            // Try user-specific key first
            if let data = userDefaults.data(forKey: userKey),
               let contacts = try? JSONDecoder().decode([TrustedContact].self, from: data) {
                return contacts
            }
            
            // Migrate global to user-specific if exists
            if let data = userDefaults.data(forKey: Keys.trustedContacts),
               let contacts = try? JSONDecoder().decode([TrustedContact].self, from: data) {
                // Migrate to user-specific key
                if let migratedData = try? JSONEncoder().encode(contacts) {
                    userDefaults.set(migratedData, forKey: userKey)
                    userDefaults.removeObject(forKey: Keys.trustedContacts)
                }
                return contacts
            }
            
            return []
        }
    }
    
    func setTrustedContacts(_ contacts: [TrustedContact]) {
        guard let userAccount = userAccount else {
            // Fallback to global key if no user account (shouldn't happen in normal flow)
            if let data = try? JSONEncoder().encode(contacts) {
                userDefaults.set(data, forKey: Keys.trustedContacts)
            } else {
                userDefaults.removeObject(forKey: Keys.trustedContacts)
            }
            return
        }
        
        let userKey = "\(Keys.trustedContacts)_\(userAccount.email)"
        if let data = try? JSONEncoder().encode(contacts) {
            userDefaults.set(data, forKey: userKey)
            // Clear global key to prevent leakage
            userDefaults.removeObject(forKey: Keys.trustedContacts)
        } else {
            userDefaults.removeObject(forKey: userKey)
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
    
    /// Clear trusted contacts for the current user (used during logout)
    func clearCurrentUserTrustedContacts() {
        if let userAccount = userAccount {
            let userKey = "\(Keys.trustedContacts)_\(userAccount.email)"
            userDefaults.removeObject(forKey: userKey)
        }
        // Also clear legacy global contacts if they exist
        userDefaults.removeObject(forKey: Keys.trustedContacts)
    }
    
    /// Clear trusted contacts for all users (used during reset)
    func clearAllTrustedContacts() {
        // Remove all trusted contacts keys
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys {
            if key.hasPrefix(Keys.trustedContacts + "_") {
                userDefaults.removeObject(forKey: key)
            }
        }
        // Also clear legacy global contacts
        userDefaults.removeObject(forKey: Keys.trustedContacts)
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
    
    // MARK: - Session Storage (jwt)
    // Session is stored per-user to prevent state leakage between users
    
    func saveUserSession(_ session: UserSession) {
        // Extract user ID from JWT to create user-specific key
        let userKey: String
        if let jwt = session.jwt,
           let userID = extractUserIDFromJWT(jwt) {
            // Use user-specific key
            userKey = "\(Keys.userSession)_\(userID)"
        } else if let userAccount = userAccount {
            // Fallback to email if JWT not available
            userKey = "\(Keys.userSession)_\(userAccount.email)"
        } else {
            // Last resort: use global key (shouldn't happen in normal flow)
            userKey = Keys.userSession
        }
        
        let dict: [String: Any] = [
            "jwt": session.jwt ?? ""
        ]
        userDefaults.set(dict, forKey: userKey)
        
        // Also clear any old global session to prevent leakage
        if userKey != Keys.userSession {
            userDefaults.removeObject(forKey: Keys.userSession)
        }
    }
    
    func loadUserSession() -> UserSession {
        let session = UserSession()
        
        // Try to load from user-specific key first
        var userKey: String? = nil
        
        // Try to get user ID from stored JWT
        if let globalDict = userDefaults.dictionary(forKey: Keys.userSession),
           let jwt = globalDict["jwt"] as? String, !jwt.isEmpty,
           let userID = extractUserIDFromJWT(jwt) {
            userKey = "\(Keys.userSession)_\(userID)"
        } else if let userAccount = userAccount {
            // Fallback to email-based key
            userKey = "\(Keys.userSession)_\(userAccount.email)"
        }
        
        // Load from user-specific key if available
        if let key = userKey,
           let dict = userDefaults.dictionary(forKey: key) {
            session.jwt = dict["jwt"] as? String
        } else if let dict = userDefaults.dictionary(forKey: Keys.userSession) {
            // Fallback to global key (legacy support)
            session.jwt = dict["jwt"] as? String
        }
        
        return session
    }
    
    /// Extract user ID from JWT token (basic parsing, doesn't verify signature)
    private func extractUserIDFromJWT(_ jwt: String) -> String? {
        // JWT format: header.payload.signature
        let parts = jwt.components(separatedBy: ".")
        guard parts.count == 3 else { return nil }
        
        // Decode payload (base64url)
        guard let payloadData = base64URLDecode(parts[1]),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let userID = payload["sub"] as? Int ?? payload["user_id"] as? Int else {
            return nil
        }
        
        return String(userID)
    }
    
    /// Decode base64url string (JWT uses base64url, not standard base64)
    private func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        return Data(base64Encoded: base64)
    }
    
    /// Clear session for current user (called on logout)
    func clearUserSession() {
        // Clear user-specific session
        if let userAccount = userAccount {
            let userKey = "\(Keys.userSession)_\(userAccount.email)"
            userDefaults.removeObject(forKey: userKey)
        }
        
        // Also try to clear by JWT user ID if available
        if let globalDict = userDefaults.dictionary(forKey: Keys.userSession),
           let jwt = globalDict["jwt"] as? String, !jwt.isEmpty,
           let userID = extractUserIDFromJWT(jwt) {
            let userKey = "\(Keys.userSession)_\(userID)"
            userDefaults.removeObject(forKey: userKey)
        }
        
        // Clear global session (legacy)
        userDefaults.removeObject(forKey: Keys.userSession)
    }
}

