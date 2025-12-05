//
//  CalendarService.swift
//  VioletVibes
//

import Foundation
import EventKit

class CalendarService {
    static let shared = CalendarService()
    
    private let eventStore = EKEventStore()
    private var notificationObserver: NSObjectProtocol?
    
    private init() {
        // Observe calendar changes
        setupCalendarChangeObserver()
    }
    
    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Permissions
    func checkPermissionStatus() async -> Bool {
        // Only check current status, don't request
        let status = EKEventStore.authorizationStatus(for: .event)
        return status == .authorized || status == .fullAccess || status == .writeOnly
    }
    
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
    
    // MARK: - Fetch Events
    func fetchTodayEvents() -> [CalendarEvent] {
        guard hasPermission else {
            return []
        }
        
        let now = Date()
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? now
        
        // Create predicate for events from now to end of day
        let predicate = eventStore.predicateForEvents(withStart: now, end: endOfDay, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)
        
        // Convert EKEvent to CalendarEvent
        return ekEvents.map { ekEvent in
            CalendarEvent(
                id: ekEvent.eventIdentifier,
                name: ekEvent.title,
                description: ekEvent.notes,
                start: formatDate(ekEvent.startDate),
                end: formatDate(ekEvent.endDate),
                location: ekEvent.location
            )
        }
        .sorted { event1, event2 in
            guard let start1 = event1.start,
                  let date1 = parseISO8601Date(start1),
                  let start2 = event2.start,
                  let date2 = parseISO8601Date(start2) else {
                return false
            }
            return date1 < date2
        }
    }
    
    func fetchEvents(from startDate: Date, to endDate: Date) -> [CalendarEvent] {
        guard hasPermission else {
            return []
        }
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)
        
        return ekEvents.map { ekEvent in
            CalendarEvent(
                id: ekEvent.eventIdentifier,
                name: ekEvent.title,
                description: ekEvent.notes,
                start: formatDate(ekEvent.startDate),
                end: formatDate(ekEvent.endDate),
                location: ekEvent.location
            )
        }
        .sorted { event1, event2 in
            guard let start1 = event1.start,
                  let date1 = parseISO8601Date(start1),
                  let start2 = event2.start,
                  let date2 = parseISO8601Date(start2) else {
                return false
            }
            return date1 < date2
        }
    }
    
    // MARK: - Calendar Change Observer
    private func setupCalendarChangeObserver() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { [weak self] _ in
            // Post notification that calendar changed
            NotificationCenter.default.post(name: .calendarDidChange, object: nil)
        }
    }
    
    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
    
    private func parseISO8601Date(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        let cleaned = dateString.replacingOccurrences(of: "Z", with: "+00:00")
        return formatter.date(from: cleaned)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let calendarDidChange = Notification.Name("calendarDidChange")
}

