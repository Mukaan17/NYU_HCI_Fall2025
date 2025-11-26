//
//  CalendarService.swift
//  VioletVibes
//

import Foundation
import EventKit

class CalendarService {
    static let shared = CalendarService()
    
    private let eventStore = EKEventStore()
    
    private init() {}
    
    // MARK: - Permissions
    func requestPermission() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .authorized, .fullAccess, .writeOnly:
            return true
        case .notDetermined:
            do {
                return try await eventStore.requestAccess(to: .event)
            } catch {
                return false
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    // MARK: - Calendar Access
    var hasPermission: Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        return status == .authorized || status == .fullAccess || status == .writeOnly
    }
    
    func getCalendars() -> [EKCalendar] {
        guard hasPermission else { return [] }
        return eventStore.calendars(for: .event)
    }
}

