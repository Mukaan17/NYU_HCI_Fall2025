//
//  MapView.swift
//  VioletVibes
//

import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var placeViewModel: PlaceViewModel
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var viewModel = MapViewModel()
    
    private let defaultLat = 40.693393
    private let defaultLng = -73.98555
    
    var body: some View {
        ZStack {
            // Map
            Map(coordinateRegion: $viewModel.region, annotationItems: annotations) { annotation in
                MapMarker(coordinate: annotation.coordinate, tint: Theme.Colors.gradientStart)
            }
            // Note: MapKit polyline rendering would need MKPolyline and MKMapView
            // For now, we'll use annotations to show the route
            .ignoresSafeArea()
            
            // User location indicator
            if let location = locationManager.location {
                UserLocationIndicator(coordinate: location.coordinate)
            }
            
            // Address Badge
            VStack {
                if let place = placeViewModel.selectedPlace {
                    HStack(spacing: Theme.Spacing.md) {
                        Text("📍")
                            .font(.system(size: 15))
                        Text(place.address ?? place.name)
                            .themeFont(size: .base, weight: .semiBold)
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                    .padding(.horizontal, Theme.Spacing.`3xl`)
                    .padding(.vertical, Theme.Spacing.`2xl`)
                    .background(
                        LinearGradient(
                            colors: [
                                Theme.Colors.glassBackgroundLight,
                                Theme.Colors.glassBackgroundDarkLight
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                    .cornerRadius(Theme.BorderRadius.md)
                } else {
                    HStack(spacing: Theme.Spacing.md) {
                        Text("📍")
                            .font(.system(size: 15))
                        Text("2 MetroTech Center")
                            .themeFont(size: .base, weight: .semiBold)
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                    .padding(.horizontal, Theme.Spacing.`3xl`)
                    .padding(.vertical, Theme.Spacing.`2xl`)
                    .background(
                        LinearGradient(
                            colors: [
                                Theme.Colors.glassBackgroundLight,
                                Theme.Colors.glassBackgroundDarkLight
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                    .cornerRadius(Theme.BorderRadius.md)
                }
                
                Spacer()
            }
            .padding(.top, 50)
            
            // Bottom Sheet
            VStack {
                Spacer()
                
                LinearGradient(
                    colors: [
                        Color.clear,
                        Theme.Colors.backgroundOverlay,
                        Theme.Colors.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
                .overlay(
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
                    .padding(.bottom, 90)
                )
            }
        }
        .onChange(of: placeViewModel.selectedPlace) { place in
            if let place = place {
                viewModel.updateRegion(latitude: place.latitude, longitude: place.longitude)
                Task {
                    await viewModel.fetchRoute(destinationLat: place.latitude, destinationLng: place.longitude)
                }
            }
        }
        .onChange(of: locationManager.location) { location in
            if let location = location, placeViewModel.selectedPlace == nil {
                viewModel.updateRegion(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            }
        }
        .onAppear {
            if let location = locationManager.location {
                viewModel.updateRegion(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            } else {
                viewModel.updateRegion(latitude: defaultLat, longitude: defaultLng)
            }
        }
    }
    
    private var annotations: [MapAnnotation] {
        if let place = placeViewModel.selectedPlace {
            return [MapAnnotation(coordinate: place.coordinate)]
        }
        return []
    }
}

struct MapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// Note: For proper polyline rendering, use MKMapView with MKPolyline
// This is a placeholder - full implementation would require UIViewRepresentable

struct UserLocationIndicator: View {
    let coordinate: CLLocationCoordinate2D
    
    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            
            ZStack {
                // Outer ring
                Circle()
                    .fill(Theme.Colors.gradientStart.opacity(0.35))
                    .frame(width: 80, height: 80)
                    .position(x: centerX, y: centerY)
                
                // Middle ring
                Circle()
                    .stroke(Theme.Colors.gradientStart.opacity(0.3), lineWidth: 2)
                    .frame(width: 64, height: 64)
                    .position(x: centerX, y: centerY)
                
                // Center dot
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.gradientStart, Theme.Colors.gradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Theme.Colors.textPrimary, lineWidth: 4)
                    )
                    .position(x: centerX, y: centerY)
            }
        }
    }
}

