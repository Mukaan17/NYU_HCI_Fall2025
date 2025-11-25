//
//  MapView.swift
//  VioletVibes
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @Environment(PlaceViewModel.self) private var placeViewModel
    @Environment(LocationManager.self) private var locationManager
    @State private var viewModel = MapViewModel()
    @State private var currentLocationAddress: String? = nil
    @State private var isGeocoding = false
    @State private var lastProcessedLocation: CLLocation? = nil
    @State private var currentDeviceLocation: CLLocation? = nil
    @State private var locationPollingTask: Task<Void, Never>? = nil
    @State private var geocodingTask: Task<Void, Never>? = nil
    @State private var lastGeocodeTime: Date? = nil
    private let geocodeThrottle: TimeInterval = 5.0 // Only geocode every 5 seconds
    
    private let defaultLat = 40.693393
    private let defaultLng = -73.98555
    private let geocoder = CLGeocoder()
    
    var body: some View {
        ZStack {
            // Map using modern iOS 17+ API
            Map(position: $viewModel.cameraPosition) {
                // User location - dynamic blip (uses latest location from either source)
                // Use stable ID to prevent unnecessary annotation recreation
                if let location = currentDeviceLocation ?? LocationService.shared.location ?? locationManager.location {
                    Annotation("My Location", coordinate: location.coordinate) {
                        LocationBlipView()
                            .id("user_location") // Stable ID to prevent recreation
                    }
                }
                
                // Destination marker
                if let place = placeViewModel.selectedPlace {
                    Annotation(place.name, coordinate: place.coordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(Theme.Colors.gradientStart)
                            .font(.system(size: 32))
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
                
                // Route polyline
                if !viewModel.polylineCoordinates.isEmpty {
                    MapPolyline(coordinates: viewModel.polylineCoordinates)
                        .stroke(Theme.Colors.gradientStart, lineWidth: 5)
                }
            }
            .mapStyle(.standard(elevation: .flat)) // Changed from .realistic to .flat for better performance
            .ignoresSafeArea()
            
            // Address Badge
            VStack {
                if let place = placeViewModel.selectedPlace {
                    HStack(spacing: Theme.Spacing.md) {
                        Text("📍")
                            .font(.system(size: 15))
                        Text(place.address ?? place.name)
                            .themeFont(size: .base, weight: .semiBold)
                            .foregroundColor(Theme.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, Theme.Spacing.`3xl`)
                    .padding(.vertical, Theme.Spacing.`2xl`)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                            .fill(.regularMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                } else {
                    HStack(spacing: Theme.Spacing.md) {
                        Text("📍")
                            .font(.system(size: 15))
                        if isGeocoding {
                            HStack(spacing: Theme.Spacing.xs) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(Theme.Colors.textPrimary)
                                Text("Getting location...")
                                    .themeFont(size: .base, weight: .semiBold)
                                    .foregroundColor(Theme.Colors.textPrimary)
                            }
                        } else {
                            Text(currentLocationAddress ?? "2 MetroTech Center")
                                .themeFont(size: .base, weight: .semiBold)
                                .foregroundColor(Theme.Colors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(2)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.`3xl`)
                    .padding(.vertical, Theme.Spacing.`2xl`)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                            .fill(.regularMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                
                Spacer()
            }
            .padding(.top, Theme.Spacing.`2xl`)
            
            // Bottom Sheet
            GeometryReader { geometry in
                let safeAreaBottom = geometry.safeAreaInsets.bottom
                let tabBarContentHeight: CGFloat = 49 // Standard iOS tab bar content height
                let tabBarHeight = safeAreaBottom + tabBarContentHeight
                
                // Card bottom padding
                let cardBottomPadding = Theme.Spacing.`2xl` // 16 points
                
                // Estimate card height based on content
                // Card padding (top + bottom): 2xl * 2 = 32 points
                // Text content: ~60-80 points
                // Image (if present): 160 points + spacing
                // Spacing between elements: ~20 points
                let hasImage = placeViewModel.selectedPlace?.image != nil
                let cardContentHeight: CGFloat = hasImage ? 272 : 112 // Image adds ~160 points
                let cardPadding = Theme.Spacing.`2xl` * 2 // Top and bottom padding
                let estimatedCardHeight = cardContentHeight + cardPadding
                
                // Calculate gradient height: from bottom to card top
                // Gradient should extend from bottom (tab bar start) to card top edge
                let gradientHeight = tabBarHeight + cardBottomPadding + estimatedCardHeight
                
                return ZStack(alignment: .bottom) {
                    // Gradient that starts from absolute bottom and ends at card top
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Theme.Colors.backgroundOverlay,
                            Theme.Colors.background
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: gradientHeight)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)
                    
                    // Card positioned at bottom
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        if let place = placeViewModel.selectedPlace {
                            if let imageURL = place.image {
                                AsyncImage(url: URL(string: imageURL)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(height: 160)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .failure:
                                        Image(systemName: "photo")
                                            .foregroundColor(Theme.Colors.textSecondary)
                                            .frame(height: 160)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .frame(height: 160)
                                .cornerRadius(12)
                                .clipped()
                                .id(imageURL) // Cache hint for SwiftUI
                            }
                            
                            Text(place.name)
                                .themeFont(size: .`2xl`, weight: .semiBold)
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            if let walkTime = place.walkTime, let distance = place.distance {
                                Text("\(walkTime) • \(distance)")
                                    .themeFont(size: .base)
                                    .foregroundColor(Theme.Colors.textSecondary)
                            } else {
                                Text("Home base • NYU Tandon")
                                    .themeFont(size: .base)
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }
                            
                            Text("Walking directions coming soon…")
                                .themeFont(size: .sm)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .opacity(0.8)
                        } else {
                            Text("2 MetroTech Center")
                                .themeFont(size: .`2xl`, weight: .semiBold)
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            Text("Home base • NYU Tandon")
                                .themeFont(size: .base)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                    }
                    .padding(Theme.Spacing.`2xl`)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.Colors.glassBackground)
                    .cornerRadius(Theme.BorderRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.BorderRadius.lg)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                    .padding(.horizontal, Theme.Spacing.`2xl`)
                    .padding(.bottom, Theme.Spacing.`2xl`)
                }
            }
            
            // Center to Location Button - bottom right corner above card (on top layer)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        // Get the latest location - try LocationService first, then LocationManager
                        let latestLocation = LocationService.shared.location ?? locationManager.location
                        
                        if let location = latestLocation {
                            // Always center to the latest location, even if coordinates are similar
                            viewModel.centerToUserLocation(
                                latitude: location.coordinate.latitude,
                                longitude: location.coordinate.longitude
                            )
                        } else {
                            // Force location check and wait for update
                            locationManager.forceLocationCheck()
                            
                            Task {
                                // Wait a bit for location to update
                                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                                
                                await MainActor.run {
                                    let updatedLocation = LocationService.shared.location ?? locationManager.location
                                    if let location = updatedLocation {
                                        viewModel.centerToUserLocation(
                                            latitude: location.coordinate.latitude,
                                            longitude: location.coordinate.longitude
                                        )
                                    } else {
                                        // Fallback to default location
                                        viewModel.centerToUserLocation(
                                            latitude: defaultLat,
                                            longitude: defaultLng
                                        )
                                    }
                                }
                            }
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.Colors.textPrimary)
                            .frame(width: 48, height: 48)
                            .background(
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                    
                                    Circle()
                                        .fill(Theme.Colors.glassBackground.opacity(0.8))
                                }
                            )
                            .overlay(
                                Circle()
                                    .stroke(Theme.Colors.border.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, Theme.Spacing.`2xl`)
                    .padding(.bottom, 120)
                }
            }
        }
        .onChange(of: placeViewModel.selectedPlace) { oldValue, newValue in
            // Only update if place actually changed
            guard oldValue?.id != newValue?.id else { return }
            
            if let place = newValue {
                // Clear current location address when a place is selected
                currentLocationAddress = nil
                viewModel.updateRegion(latitude: place.latitude, longitude: place.longitude, animated: true)
                Task {
                    await viewModel.fetchRoute(destinationLat: place.latitude, destinationLng: place.longitude)
                }
            } else {
                // Clear route when place is deselected
                viewModel.clearRoute()
                // Geocode current location when place is deselected
                if let location = locationManager.location {
                    geocodingTask?.cancel()
                    geocodingTask = Task {
                        await geocodeLocation(location)
                    }
                }
            }
        }
        .onChange(of: locationManager.location) { oldValue, newValue in
            // Only update if location changed significantly (50m threshold)
            guard let newLocation = newValue else { return }
            
            if let oldLocation = oldValue {
                let distance = newLocation.distance(from: oldLocation)
                guard distance > 50 else { return } // Only update if moved 50+ meters
            }
            
            // Update current device location state for blip
            currentDeviceLocation = newLocation
            handleLocationUpdate(oldLocation: oldValue, newLocation: newValue)
        }
        .onAppear {
            // Check both LocationService and LocationManager for initial location
            let initialLocation = LocationService.shared.location ?? locationManager.location
            if let location = initialLocation {
                currentDeviceLocation = location
                viewModel.updateRegion(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                // Geocode initial location (only once)
                geocodingTask?.cancel()
                geocodingTask = Task {
                    await geocodeLocation(location)
                }
                lastProcessedLocation = location
            } else {
                viewModel.updateRegion(latitude: defaultLat, longitude: defaultLng)
            }
            
            // Start periodic check for LocationService updates
            // Use longer interval to reduce battery and memory usage
            // Note: This is mainly for initial location, as onChange handlers will catch updates
            locationPollingTask = Task {
                // Only run a few times, then rely on onChange handlers
                var iterations = 0
                let maxIterations = 3 // Only check 3 times (30 seconds total)
                
                while !Task.isCancelled && iterations < maxIterations {
                    try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                    
                    let latestLocation = LocationService.shared.location ?? locationManager.location
                    if let location = latestLocation {
                        // Only update if we don't have a location yet or it changed significantly
                        if let lastLocation = lastProcessedLocation {
                            let distance = location.distance(from: lastLocation)
                            if distance > 100 { // Only update if moved 100+ meters
                                await MainActor.run {
                                    currentDeviceLocation = location
                                    handleLocationUpdate(oldLocation: lastProcessedLocation, newLocation: location)
                                    lastProcessedLocation = location
                                }
                            }
                        } else {
                            // First location
                            await MainActor.run {
                                currentDeviceLocation = location
                                handleLocationUpdate(oldLocation: nil, newLocation: location)
                                lastProcessedLocation = location
                            }
                        }
                    }
                    iterations += 1
                }
            }
        }
        .task {
            // Geocode location on task start if available
            if placeViewModel.selectedPlace == nil, let location = locationManager.location {
                await geocodeLocation(location)
            }
        }
        .onDisappear {
            // Cancel all tasks to prevent memory leaks
            locationPollingTask?.cancel()
            locationPollingTask = nil
            geocodingTask?.cancel()
            geocodingTask = nil
        }
    }
    
    // Handle location updates for automatic map centering
    private func handleLocationUpdate(oldLocation: CLLocation?, newLocation: CLLocation?) {
        guard let newLocation = newLocation else { return }
        
        // Throttle geocoding to reduce API calls and memory usage
        let shouldGeocode: Bool
        if let lastGeocode = lastGeocodeTime {
            shouldGeocode = Date().timeIntervalSince(lastGeocode) >= geocodeThrottle
        } else {
            shouldGeocode = true
        }
        
        // Geocode the new location for the badge (if no place is selected and throttled)
        if placeViewModel.selectedPlace == nil && shouldGeocode {
            lastGeocodeTime = Date()
            // Cancel any existing geocoding task
            geocodingTask?.cancel()
            geocodingTask = Task {
                await geocodeLocation(newLocation)
            }
        }
        
        // Only auto-update map if no place is selected
        // This allows users to explore the map without it jumping back to their location
        guard placeViewModel.selectedPlace == nil else { return }
        
        // Update map automatically when location changes
        // Use a larger threshold (100 meters) to reduce map updates and improve performance
        if let oldLocation = oldLocation {
            let distance = newLocation.distance(from: oldLocation)
            // Update if moved more than 100m to reduce unnecessary map updates
            guard distance > 100 else { return }
        }
        
        // Update map region to follow user location (throttled by MapViewModel)
        viewModel.updateRegion(
            latitude: newLocation.coordinate.latitude,
            longitude: newLocation.coordinate.longitude,
            animated: true // Smooth animation for automatic updates
        )
    }
    
    // Reverse geocode location to get address
    private func geocodeLocation(_ location: CLLocation) async {
        // Check if task was cancelled before starting
        guard !Task.isCancelled else { return }
        
        await MainActor.run {
            isGeocoding = true
        }
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            // Check again after async operation
            guard !Task.isCancelled else {
                await MainActor.run {
                    isGeocoding = false
                }
                return
            }
            
            await MainActor.run {
                if let placemark = placemarks.first {
                    // Build address string from placemark
                    var addressComponents: [String] = []
                    
                    if let streetNumber = placemark.subThoroughfare {
                        addressComponents.append(streetNumber)
                    }
                    if let streetName = placemark.thoroughfare {
                        addressComponents.append(streetName)
                    }
                    if let city = placemark.locality {
                        addressComponents.append(city)
                    }
                    
                    if !addressComponents.isEmpty {
                        currentLocationAddress = addressComponents.joined(separator: " ")
                    } else if let name = placemark.name {
                        currentLocationAddress = name
                    } else {
                        currentLocationAddress = "Current Location"
                    }
                } else {
                    currentLocationAddress = "Current Location"
                }
                isGeocoding = false
            }
        } catch {
            // Don't update UI if task was cancelled
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                // Only log non-cancellation errors
                if !(error is CancellationError) {
                    print("Geocoding error: \(error.localizedDescription)")
                }
                currentLocationAddress = "Current Location"
                isGeocoding = false
            }
        }
    }
}

// Location Blip View - Animated location indicator
struct LocationBlipView: View {
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.6
    
    var body: some View {
        ZStack {
            // Outer pulsing ring
            Circle()
                .fill(Theme.Colors.gradientStart.opacity(pulseOpacity))
                .frame(width: 24, height: 24)
                .scaleEffect(pulseScale)
            
            // Inner solid dot
            Circle()
                .fill(Theme.Colors.gradientStart)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
        }
        .onAppear {
            withAnimation(
                Animation.easeOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                pulseScale = 2.0
                pulseOpacity = 0.0
            }
        }
    }
}

