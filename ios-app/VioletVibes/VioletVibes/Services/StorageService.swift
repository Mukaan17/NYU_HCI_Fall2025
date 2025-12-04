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
        static let homeAddress = "homeAddress"
        static let trustedContacts = "trustedContacts"

        // EXISTING
        static let userAccount = "userAccount"
        static let userPreferences = "userPreferences"

        // NEW — SESSION STORAGE
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
    
    // MARK: - Onboarding Survey
    var hasCompletedOnboardingSurvey: Bool {
        get { userDefaults.bool(forKey: Keys.hasCompletedOnboardingSurvey) }
    }
    
    func setHasCompletedOnboardingSurvey(_ value: Bool) {
        userDefaults.set(value, forKey: Keys.hasCompletedOnboardingSurvey)
    }
    
    // MARK: - Reset Onboarding
    func resetOnboarding() {
        userDefaults.removeObject(forKey: Keys.hasSeenWelcome)
        userDefaults.removeObject(forKey: Keys.hasCompletedPermissions)
        userDefaults.removeObject(forKey: Keys.hasLoggedIn)
        userDefaults.removeObject(forKey: Keys.hasCompletedOnboardingSurvey)
        userDefaults.removeObject(forKey: Keys.userAccount)
        userDefaults.removeObject(forKey: Keys.userPreferences)
        userDefaults.removeObject(forKey: Keys.userSession)  // <-- NEW
    }
    
    // MARK: - Home Address
    var homeAddress: String? {
        get { userDefaults.string(forKey: Keys.homeAddress) }
    }
    
    func setHomeAddress(_ address: String?) {
        if let address = address {
            userDefaults.set(address, forKey: Keys.homeAddress)
        } else {
            userDefaults.removeObject(forKey: Keys.homeAddress)
        }
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
        
        if contacts.contains(where: { $0.id == contact.id }) {
            throw StorageError.duplicateContact("Contact with this ID already exists")
        }
        
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
        
        if let email = contact.email, !email.isEmpty {
            let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
            if contacts.contains(where: { existingContact in
                if let existingEmail = existingContact.email, !existingEmail.isEmpty {
                    return existingEmail.lowercased().trimmingCharacters(in: .whitespaces) == normalizedEmail
                }
                return false
            }) {
                throw StorageError.duplicateContact("A contact with this email already exists")
            }
        }
        
        contacts.append(contact)
        setTrustedContacts(contacts)
    }
    
    private func normalizePhoneNumber(_ phone: String) -> String {
        return phone.filter { $0.isNumber }
    }
    
    func removeTrustedContact(_ id: UUID) {
        var contacts = trustedContacts
        contacts.removeAll { $0.id == id }
        setTrustedContacts(contacts)
    }
    
    // MARK: - User Account
    var userAccount: UserAccount? {
        get {
            guard let data = userDefaults.data(forKey: Keys.userAccount),
                  let account = try? JSONDecoder().decode(UserAccount.self, from: data) else {
                return nil
            }
            return account
        }
    }
    
    func saveUserAccount(_ account: UserAccount) {
        if let data = try? JSONEncoder().encode(account) {
            userDefaults.set(data, forKey: Keys.userAccount)
        } else {
            userDefaults.removeObject(forKey: Keys.userAccount)
        }
    }
    
    // MARK: - User Preferences
    var userPreferences: UserPreferences {
        get {
            guard let data = userDefaults.data(forKey: Keys.userPreferences),
                  let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
                return UserPreferences()
            }
            return preferences
        }
    }
    
    func saveUserPreferences(_ preferences: UserPreferences) {
        if let data = try? JSONEncoder().encode(preferences) {
            userDefaults.set(data, forKey: Keys.userPreferences)
        } else {
            userDefaults.removeObject(forKey: Keys.userPreferences)
        }
    }

    // ========================================================================
    // MARK: - SESSION STORAGE (jwt + googleCalendarLinked)
    // ========================================================================
    
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

