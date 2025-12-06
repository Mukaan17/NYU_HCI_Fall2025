//
//  MapView.swift
//  VioletVibes
//

import SwiftUI
import MapKit
import CoreLocation
import UIKit

struct MapView: View {
    @Environment(PlaceViewModel.self) private var placeViewModel
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.openURL) private var openURL
    @State private var viewModel = MapViewModel()
    @State private var currentLocationAddress: String? = nil
    @State private var isGeocoding = false
    @State private var lastProcessedLocation: CLLocation? = nil
    @State private var currentDeviceLocation: CLLocation? = nil
    @State private var locationPollingTask: Task<Void, Never>? = nil
    @State private var geocodingTask: Task<Void, Never>? = nil
    @State private var lastGeocodeTime: Date? = nil
    @State private var showMapsPicker = false
    @State private var pendingDestination: (coordinate: CLLocationCoordinate2D, name: String)? = nil
    @State private var dragDistance: CGFloat = 0
    @State private var homeAddress: String? = nil
    @State private var homeCoordinate: CLLocationCoordinate2D? = nil
    @State private var isHomeSelected: Bool = false
    @State private var isGeocodingHome: Bool = false
    private let geocodeThrottle: TimeInterval = 5.0 // Only geocode every 5 seconds
    private let tapThreshold: CGFloat = 10 // Pixels - if drag distance is less than this, it's a tap
    
    private let defaultLat = 40.693393
    private let defaultLng = -73.98555
    
    // NYU Campus coordinates
    private let tandonLat = 40.693393
    private let tandonLng = -73.98555
    private let washingtonSquareLat = 40.7295
    private let washingtonSquareLng = -73.9965
    
    private let geocoder = CLGeocoder()
    private let storage = StorageService.shared
    
    var body: some View {
        ZStack {
            mapContent
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // Track total drag distance
                            dragDistance = sqrt(value.translation.width * value.translation.width + value.translation.height * value.translation.height)
                        }
                        .onEnded { _ in
                            // If drag distance is small, treat as tap
                            if dragDistance < tapThreshold {
                                handleMapTap()
                            }
                            // Reset drag distance
                            dragDistance = 0
                        }
                )
            addressBadge
            bottomSheet
            centerToLocationButton
        }
        .onChange(of: placeViewModel.selectedPlace) { oldValue, newValue in
            handlePlaceChange(oldValue: oldValue, newValue: newValue)
            // Clear home selection when a place is selected
            if newValue != nil {
                isHomeSelected = false
            }
        }
        .onChange(of: placeViewModel.showHomeOnly) { oldValue, newValue in
            // When home-only mode is enabled, select home if coordinates are available
            if newValue, let homeCoord = homeCoordinate {
                isHomeSelected = true
                viewModel.zoomToLocation(
                    latitude: homeCoord.latitude,
                    longitude: homeCoord.longitude,
                    animated: true
                )
            }
        }
        .onChange(of: isHomeSelected) { oldValue, newValue in
            // Clear place selection when home is selected
            if newValue {
                placeViewModel.clearSelectedPlace()
            }
        }
        .onChange(of: locationManager.location) { oldValue, newValue in
            handleLocationChange(oldLocation: oldValue, newLocation: newValue)
        }
        .onAppear {
            handleAppear()
            loadHomeAddress()
            // If in home-only mode, ensure home is selected
            if placeViewModel.showHomeOnly, let homeCoord = homeCoordinate {
                isHomeSelected = true
                viewModel.zoomToLocation(
                    latitude: homeCoord.latitude,
                    longitude: homeCoord.longitude,
                    animated: true
                )
            }
        }
        .task {
            handleTask()
        }
        .onDisappear {
            handleDisappear()
        }
    }
    
    // MARK: - Map Content
    private var mapContent: some View {
        Map(position: $viewModel.cameraPosition) {
            // User location annotation
            if let location = currentDeviceLocation {
                Annotation("My Location", coordinate: location.coordinate) {
                    LocationBlipView()
                        .id("user_location")
                }
            }
            
            // Only show pins for backend-suggested places (unless in home-only mode)
            if !placeViewModel.showHomeOnly {
                ForEach(placeViewModel.allPlaces) { place in
                    Annotation(place.name, coordinate: place.coordinate) {
                        Button(action: {
                            handlePinTap(place: place)
                        }) {
                            CategoryPinView(
                                place: place,
                                isSelected: place.id == placeViewModel.selectedPlace?.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Show pin for selected place if it's not in allPlaces (fallback)
                if let selectedPlace = placeViewModel.selectedPlace,
                   !placeViewModel.allPlaces.contains(where: { $0.id == selectedPlace.id }) {
                    Annotation(selectedPlace.name, coordinate: selectedPlace.coordinate) {
                        Button(action: {
                            handlePinTap(place: selectedPlace)
                        }) {
                            CategoryPinView(
                                place: selectedPlace,
                                isSelected: true
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Home pin (if home address is set)
            if let homeCoord = homeCoordinate {
                Annotation("Home", coordinate: homeCoord) {
                    Button(action: {
                        handleHomePinTap()
                    }) {
                        HomePinView(isSelected: isHomeSelected)
                    }
                    .buttonStyle(.plain)
                }
            }
            
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .ignoresSafeArea()
    }
    
    // MARK: - Address Badge
    @ViewBuilder
    private var addressBadge: some View {
        VStack {
            if let place = placeViewModel.selectedPlace {
                placeAddressBadge(place: place)
            } else {
                currentLocationBadge
            }
            Spacer()
        }
        .padding(.top, Theme.Spacing.`2xl`)
    }
    
    @ViewBuilder
    private func placeAddressBadge(place: SelectedPlace) -> some View {
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
    }
    
    @ViewBuilder
    private var currentLocationBadge: some View {
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
    
    // MARK: - Bottom Sheet
    @ViewBuilder
    private var bottomSheet: some View {
        GeometryReader { geometry in
            let geometryWidth = geometry.size.width
            let geometryHeight = geometry.size.height
            
            if geometryWidth > 0 && geometryHeight > 0 {
                let safeAreaBottom = geometry.safeAreaInsets.bottom
                let tabBarContentHeight: CGFloat = 49
                let tabBarHeight = safeAreaBottom + tabBarContentHeight
                let cardBottomPadding = Theme.Spacing.`2xl`
                let hasImage = placeViewModel.selectedPlace?.image != nil
                let cardContentHeight: CGFloat = hasImage ? 272 : 112
                let cardPadding = Theme.Spacing.`2xl` * 2
                let estimatedCardHeight = cardContentHeight + cardPadding
                let gradientHeight = max(tabBarHeight + cardBottomPadding + estimatedCardHeight, 200)
                
                ZStack(alignment: .bottom) {
                    bottomSheetGradient(height: gradientHeight)
                    bottomSheetCard
                }
            } else {
                EmptyView()
            }
        }
    }
    
    @ViewBuilder
    private func bottomSheetGradient(height: CGFloat) -> some View {
        LinearGradient(
            colors: [
                Color.clear,
                Theme.Colors.backgroundOverlay,
                Theme.Colors.background
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: max(height, 200))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(edges: .bottom)
        .allowsHitTesting(false)
    }
    
    @ViewBuilder
    private var bottomSheetCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            if isHomeSelected {
                homeCardContent
            } else if let place = placeViewModel.selectedPlace {
                placeCardContent(place: place)
            } else {
                defaultCardContent
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
    
    @ViewBuilder
    private func placeCardContent(place: SelectedPlace) -> some View {
        if let imageURL = place.image {
            placeImage(url: imageURL)
        }
        
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(place.name)
                .themeFont(size: .`2xl`, weight: .semiBold)
                .foregroundColor(Theme.Colors.textPrimary)
            
            // Address
            if let address = place.address {
                Text(address)
                    .themeFont(size: .sm)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            // Rating (if available from recommendation)
            if let rating = getRatingForPlace(place) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    Text(rating)
                        .themeFont(size: .sm, weight: .medium)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
        }
        
        routeInfoView(place: place)
        getDirectionsButton(place: place)
    }
    
    private func getRatingForPlace(_ place: SelectedPlace) -> String? {
        return place.rating
    }
    
    @ViewBuilder
    private func placeImage(url: String) -> some View {
        AsyncImage(url: URL(string: url)) { phase in
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
        .id(url)
    }
    
    @ViewBuilder
    private func routeInfoView(place: SelectedPlace) -> some View {
        if let walkTime = place.walkTime, let distance = place.distance {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.gradientStart)
                Text("\(walkTime) • \(distance)")
                    .themeFont(size: .base)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        } else {
            Text("Home base • NYU")
                .themeFont(size: .base)
                .foregroundColor(Theme.Colors.textSecondary)
        }
    }
    
    @ViewBuilder
    private func getDirectionsButton(place: SelectedPlace) -> some View {
        Button(action: {
            handleGetDirections(place: place)
        }) {
            HStack {
                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Get Directions")
                    .themeFont(size: .base, weight: .semiBold)
            }
            .foregroundColor(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                LinearGradient(
                    colors: [Theme.Colors.gradientStart, Theme.Colors.gradientEnd],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(Theme.BorderRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                    .stroke(Theme.Colors.border.opacity(0.2), lineWidth: 1)
            )
        }
        .confirmationDialog("Open Directions", isPresented: $showMapsPicker, titleVisibility: .visible) {
            Button("Apple Maps") {
                if let destination = pendingDestination {
                    let userLocation = currentDeviceLocation ?? locationManager.location
                    let origin = userLocation?.coordinate ?? CLLocationCoordinate2D(latitude: defaultLat, longitude: defaultLng)
                    openInAppleMaps(origin: origin, destination: destination.coordinate, destinationName: destination.name)
                }
                pendingDestination = nil
            }
            Button("Google Maps") {
                if let destination = pendingDestination {
                    let userLocation = currentDeviceLocation ?? locationManager.location
                    let origin = userLocation?.coordinate ?? CLLocationCoordinate2D(latitude: defaultLat, longitude: defaultLng)
                    openInGoogleMaps(origin: origin, destination: destination.coordinate, destinationName: destination.name)
                }
                pendingDestination = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDestination = nil
            }
        }
    }
    
    @ViewBuilder
    private var loadingRouteIndicator: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("Loading route...")
                .themeFont(size: .sm)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding(.top, Theme.Spacing.xs)
    }
    
    @ViewBuilder
    private var defaultCardContent: some View {
        Text(campusNameForCurrentLocation)
            .themeFont(size: .`2xl`, weight: .semiBold)
            .foregroundColor(Theme.Colors.textPrimary)
        
        if let address = currentLocationAddress {
            Text(address)
                .themeFont(size: .sm)
                .foregroundColor(Theme.Colors.textSecondary)
                .lineLimit(2)
        }
        
        Text("Home base • NYU")
            .themeFont(size: .base)
            .foregroundColor(Theme.Colors.textSecondary)
    }
    
    // Determine which campus name to show based on current location
    private var campusNameForCurrentLocation: String {
        // First check address string for keywords
        if let address = currentLocationAddress, !address.isEmpty {
            let addressLower = address.lowercased()
            
            // Washington Square area keywords
            if addressLower.contains("washington") || 
               addressLower.contains("greenwich") || 
               addressLower.contains("bleecker") || 
               addressLower.contains("university") ||
               addressLower.contains("macdougal") ||
               addressLower.contains("west 4th") ||
               addressLower.contains("west 3rd") ||
               addressLower.contains("west 8th") ||
               addressLower.contains("west 9th") ||
               addressLower.contains("west 10th") ||
               addressLower.contains("west 11th") ||
               addressLower.contains("west 12th") ||
               addressLower.contains("east 8th") ||
               addressLower.contains("east 9th") ||
               addressLower.contains("east 10th") ||
               addressLower.contains("east 11th") ||
               addressLower.contains("east 12th") ||
               addressLower.contains("washington place") ||
               addressLower.contains("washington square") {
                return "Washington Square"
            }
            
            // Tandon/Brooklyn area keywords
            if addressLower.contains("metrotech") || 
               addressLower.contains("jay") ||
               addressLower.contains("tillary") || 
               addressLower.contains("brooklyn") ||
               addressLower.contains("flatbush") ||
               addressLower.contains("dekalb") ||
               addressLower.contains("fulton") {
                return "Tandon"
            }
        }
        
        // If current location is available, use distance calculation
        if let location = currentDeviceLocation ?? locationManager.location {
            let currentLocation = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let tandonLocation = CLLocation(latitude: tandonLat, longitude: tandonLng)
            let washingtonSquareLocation = CLLocation(latitude: washingtonSquareLat, longitude: washingtonSquareLng)
            
            let distanceToTandon = currentLocation.distance(from: tandonLocation)
            let distanceToWashingtonSquare = currentLocation.distance(from: washingtonSquareLocation)
            
            // If within 2km of a campus, show that campus name
            if distanceToTandon < 2000 {
                return "Tandon"
            } else if distanceToWashingtonSquare < 2000 {
                return "Washington Square"
            }
        }
        
        // Default fallback
        return currentLocationAddress ?? "2 MetroTech Center"
    }
    
    @ViewBuilder
    private var homeCardContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "house.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.Colors.gradientStart)
                Text(campusNameForHome)
                    .themeFont(size: .`2xl`, weight: .semiBold)
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            
            if let address = homeAddress {
                Text(address)
                    .themeFont(size: .sm)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            Text("Home base • NYU")
                .themeFont(size: .base)
                .foregroundColor(Theme.Colors.textSecondary)
            
            getHomeDirectionsButton
        }
    }
    
    // Determine which campus name to show based on home location
    private var campusNameForHome: String {
        // First, check address string for keywords (works even if coordinates aren't set yet)
        if let address = homeAddress, !address.isEmpty {
            let addressLower = address.lowercased()
            
            // Washington Square area keywords
            if addressLower.contains("washington") || 
               addressLower.contains("greenwich") || 
               addressLower.contains("bleecker") || 
               addressLower.contains("university") ||
               addressLower.contains("macdougal") ||
               addressLower.contains("west 4th") ||
               addressLower.contains("west 3rd") ||
               addressLower.contains("west 8th") ||
               addressLower.contains("west 9th") ||
               addressLower.contains("west 10th") ||
               addressLower.contains("west 11th") ||
               addressLower.contains("west 12th") ||
               addressLower.contains("east 8th") ||
               addressLower.contains("east 9th") ||
               addressLower.contains("east 10th") ||
               addressLower.contains("east 11th") ||
               addressLower.contains("east 12th") ||
               addressLower.contains("washington place") ||
               addressLower.contains("washington square") {
                return "Washington Square"
            }
            
            // Tandon/Brooklyn area keywords
            if addressLower.contains("metrotech") || 
               addressLower.contains("jay") ||
               addressLower.contains("tillary") || 
               addressLower.contains("brooklyn") ||
               addressLower.contains("flatbush") ||
               addressLower.contains("dekalb") ||
               addressLower.contains("fulton") {
                return "Tandon"
            }
        }
        
        // If coordinates are available, use distance calculation
        if let homeCoord = homeCoordinate {
            let homeLocation = CLLocation(latitude: homeCoord.latitude, longitude: homeCoord.longitude)
            let tandonLocation = CLLocation(latitude: tandonLat, longitude: tandonLng)
            let washingtonSquareLocation = CLLocation(latitude: washingtonSquareLat, longitude: washingtonSquareLng)
            
            let distanceToTandon = homeLocation.distance(from: tandonLocation)
            let distanceToWashingtonSquare = homeLocation.distance(from: washingtonSquareLocation)
            
            // If within 2km of a campus, show that campus name
            if distanceToTandon < 2000 {
                return "Tandon"
            } else if distanceToWashingtonSquare < 2000 {
                return "Washington Square"
            }
        }
        
        // Default fallback
        return "Home"
    }
    
    @ViewBuilder
    private var getHomeDirectionsButton: some View {
        Button(action: {
            handleGetHomeDirections()
        }) {
            HStack {
                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Get Directions")
                    .themeFont(size: .base, weight: .semiBold)
            }
            .foregroundColor(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                LinearGradient(
                    colors: [Theme.Colors.gradientStart, Theme.Colors.gradientEnd],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(Theme.BorderRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                    .stroke(Theme.Colors.border.opacity(0.2), lineWidth: 1)
            )
        }
        .confirmationDialog("Open Directions", isPresented: $showMapsPicker, titleVisibility: .visible) {
            Button("Apple Maps") {
                if let destination = pendingDestination {
                    let userLocation = currentDeviceLocation ?? locationManager.location
                    let origin = userLocation?.coordinate ?? CLLocationCoordinate2D(latitude: defaultLat, longitude: defaultLng)
                    openInAppleMaps(origin: origin, destination: destination.coordinate, destinationName: destination.name)
                }
                pendingDestination = nil
            }
            Button("Google Maps") {
                if let destination = pendingDestination {
                    let userLocation = currentDeviceLocation ?? locationManager.location
                    let origin = userLocation?.coordinate ?? CLLocationCoordinate2D(latitude: defaultLat, longitude: defaultLng)
                    openInGoogleMaps(origin: origin, destination: destination.coordinate, destinationName: destination.name)
                }
                pendingDestination = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDestination = nil
            }
        }
    }
    
    // MARK: - Center to Location Button
    @ViewBuilder
    private var centerToLocationButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: handleCenterToLocation) {
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
    
    // MARK: - Event Handlers
    private func handleMapTap() {
        // Dismiss the selected place or home card when tapping on map
        if placeViewModel.selectedPlace != nil {
            placeViewModel.clearSelectedPlace()
        }
        if isHomeSelected {
            isHomeSelected = false
        }
        // Exit home-only mode when user interacts with map
        if placeViewModel.showHomeOnly {
            placeViewModel.setHomeOnlyMode(false)
        }
    }
    
    private func handlePinTap(place: SelectedPlace) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Clear home selection and exit home-only mode
        isHomeSelected = false
        placeViewModel.setHomeOnlyMode(false)
        placeViewModel.setSelectedPlace(place)
        
        // Zoom in on the selected pin
        viewModel.zoomToLocation(
            latitude: place.latitude,
            longitude: place.longitude,
            animated: true
        )
    }
    
    private func handleHomePinTap() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Clear place selection
        placeViewModel.clearSelectedPlace()
        isHomeSelected = true
        
        // Zoom in on home location
        if let homeCoord = homeCoordinate {
            viewModel.zoomToLocation(
                latitude: homeCoord.latitude,
                longitude: homeCoord.longitude,
                animated: true
            )
        }
    }
    
    private func handlePlaceChange(oldValue: SelectedPlace?, newValue: SelectedPlace?) {
        guard oldValue?.id != newValue?.id else { return }
        
        if let place = newValue {
            currentLocationAddress = nil
            // Clear home selection when a place is selected
            isHomeSelected = false
            // Use zoomToLocation to center the map on the pin with proper offset
            viewModel.zoomToLocation(
                latitude: place.latitude,
                longitude: place.longitude,
                animated: true
            )
        } else {
            // When place is cleared, show home base card
            isHomeSelected = false
            if let location = locationManager.location {
                geocodingTask?.cancel()
                geocodingTask = Task {
                    await geocodeLocation(location)
                }
            }
        }
    }
    
    private func handleLocationChange(oldLocation: CLLocation?, newLocation: CLLocation?) {
        guard let newLocation = newLocation else { return }
        
        currentDeviceLocation = newLocation
        
        if let oldLocation = oldLocation {
            let distance = newLocation.distance(from: oldLocation)
            guard distance > 100 else { return }
        }
        
        handleLocationUpdate(oldLocation: oldLocation, newLocation: newLocation)
    }
    
    private func handleAppear() {
        // Try to get device location first, fallback to default only if unavailable
        let initialLocation = LocationService.shared.location ?? locationManager.location
        
        if let location = initialLocation {
            // Use device location immediately
            currentDeviceLocation = location
            viewModel.updateRegion(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                animated: false
            )
            lastProcessedLocation = location
            
            geocodingTask?.cancel()
            geocodingTask = Task {
                try? await Task.sleep(nanoseconds: 800_000_000)
                await geocodeLocation(location)
            }
        } else {
            // Only use default if device location is not available
            viewModel.updateRegion(latitude: defaultLat, longitude: defaultLng, animated: false)
        }
        
        Task { @MainActor in
            // Wait a bit and check again for location if we didn't have it initially
            if initialLocation == nil {
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                let updatedLocation = LocationService.shared.location ?? locationManager.location
                if let location = updatedLocation {
                    currentDeviceLocation = location
                    viewModel.updateRegion(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        animated: true
                    )
                    lastProcessedLocation = location
                    
                    geocodingTask?.cancel()
                    geocodingTask = Task {
                        try? await Task.sleep(nanoseconds: 800_000_000)
                        await geocodeLocation(location)
                    }
                }
            }
            
            if currentDeviceLocation == nil {
                locationPollingTask = Task {
                    var iterations = 0
                    let maxIterations = 2
                    
                    while !Task.isCancelled && iterations < maxIterations {
                        try? await Task.sleep(nanoseconds: 10_000_000_000)
                        
                        let latestLocation = LocationService.shared.location ?? locationManager.location
                        if let location = latestLocation {
                            if let lastLocation = lastProcessedLocation {
                                let distance = location.distance(from: lastLocation)
                                if distance > 100 {
                                    await MainActor.run {
                                        currentDeviceLocation = location
                                        handleLocationUpdate(oldLocation: lastProcessedLocation, newLocation: location)
                                        lastProcessedLocation = location
                                    }
                                }
                            } else {
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
        }
    }
    
    private func handleTask() {
        if placeViewModel.selectedPlace == nil {
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                
                if let location = locationManager.location ?? LocationService.shared.location {
                    await geocodeLocation(location)
                }
            }
        }
        
        // Load recommendations and convert to places for map pins
        loadRecommendationsForMap()
    }
    
    private func loadRecommendationsForMap() {
        // Don't load recommendations if in home-only mode
        guard !placeViewModel.showHomeOnly else {
            return
        }
        Task {
            // Fetch recommendations from multiple categories to get 20 total
            let apiService = APIService.shared
            var allPlaces: [SelectedPlace] = []
            
            // Categories to fetch from
            let categories = ["explore", "quick_bites", "chill_cafes", "events"]
            let limitPerCategory = 5 // 5 per category = 20 total
            
            do {
                // Fetch from each category
                for category in categories {
                    do {
                        let response = try await apiService.getQuickRecommendations(category: category, limit: limitPerCategory)
                        
                        // Convert recommendations to SelectedPlace objects with category
                        let places = response.places.compactMap { rec -> SelectedPlace? in
                            guard let lat = rec.lat, let lng = rec.lng else { return nil }
                            return SelectedPlace(
                                name: rec.title,
                                latitude: lat,
                                longitude: lng,
                                walkTime: rec.walkTime,
                                distance: rec.distance,
                                address: rec.description,
                                image: rec.image,
                                rating: rec.popularity,
                                category: response.category
                            )
                        }
                        
                        allPlaces.append(contentsOf: places)
                    } catch {
                        print("Failed to load recommendations for category \(category): \(error)")
                    }
                }
                
                // Limit to 20 total for new places
                let limitedPlaces = Array(allPlaces.prefix(20))
                
                await MainActor.run {
                    // Merge with existing places instead of replacing them
                    // This preserves recommendation pins from chat
                    let existingPlaces = placeViewModel.allPlaces
                    var mergedPlaces = existingPlaces
                    
                    // Add new places that don't already exist (check by name and coordinates)
                    for place in limitedPlaces {
                        let isDuplicate = mergedPlaces.contains { existingPlace in
                            existingPlace.name == place.name &&
                            abs(existingPlace.latitude - place.latitude) < 0.0001 &&
                            abs(existingPlace.longitude - place.longitude) < 0.0001
                        }
                        if !isDuplicate {
                            mergedPlaces.append(place)
                        }
                    }
                    
                    // Update with merged list (keep all existing + new ones)
                    placeViewModel.setAllPlaces(mergedPlaces)
                }
            } catch {
                print("Failed to load recommendations for map: \(error)")
            }
        }
    }
    
    private func handleDisappear() {
        locationPollingTask?.cancel()
        locationPollingTask = nil
        geocodingTask?.cancel()
        geocodingTask = nil
    }
    
    private func handleGetDirections(place: SelectedPlace) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Store destination and show picker
        let destinationCoordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
        pendingDestination = (coordinate: destinationCoordinate, name: place.name)
        showMapsPicker = true
    }
    
    private func openInAppleMaps(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, destinationName: String) {
        // Create map items for origin and destination
        let originPlacemark = MKPlacemark(coordinate: origin)
        let destinationPlacemark = MKPlacemark(coordinate: destination)
        
        let originMapItem = MKMapItem(placemark: originPlacemark)
        originMapItem.name = "Current Location"
        
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        destinationMapItem.name = destinationName
        
        // Open in Apple Maps with walking directions (since we're using walking/transit)
        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking]
        MKMapItem.openMaps(with: [originMapItem, destinationMapItem], launchOptions: options)
    }
    
    private func openInGoogleMaps(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, destinationName: String) {
        // Google Maps URL scheme for directions
        let urlString = "comgooglemaps://?saddr=\(origin.latitude),\(origin.longitude)&daddr=\(destination.latitude),\(destination.longitude)&directionsmode=walking"
        
        if let url = URL(string: urlString) {
            openURL(url)
        } else {
            // Fallback to web version if Google Maps app is not installed
            let webURLString = "https://www.google.com/maps/dir/?api=1&origin=\(origin.latitude),\(origin.longitude)&destination=\(destination.latitude),\(destination.longitude)&travelmode=walking"
            if let webURL = URL(string: webURLString) {
                openURL(webURL)
            }
        }
    }
    
    private func handleCenterToLocation() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        let latestLocation = currentDeviceLocation ?? LocationService.shared.location ?? locationManager.location
        
        if let location = latestLocation {
            viewModel.centerToUserLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        } else {
            locationManager.forceLocationCheck()
            
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                
                await MainActor.run {
                    let updatedLocation = LocationService.shared.location ?? locationManager.location
                    if let location = updatedLocation {
                        viewModel.centerToUserLocation(
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude
                        )
                    } else {
                        viewModel.centerToUserLocation(
                            latitude: defaultLat,
                            longitude: defaultLng
                        )
                    }
                }
            }
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
    
    // MARK: - Home Address Functions
    private func loadHomeAddress() {
        Task {
            let address = await storage.homeAddress
            await MainActor.run {
                homeAddress = address
                if let address = address, !address.isEmpty {
                    geocodeHomeAddress(address)
                }
            }
        }
    }
    
    private func geocodeHomeAddress(_ address: String) {
        guard !isGeocodingHome else { return }
        isGeocodingHome = true
        
        Task {
            do {
                let placemarks = try await geocoder.geocodeAddressString(address)
                
                await MainActor.run {
                    if let placemark = placemarks.first,
                       let location = placemark.location {
                        homeCoordinate = location.coordinate
                    }
                    isGeocodingHome = false
                }
            } catch {
                await MainActor.run {
                    print("Failed to geocode home address: \(error.localizedDescription)")
                    isGeocodingHome = false
                }
            }
        }
    }
    
    private func handleGetHomeDirections() {
        guard let homeCoord = homeCoordinate else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Store destination and show picker
        let destinationName = homeAddress ?? "Home"
        pendingDestination = (coordinate: homeCoord, name: destinationName)
        showMapsPicker = true
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

// Category Pin View - Shows different colors and glyphs based on category
struct CategoryPinView: View {
    let place: SelectedPlace
    let isSelected: Bool
    
    private var categoryInfo: (color: Color, glyph: String) {
        let category = place.category?.lowercased() ?? "explore"
        
        switch category {
        case "quick_bites", "food":
            return (Color(hex: "FF6B6B"), "fork.knife")
        case "chill_cafes", "cafe", "coffee":
            return (Theme.Colors.gradientBlueStart, "cup.and.saucer.fill")
        case "events", "event":
            return (Theme.Colors.accentGreen, "calendar")
        case "explore", "explore_places":
            return (Theme.Colors.gradientStart, "mappin.circle.fill")
        default:
            return (Theme.Colors.gradientStart, "mappin.circle.fill")
        }
    }
    
    var body: some View {
        ZStack {
            // Background circle for opacity
            Circle()
                .fill(Color.white.opacity(0.95))
                .frame(width: isSelected ? 40 : 36, height: isSelected ? 40 : 36)
            
            // Category-colored circle
            Circle()
                .fill(categoryInfo.color)
                .frame(width: isSelected ? 32 : 28, height: isSelected ? 32 : 28)
            
            // Glyph icon
            Image(systemName: categoryInfo.glyph)
                .foregroundColor(.white)
                .font(.system(size: isSelected ? 18 : 16, weight: .semibold))
        }
        .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 3)
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// Home Pin View - Shows home location with house glyph
struct HomePinView: View {
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            // Background circle for opacity
            Circle()
                .fill(Color.white.opacity(0.95))
                .frame(width: isSelected ? 40 : 36, height: isSelected ? 40 : 36)
            
            // Home-colored circle (using gradient start color)
            Circle()
                .fill(Theme.Colors.gradientStart)
                .frame(width: isSelected ? 32 : 28, height: isSelected ? 32 : 28)
            
            // Home glyph icon
            Image(systemName: "house.fill")
                .foregroundColor(.white)
                .font(.system(size: isSelected ? 18 : 16, weight: .semibold))
        }
        .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 3)
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

