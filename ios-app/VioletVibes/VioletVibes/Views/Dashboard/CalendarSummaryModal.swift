//
//  CalendarSummaryModal.swift
//  VioletVibes
//

import SwiftUI

struct CalendarSummaryModal: View {
    let events: [CalendarEvent]
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                if events.isEmpty {
                    VStack(spacing: Theme.Spacing.lg) {
                        Image(systemName: "calendar")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        Text("No upcoming events")
                            .themeFont(size: .xl, weight: .semiBold)
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Text("You're free for the rest of the day!")
                            .themeFont(size: .base)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                            ForEach(events, id: \.id) { event in
                                CalendarEventRow(event: event)
                            }
                        }
                        .padding(Theme.Spacing.`2xl`)
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
        }
    }
}

struct CalendarEventRow: View {
    let event: CalendarEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // Time indicator
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                if let start = event.start, let date = parseDate(start) {
                    Text(formatTime(date))
                        .themeFont(size: .sm, weight: .semiBold)
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    if let end = event.end, let endDate = parseDate(end) {
                        Text(formatTime(endDate))
                            .themeFont(size: .xs)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
            }
            .frame(width: 60)
            
            // Event details
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(event.name ?? "Untitled Event")
                    .themeFont(size: .base, weight: .semiBold)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                if let location = event.location, !location.isEmpty {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.textSecondary)
                        Text(location)
                            .themeFont(size: .sm)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
                
                if let description = event.description, !description.isEmpty {
                    Text(description)
                        .themeFont(size: .sm)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineLimit(2)
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
}

