//
//  ContactsService.swift
//  VioletVibes
//

import Foundation
import Contacts

class ContactsService {
    static let shared = ContactsService()
    
    private let contactStore = CNContactStore()
    
    private init() {}
    
    // MARK: - Permissions
    func requestPermission() async -> Bool {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            do {
                return try await contactStore.requestAccess(for: .contacts)
            } catch {
                return false
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    // MARK: - Contacts Access
    var hasPermission: Bool {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        return status == .authorized
    }
    
    func getContacts() -> [CNContact] {
        guard hasPermission else { return [] }
        
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        
        var contacts: [CNContact] = []
        do {
            try contactStore.enumerateContacts(with: request) { contact, _ in
                contacts.append(contact)
            }
        } catch {
            print("Error fetching contacts: \(error)")
        }
        
        return contacts
    }
}

