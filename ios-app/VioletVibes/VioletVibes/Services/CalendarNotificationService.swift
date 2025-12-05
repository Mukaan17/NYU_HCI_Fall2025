//
//  CalendarNotificationService.swift
//  VioletVibes
//

import Foundation
import UserNotifications
import Observation

@Observable
final class CalendarNotificationService {
    static let shared = CalendarNotificationService()
    
    private let apiService = APIService.shared
    private var checkTask: Task<Void, Never>? = nil
    private var lastCheckTime: Date? = nil
    private let checkInterval: TimeInterval = 15 * 60 // Check every 15 minutes
    private var processedNotificationIds: Set<String> = []
    
    private init() {
        // Load processed notification IDs from UserDefaults
        if let saved = UserDefaults.standard.array(forKey: "processedNotificationIds") as? [String] {
            processedNotificationIds = Set(saved)
        }
    }
    
    // MARK: - Start/Stop Monitoring
    
    func startMonitoring(jwt: String?) {
        guard let jwt = jwt, !jwt.isEmpty else {
            print("⚠️ Cannot start calendar notification monitoring: No JWT token")
            return
        }
        
        // Cancel existing task if any
        checkTask?.cancel()
        
        // Start periodic checking
        checkTask = Task {
            await performPeriodicChecks(jwt: jwt)
        }
    }
    
    func stopMonitoring() {
        checkTask?.cancel()
        checkTask = nil
    }
    
    // MARK: - Periodic Checks
    
    private func performPeriodicChecks(jwt: String) async {
        while !Task.isCancelled {
            // Wait before first check (to avoid immediate check on app launch)
            if lastCheckTime == nil {
                try? await Task.sleep(nanoseconds: 60_000_000_000) // 1 minute
            }
            
            await checkForNotifications(jwt: jwt)
            
            // Wait for next check interval
            try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
        }
    }
    
    // MARK: - Check for Notifications
    
    private func checkForNotifications(jwt: String) async {
        do {
            let response = try await apiService.checkCalendarNotifications(jwt: jwt)
            lastCheckTime = Date()
            
            // Check if notifications array is empty
            guard !response.notifications.isEmpty else {
                return
            }
            
            // Process each notification match
            for match in response.notifications {
                await processNotificationMatch(match)
            }
            
        } catch {
            print("⚠️ Error checking calendar notifications: \(error)")
        }
    }
    
    // MARK: - Process Notification Match
    
    private func processNotificationMatch(_ match: NotificationMatch) async {
        // Create a unique ID for this notification based on free time and events
        let notificationId = "\(match.free_time.start)-\(match.events.first?.title ?? "")"
        
        // Skip if we've already processed this notification
        if processedNotificationIds.contains(notificationId) {
            return
        }
        
        // Get the best matching event (first one)
        guard let event = match.events.first else {
            return
        }
        
        // Calculate when to send the notification (15 minutes before free time starts)
        guard let freeTimeStart = parseISO8601Date(match.free_time.start) else {
            return
        }
        
        let notificationTime = freeTimeStart.addingTimeInterval(-15 * 60) // 15 minutes before
        let now = Date()
        
        // Only schedule if notification time is in the future
        guard notificationTime > now else {
            return
        }
        
        // Build notification content
        let title = "You have free time!"
        let body = buildNotificationBody(event: event, freeTime: match.free_time)
        
        // Schedule the notification
        await NotificationService.shared.scheduleNotification(
            title: title,
            body: body,
            timeInterval: notificationTime.timeIntervalSince(now),
            identifier: notificationId
        )
        
        // Mark as processed
        processedNotificationIds.insert(notificationId)
        saveProcessedIds()
        
        print("📬 Scheduled notification: '\(title)' for \(notificationTime)")
    }
    
    private func buildNotificationBody(event: EventMatch, freeTime: FreeTimeSlot) -> String {
        var parts: [String] = []
        
        if let eventTitle = event.title {
            parts.append(eventTitle)
        }
        
        if let location = event.location {
            parts.append("at \(location)")
        }
        
        let duration = Int(freeTime.duration_minutes)
        if duration > 0 {
            parts.append("(\(duration) min free)")
        }
        
        return parts.joined(separator: " ")
    }
    
    private func parseISO8601Date(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Try with fractional seconds first
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Try removing Z and adding timezone
        let cleaned = dateString.replacingOccurrences(of: "Z", with: "+00:00")
        return formatter.date(from: cleaned)
    }
    
    private func saveProcessedIds() {
        UserDefaults.standard.set(Array(processedNotificationIds), forKey: "processedNotificationIds")
    }
    
    // MARK: - Manual Check
    
    func checkNow(jwt: String) async {
        await checkForNotifications(jwt: jwt)
    }
}

