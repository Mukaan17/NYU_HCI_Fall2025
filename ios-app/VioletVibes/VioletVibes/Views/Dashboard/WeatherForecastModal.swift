//
//  WeatherForecastModal.swift
//  VioletVibes
//

import SwiftUI

struct WeatherForecastModal: View {
    let currentWeather: Weather?
    let forecast: [HourlyForecast]?
    @Binding var isPresented: Bool
    @Environment(LocationManager.self) private var locationManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Theme.Colors.background,
                        Theme.Colors.backgroundSecondary,
                        Theme.Colors.background
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Blur shapes for visual effect
                GeometryReader { geometry in
                    Circle()
                        .fill(Theme.Colors.accentBlue.opacity(0.3))
                        .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8)
                        .offset(x: -geometry.size.width * 0.2, y: -geometry.size.height * 0.1)
                        .blur(radius: 80)
                    
                    Circle()
                        .fill(Theme.Colors.accentPurpleMedium.opacity(0.2))
                        .frame(width: geometry.size.width * 0.6, height: geometry.size.width * 0.6)
                        .offset(x: geometry.size.width * 0.3, y: geometry.size.height * 0.3)
                        .blur(radius: 60)
                }
                .allowsHitTesting(false)
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.`4xl`) {
                        // Current Weather Section
                        if let weather = currentWeather {
                            VStack(spacing: Theme.Spacing.lg) {
                                Text(weather.emoji)
                                    .font(.system(size: 80))
                                
                                Text("\(weather.temp)°F")
                                    .font(.system(size: 64, weight: .bold))
                                    .foregroundColor(Theme.Colors.textPrimary)
                                
                                if let location = locationManager.location {
                                    Text("Current Location")
                                        .themeFont(size: .base)
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }
                            }
                            .padding(Theme.Spacing.`3xl`)
                            .frame(maxWidth: .infinity)
                            .background(Theme.Colors.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.BorderRadius.lg)
                                    .stroke(Theme.Colors.border, lineWidth: 1)
                            )
                            .cornerRadius(Theme.BorderRadius.lg)
                            .padding(.horizontal, Theme.Spacing.`2xl`)
                            .padding(.top, Theme.Spacing.`2xl`)
                        }
                        
                        // Hourly Forecast Section
                        if let forecast = forecast, !forecast.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                                Text("Hourly Forecast")
                                    .themeFont(size: .`2xl`, weight: .bold)
                                    .foregroundColor(Theme.Colors.textPrimary)
                                    .padding(.horizontal, Theme.Spacing.`2xl`)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: Theme.Spacing.md) {
                                        ForEach(forecast) { hour in
                                            HourlyForecastCard(forecast: hour)
                                        }
                                    }
                                    .padding(.horizontal, Theme.Spacing.`2xl`)
                                }
                            }
                        } else {
                            VStack(spacing: Theme.Spacing.lg) {
                                ProgressView()
                                    .tint(Theme.Colors.textPrimary)
                                
                                Text("Loading forecast...")
                                    .themeFont(size: .base)
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }
                            .padding(Theme.Spacing.`3xl`)
                        }
                    }
                    .padding(.bottom, Theme.Spacing.`4xl`)
                }
            }
            .navigationTitle("Weather Forecast")
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

struct HourlyForecastCard: View {
    let forecast: HourlyForecast
    
    private var timeString: String {
        let formatter = DateFormatter()
        let now = Date()
        let calendar = Calendar.current
        
        // Check if it's the current hour
        if calendar.isDate(forecast.time, equalTo: now, toGranularity: .hour) {
            return "Now"
        }
        
        formatter.dateFormat = "h a"
        return formatter.string(from: forecast.time)
    }
    
    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Time
            Text(timeString)
                .themeFont(size: .sm, weight: .semiBold)
                .foregroundColor(Theme.Colors.textSecondary)
            
            // Weather emoji
            Text(forecast.emoji)
                .font(.system(size: 32))
            
            // Temperature
            Text("\(forecast.temp)°")
                .themeFont(size: .base, weight: .semiBold)
                .foregroundColor(Theme.Colors.textPrimary)
            
            // Optional: Wind speed or humidity
            if let windSpeed = forecast.windSpeed {
                HStack(spacing: 2) {
                    Image(systemName: "wind")
                        .font(.system(size: 8))
                    Text("\(Int(windSpeed))")
                        .font(.system(size: 10))
                }
                .foregroundColor(Theme.Colors.textSecondary)
            }
        }
        .padding(.vertical, Theme.Spacing.md)
        .padding(.horizontal, Theme.Spacing.lg)
        .frame(minWidth: 80)
        .background(Theme.Colors.glassBackground)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
        .cornerRadius(Theme.BorderRadius.md)
    }
}

