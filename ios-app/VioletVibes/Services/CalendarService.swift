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
        case .authorized:
            return true
        case .notDetermined:
            return await eventStore.requestAccess(to: .event)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    // MARK: - Calendar Access
    var hasPermission: Bool {
        EKEventStore.authorizationStatus(for: .event) == .authorized
    }
    
    func getCalendars() -> [EKCalendar] {
        guard hasPermission else { return [] }
        return eventStore.calendars(for: .event)
    }
}

