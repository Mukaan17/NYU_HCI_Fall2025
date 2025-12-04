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
    
    @State private var currentDeviceLocation: CLLocation? = nil
    @State private var isGeocoding = false
    @State private var currentLocationAddress: String? = nil
    
    @State private var expandedSteps: Bool = false
    @State private var geocodingTask: Task<Void, Never>? = nil
    
    private let defaultLat = 40.693393
    private let defaultLng = -73.98555
    private let geocoder = CLGeocoder()

    var body: some View {
        ZStack {
            // ───────────────────────────────────────────
            // MARK: MAP WITH PIN + POLYLINE
            // ───────────────────────────────────────────
            Map(position: $viewModel.cameraPosition) {
                
                // User location blip
                if let loc = currentDeviceLocation {
                    Annotation("My Location", coordinate: loc.coordinate) {
                        LocationBlipView()
                    }
                }
                
                // Selected place pin
                if let place = placeViewModel.selectedPlace {
                    Annotation(place.name, coordinate: place.coordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(Theme.Colors.gradientStart)
                            .font(.system(size: 32))
                            .shadow(color: .black.opacity(0.3), radius: 4)
                    }
                }

                // OTHER RECOMMENDATION PINS
                ForEach(placeViewModel.nearbyPlaces) { place in
                    // Skip if it's the place currently selected
                    if placeViewModel.selectedPlace?.id != place.id {
                        Annotation(place.name, coordinate: place.coordinate) {
                            RecommendationPinView()
                                .onTapGesture {
                                    handlePinTap(place)
                                }
                        }
                    }
                }

                // Purple walking route polyline
                if !viewModel.polylineCoordinates.isEmpty {
                    MapPolyline(coordinates: viewModel.polylineCoordinates)
                        .stroke(Theme.Colors.gradientStart, lineWidth: 5)
                }
            }
            .mapStyle(.standard(elevation: .flat))
            .ignoresSafeArea()

            // ───────────────────────────────────────────
            // MARK: ADDRESS BADGE
            // ───────────────────────────────────────────
            VStack {
                addressBadge
                Spacer()
            }
            .padding(.top, Theme.Spacing.`2xl`)

            // ───────────────────────────────────────────
            // MARK: BOTTOM SHEET
            // ───────────────────────────────────────────
            VStack {
                Spacer()
                bottomSheet
            }

            // ───────────────────────────────────────────
            // MARK: CENTER TO LOCATION BUTTON
            // ───────────────────────────────────────────
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    centerLocationButton
                }
            }
            .padding(.trailing, Theme.Spacing.`2xl`)
            .padding(.bottom, 120)
        }
        .onAppear {
            setupInitialState()
        }
        .task(id: placeViewModel.selectedPlace?.id) {
            await handlePlaceSelection()
        }
        .onChange(of: locationManager.location) { _, newLoc in
            handleLocationUpdate(newLoc)
        }
    }
}

// ╔═══════════════════════════════════════════════════════════
// MARK: - ADDRESS BADGE
// ╚═══════════════════════════════════════════════════════════

extension MapView {
    private var addressBadge: some View {
        HStack(spacing: Theme.Spacing.md) {
            Text("📍").font(.system(size: 15))

            if let place = placeViewModel.selectedPlace {
                Text(place.address ?? place.name)
                    .themeFont(size: .base, weight: .semiBold)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(2)
            } else if isGeocoding {
                HStack(spacing: 6) {
                    ProgressView().scaleEffect(0.8)
                    Text("Getting location…")
                }
                .themeFont(size: .base, weight: .semiBold)
                .foregroundColor(Theme.Colors.textPrimary)
            } else {
                Text(currentLocationAddress ?? "2 MetroTech Center")
                    .themeFont(size: .base, weight: .semiBold)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, Theme.Spacing.`3xl`)
        .padding(.vertical, Theme.Spacing.`2xl`)
        .background(.regularMaterial)
        .backgroundStyle(.thinMaterial)
        .cornerRadius(Theme.BorderRadius.md)
        .shadow(radius: 3)
    }
}

// ╔═══════════════════════════════════════════════════════════
// MARK: - BOTTOM SHEET (Place Details + Steps)
// ╚═══════════════════════════════════════════════════════════

extension MapView {
    private var bottomSheet: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            
            if let place = placeViewModel.selectedPlace {
                // PLACE NAME
                Text(place.name)
                    .themeFont(size: .`2xl`, weight: .bold)
                    .foregroundColor(Theme.Colors.textPrimary)

                // WALK TIME + DISTANCE
                if let walk = place.walkTime, let dist = place.distance {
                    Text("\(walk) • \(dist)")
                        .themeFont(size: .base)
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                // ROUTE STATUS
                if viewModel.isLoadingRoute {
                    Text("Loading walking directions…")
                        .themeFont(size: .sm)
                        .foregroundColor(.gray)
                } else if !viewModel.polylineCoordinates.isEmpty {
                    Text("Walking route ready — follow the purple path.")
                        .themeFont(size: .sm)
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                // ───────────────────────────────────────────
                // TURN-BY-TURN STEPS
                // ───────────────────────────────────────────
                if !viewModel.steps.isEmpty {
                    Button {
                        withAnimation { expandedSteps.toggle() }
                    } label: {
                        HStack {
                            Text(expandedSteps ? "Hide Steps" : "Show Steps")
                            Spacer()
                            Image(systemName: expandedSteps ? "chevron.down" : "chevron.right")
                        }
                        .font(.headline)
                        .foregroundColor(Theme.Colors.textPrimary)
                    }

                    if expandedSteps {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(viewModel.steps) { step in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(stripHTML(step.instruction))
                                        .themeFont(size: .sm)
                                        .foregroundColor(Theme.Colors.textPrimary)

                                    Text("\(step.distance) • \(step.duration)")
                                        .themeFont(size: .xs)
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }

            } else {
                Text("Select a place to see walking route")
                    .foregroundColor(.gray)
            }

        }
        .padding(Theme.Spacing.`2xl`)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.glassBackground)
        .cornerRadius(16)
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

// ╔═══════════════════════════════════════════════════════════
// MARK: - CENTER BUTTON
// ╚═══════════════════════════════════════════════════════════

extension MapView {
    private var centerLocationButton: some View {
        Button {
            let loc = currentDeviceLocation ?? locationManager.location
            if let loc = loc {
                viewModel.centerToUserLocation(
                    latitude: loc.coordinate.latitude,
                    longitude: loc.coordinate.longitude
                )
            }
        } label: {
            Image(systemName: "location.fill")
                .foregroundColor(Theme.Colors.textPrimary)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 50, height: 50)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
    }
}

// ╔═══════════════════════════════════════════════════════════
// MARK: - HELPERS
// ╚═══════════════════════════════════════════════════════════

extension MapView {
    
    private func setupInitialState() {
        viewModel.updateRegion(latitude: defaultLat, longitude: defaultLng, animated: false)
        updateCurrentLocation()
    }
    
    private func updateCurrentLocation() {
        if let loc = locationManager.location {
            currentDeviceLocation = loc
            Task { await geocode(loc) }
        }
    }
    
    private func handlePlaceSelection() async {
        guard let p = placeViewModel.selectedPlace else {
            viewModel.clearRoute()
            return
        }
        await viewModel.fetchRoute(destinationLat: p.latitude, destinationLng: p.longitude)
        expandedSteps = false
    }

    private func handleLocationUpdate(_ newLoc: CLLocation?) {
        guard let loc = newLoc else { return }
        currentDeviceLocation = loc
        Task { await geocode(loc) }
    }

    private func geocode(_ location: CLLocation) async {
        isGeocoding = true
        defer { isGeocoding = false }

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let mark = placemarks.first {
                currentLocationAddress = [
                    mark.subThoroughfare,
                    mark.thoroughfare,
                    mark.locality
                ].compactMap { $0 }.joined(separator: " ")
            }
        } catch {
            currentLocationAddress = "Current Location"
        }
    }
    
    private func stripHTML(_ text: String) -> String {
        text.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
    }

    @MainActor
    private func handlePinTap(_ place: SelectedPlace) {
        placeViewModel.setSelectedPlace(place)
        viewModel.updateRegion(latitude: place.latitude,
                            longitude: place.longitude)

        Task {
            await viewModel.fetchRoute(
                destinationLat: place.latitude,
                destinationLng: place.longitude
            )
        }
    }

}

// ╔═══════════════════════════════════════════════════════════
// MARK: - LOCATION BLIP VIEW
// ╚═══════════════════════════════════════════════════════════

struct LocationBlipView: View {
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.Colors.gradientStart.opacity(0.3))
                .frame(width: 24, height: 24)
                .scaleEffect(pulse ? 2.0 : 1.0)
                .opacity(pulse ? 0.0 : 0.7)
            Circle()
                .fill(Theme.Colors.gradientStart)
                .frame(width: 12, height: 12)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }
}

struct RecommendationPinView: View {
    var body: some View {
        Image(systemName: "mappin.circle")
            .font(.system(size: 20))
            .foregroundColor(Theme.Colors.gradientStart)
            .shadow(radius: 3)
    }
}

