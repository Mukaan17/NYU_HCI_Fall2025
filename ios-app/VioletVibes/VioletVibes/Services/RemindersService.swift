//
//  RemindersService.swift
//  VioletVibes
//

import Foundation
import EventKit

class RemindersService {
    static let shared = RemindersService()
    
    private let eventStore = EKEventStore()
    
    private init() {}
    
    // MARK: - Permissions
    func checkPermissionStatus() async -> Bool {
        // Only check current status, don't request
        let status = EKEventStore.authorizationStatus(for: .reminder)
        return status == .authorized || status == .fullAccess || status == .writeOnly
    }
    
    func requestPermission() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        
        switch status {
        case .authorized, .fullAccess, .writeOnly:
            return true
        case .notDetermined:
            do {
                return try await eventStore.requestAccess(to: .reminder)
            } catch {
                return false
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    // MARK: - Reminders Access
    var hasPermission: Bool {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        return status == .authorized || status == .fullAccess || status == .writeOnly
    }
    
    func getReminders(completion: @escaping ([EKReminder]) -> Void) {
        guard hasPermission else {
            completion([])
            return
        }
        
        let calendars = eventStore.calendars(for: .reminder)
        var allReminders: [EKReminder] = []
        let group = DispatchGroup()
        
        for calendar in calendars {
            group.enter()
            let predicate = eventStore.predicateForReminders(in: [calendar])
            eventStore.fetchReminders(matching: predicate) { reminders in
                if let reminders = reminders {
                    allReminders.append(contentsOf: reminders)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(allReminders)
        }
    }
}

