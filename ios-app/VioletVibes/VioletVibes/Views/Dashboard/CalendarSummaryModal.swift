//
//  CalendarSummaryModal.swift
//  VioletVibes
//

import SwiftUI

struct CalendarSummaryModal: View {
    let events: [CalendarEvent]
    @Binding var isPresented: Bool
    @State private var currentTime = Date()
    @State private var timer: Timer?
    
    // Filter out events that have ended
    private var activeEvents: [CalendarEvent] {
        let now = currentTime
        return events.filter { event in
            // If event has an end time, check if it's in the future
            if let endString = event.end,
               let endDate = parseDate(endString) {
                return endDate > now
            }
            // If no end time, check start time
            if let startString = event.start,
               let startDate = parseDate(startString) {
                return startDate > now
            }
            // If no dates, include it (shouldn't happen, but safe fallback)
            return true
        }
    }
    
    // Group events by date
    private var groupedEvents: [(String, [CalendarEvent])] {
        let calendar = Calendar.current
        let now = currentTime
        
        let grouped = Dictionary(grouping: activeEvents) { event -> String in
            guard let startString = event.start,
                  let startDate = parseDate(startString) else {
                return "Other"
            }
            
            if calendar.isDateInToday(startDate) {
                return "Today"
            } else if calendar.isDateInTomorrow(startDate) {
                return "Tomorrow"
            } else if startDate > now {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE, MMMM d"
                return formatter.string(from: startDate)
            } else {
                return "Past"
            }
        }
        
        // Sort by date, with Today first, then Tomorrow, then future dates, then Past
        let sortedKeys = grouped.keys.sorted { key1, key2 in
            let order = ["Today", "Tomorrow", "Past", "Other"]
            let index1 = order.firstIndex(of: key1) ?? Int.max
            let index2 = order.firstIndex(of: key2) ?? Int.max
            
            if index1 != Int.max || index2 != Int.max {
                return index1 < index2
            }
            
            // Both are date strings, sort alphabetically
            return key1 < key2
        }
        
        return sortedKeys.compactMap { key in
            guard let events = grouped[key], !events.isEmpty else { return nil }
            // Sort events within each group by start time
            let sortedEvents = events.sorted { event1, event2 in
                guard let start1 = event1.start,
                      let date1 = parseDate(start1),
                      let start2 = event2.start,
                      let date2 = parseDate(start2) else {
                    return false
                }
                return date1 < date2
            }
            return (key, sortedEvents)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                if activeEvents.isEmpty {
                    VStack(spacing: Theme.Spacing.lg) {
                        Image(systemName: "calendar")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        Text("No events")
                            .themeFont(size: .xl, weight: .semiBold)
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Text("You're free for the rest of the day!")
                            .themeFont(size: .base)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.Spacing.`2xl`) {
                            ForEach(groupedEvents, id: \.0) { dateGroup, dateEvents in
                                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                                    // Date header
                                    Text(dateGroup)
                                        .themeFont(size: .lg, weight: .bold)
                                        .foregroundColor(Theme.Colors.textPrimary)
                                        .padding(.horizontal, Theme.Spacing.`2xl`)
                                        .padding(.top, dateGroup == groupedEvents.first?.0 ? 0 : Theme.Spacing.xl)
                                    
                                    // Events for this date
                                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                                        ForEach(dateEvents, id: \.id) { event in
                                            CalendarEventRow(event: event)
                                        }
                                    }
                                    .padding(.horizontal, Theme.Spacing.`2xl`)
                                }
                            }
                        }
                        .padding(.vertical, Theme.Spacing.`2xl`)
                    }
                }
            }
            .navigationTitle("Your Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(Theme.Colors.textPrimary)
                }
            }
            .onAppear {
                // Start timer to update every minute
                timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
                    currentTime = Date()
                }
            }
            .onDisappear {
                // Stop timer when view disappears
                timer?.invalidate()
                timer = nil
            }
        }
    }
    
    private func parseDate(_ dateString: String) -> Date? {
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

struct CalendarEventRow: View {
    let event: CalendarEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // Time indicator with duration
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                if let start = event.start, let startDate = parseDate(start) {
                    Text(formatTime(startDate))
                        .themeFont(size: .sm, weight: .semiBold)
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    if let end = event.end, let endDate = parseDate(end) {
                        Text(formatTime(endDate))
                            .themeFont(size: .xs)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        // Show duration
                        let duration = endDate.timeIntervalSince(startDate)
                        let hours = Int(duration / 3600)
                        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
                        
                        if hours > 0 || minutes > 0 {
                            Text(formatDuration(hours: hours, minutes: minutes))
                                .themeFont(size: .xs)
                                .foregroundColor(Theme.Colors.textSecondary.opacity(0.7))
                        }
                    }
                }
            }
            .frame(width: 70, alignment: .leading)
            
            // Event details
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(event.name ?? "Untitled Event")
                    .themeFont(size: .base, weight: .semiBold)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(2)
                
                if let location = event.location, !location.isEmpty {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.textSecondary)
                        Text(location)
                            .themeFont(size: .sm)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }
                
                if let description = event.description, !description.isEmpty {
                    Text(description)
                        .themeFont(size: .sm)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineLimit(3)
                }
            }
            
            Spacer()
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Colors.glassBackground)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
        .cornerRadius(Theme.BorderRadius.md)
    }
    
    private func parseDate(_ dateString: String) -> Date? {
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
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatDuration(hours: Int, minutes: Int) -> String {
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

