//
//  LocationSharingService.swift
//  VioletVibes
//

import Foundation
import MessageUI
import Contacts
import CoreLocation
import UIKit
import MapKit

class LocationSharingService: NSObject {
    static let shared = LocationSharingService()
    
    private override init() {
        super.init()
    }
    
    // MARK: - iMessage Detection
    
    /// Detects if a contact is likely an iMessage user
    /// Note: This is an approximation - we check if the contact has an Apple ID email or phone format
    func isIMessageUser(contact: TrustedContact) -> Bool {
        // Check if contact has an email that looks like an Apple ID (iCloud, me.com, mac.com)
        if let email = contact.email?.lowercased() {
            let appleDomains = ["icloud.com", "me.com", "mac.com"]
            if appleDomains.contains(where: { email.contains($0) }) {
                return true
            }
        }
        
        // Check if phone number is in a format that typically supports iMessage
        // (US/Canada numbers, or international numbers)
        if let phone = contact.phoneNumber {
            // Basic check - if it's a valid phone number format, assume it might support iMessage
            // In a real implementation, you'd use more sophisticated detection
            let cleaned = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
            return cleaned.count >= 10
        }
        
        return false
    }
    
    // MARK: - Sharing Methods
    
    /// Shares location via Find My (iMessage)
    func shareViaFindMy(contact: TrustedContact, location: CLLocation, presentingViewController: UIViewController) {
        guard MFMessageComposeViewController.canSendText() else {
            // Fallback to opening Messages app with location
            openMessagesAppWithLocation(contact: contact, location: location)
            return
        }
        
        let messageComposer = MFMessageComposeViewController()
        messageComposer.messageComposeDelegate = self
        
        // Add recipient
        if let phone = contact.phoneNumber {
            messageComposer.recipients = [phone]
        } else if let email = contact.email {
            messageComposer.recipients = [email]
        }
        
        // Create location message with Google Maps link
        let locationText = createLocationMessage(location: location)
        messageComposer.body = locationText
        
        presentingViewController.present(messageComposer, animated: true)
    }
    
    /// Shares location via WhatsApp
    func shareViaWhatsApp(contact: TrustedContact, location: CLLocation) -> Bool {
        guard let phone = contact.phoneNumber else { return false }
        
        // Clean phone number (remove non-numeric characters except +)
        let cleanedPhone = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        
        // Create Google Maps link
        let mapsLink = createGoogleMapsLink(location: location)
        let message = "📍 My current location: \(mapsLink)"
        
        // Try WhatsApp URL scheme
        let whatsappURL = "whatsapp://send?phone=\(cleanedPhone)&text=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: whatsappURL),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return true
        }
        
        return false
    }
    
    /// Shares location via SMS
    func shareViaSMS(contact: TrustedContact, location: CLLocation, presentingViewController: UIViewController) {
        guard MFMessageComposeViewController.canSendText() else {
            return
        }
        
        let messageComposer = MFMessageComposeViewController()
        messageComposer.messageComposeDelegate = self
        
        // Add recipient
        if let phone = contact.phoneNumber {
            messageComposer.recipients = [phone]
        }
        
        // Create message with Google Maps link
        let mapsLink = createGoogleMapsLink(location: location)
        messageComposer.body = "📍 My current location: \(mapsLink)"
        
        presentingViewController.present(messageComposer, animated: true)
    }
    
    // MARK: - Main Sharing Method
    
    /// Main method to share location with a contact
    /// Automatically selects the best method based on contact type
    func shareLocation(
        with contact: TrustedContact,
        location: CLLocation,
        presentingViewController: UIViewController,
        completion: @escaping (Bool, String?) -> Void
    ) {
        guard contact.hasContactMethod else {
            completion(false, "Contact has no phone number or email")
            return
        }
        
        // Try iMessage/Find My first if contact appears to be an Apple user
        if isIMessageUser(contact: contact) {
            shareViaFindMy(contact: contact, location: location, presentingViewController: presentingViewController)
            completion(true, "Sharing via iMessage")
            return
        }
        
        // Try WhatsApp if phone number is available
        if contact.phoneNumber != nil {
            if shareViaWhatsApp(contact: contact, location: location) {
                completion(true, "Sharing via WhatsApp")
                return
            }
        }
        
        // Fallback to SMS
        if contact.phoneNumber != nil {
            shareViaSMS(contact: contact, location: location, presentingViewController: presentingViewController)
            completion(true, "Sharing via SMS")
            return
        }
        
        // If only email is available, try to open Mail app
        if let email = contact.email {
            shareViaEmail(contact: contact, location: location)
            completion(true, "Sharing via Email")
            return
        }
        
        completion(false, "Unable to share location")
    }
    
    // MARK: - Helper Methods
    
    private func createLocationMessage(location: CLLocation) -> String {
        let mapsLink = createGoogleMapsLink(location: location)
        return "📍 My current location: \(mapsLink)"
    }
    
    private func createGoogleMapsLink(location: CLLocation) -> String {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        return "https://www.google.com/maps?q=\(lat),\(lon)"
    }
    
    private func createLocationURL(location: CLLocation) -> URL? {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        return URL(string: "https://maps.apple.com/?ll=\(lat),\(lon)")
    }
    
    private func openMessagesAppWithLocation(contact: TrustedContact, location: CLLocation) {
        let mapsLink = createGoogleMapsLink(location: location)
        let message = "📍 My current location: \(mapsLink)"
        
        var urlString = "sms:"
        if let phone = contact.phoneNumber {
            let cleaned = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
            urlString += cleaned
        }
        urlString += "&body=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: urlString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareViaEmail(contact: TrustedContact, location: CLLocation) {
        let mapsLink = createGoogleMapsLink(location: location)
        let subject = "My Current Location"
        let body = "📍 My current location: \(mapsLink)"
        
        let mailto = "mailto:\(contact.email ?? "")?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: mailto),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - MFMessageComposeViewControllerDelegate

extension LocationSharingService: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }
}

