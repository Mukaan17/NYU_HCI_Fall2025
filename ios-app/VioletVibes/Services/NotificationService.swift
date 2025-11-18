//
//  NotificationService.swift
//  VioletVibes
//

import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    // MARK: - Permissions
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    // MARK: - Notification Status
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    var hasPermission: Bool {
        get async {
            let status = await getAuthorizationStatus()
            return status == .authorized
        }
    }
    
    // MARK: - Send Notification
    func sendNotification(title: String, body: String, identifier: String = UUID().uuidString) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to send notification: \(error)")
        }
    }
}

