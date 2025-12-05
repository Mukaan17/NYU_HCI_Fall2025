//
//  CalendarViewModel.swift
//  VioletVibes
//

import Foundation
import Observation

@Observable
final class CalendarViewModel {
    private let calendarService = CalendarService.shared
    private var calendarChangeObserver: NSObjectProtocol?
    var events: [CalendarEvent] = []
    var isLoading = false
    var error: String? = nil
    
    init() {
        // Observe calendar changes
        setupCalendarChangeObserver()
    }
    
    deinit {
        if let observer = calendarChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setupCalendarChangeObserver() {
        calendarChangeObserver = NotificationCenter.default.addObserver(
            forName: .calendarDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Automatically refresh events when calendar changes
            Task { @MainActor in
                await self?.loadTodayEvents()
            }
        }
    }
    
    // Calculate time until next event
    func timeUntilNextEvent() -> String? {
        let now = Date()
        
        // Find the next event that hasn't started yet
        let upcomingEvents = events.compactMap { event -> (Date, String)? in
            guard let startString = event.start,
                  let startDate = parseISO8601Date(startString),
                  startDate > now else {
                return nil
            }
            return (startDate, event.name ?? "Event")
        }
        .sorted { $0.0 < $1.0 }
        
        guard let nextEvent = upcomingEvents.first else {
            return nil
        }
        
        let timeInterval = nextEvent.0.timeIntervalSince(now)
        let hours = Int(timeInterval / 3600)
        let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "Free for \(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "Free for \(minutes)m"
        } else {
            return "Free now"
        }
    }
    
    // Get formatted time until next event (e.g., "Until 6:30 PM")
    func timeUntilFormatted() -> String? {
        let now = Date()
        
        let upcomingEvents = events.compactMap { event -> (Date, String)? in
            guard let startString = event.start,
                  let startDate = parseISO8601Date(startString),
                  startDate > now else {
                return nil
            }
            return (startDate, event.name ?? "Event")
        }
        .sorted { $0.0 < $1.0 }
        
        guard let nextEvent = upcomingEvents.first else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: nextEvent.0)
        
        return "Free until \(timeString)"
    }
    
    // Get events until next event (for summary modal)
    func eventsUntilNext() -> [CalendarEvent] {
        let now = Date()
        
        // Find the next event
        let upcomingEvents = events.compactMap { event -> (Date, CalendarEvent)? in
            guard let startString = event.start,
                  let startDate = parseISO8601Date(startString),
                  startDate > now else {
                return nil
            }
            return (startDate, event)
        }
        .sorted { $0.0 < $1.0 }
        
        guard let nextEvent = upcomingEvents.first else {
            return []
        }
        
        // Return all events up to and including the next event
        return events.filter { event in
            guard let startString = event.start,
                  let startDate = parseISO8601Date(startString) else {
                return false
            }
            return startDate <= nextEvent.0
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
    
    func loadTodayEvents(jwt: String? = nil) async {
        // Check if we have calendar permission
        var hasPermission = await calendarService.checkPermissionStatus()
        
        // Request permission if not granted
        if !hasPermission {
            hasPermission = await calendarService.requestPermission()
        }
        
        // If still no permission, set error and return
        guard hasPermission else {
            error = "Calendar access denied"
            events = []
            isLoading = false
            return
        }
        
        isLoading = true
        error = nil
        
        // Fetch events directly from system calendar
        events = calendarService.fetchTodayEvents()
        
        isLoading = false
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

