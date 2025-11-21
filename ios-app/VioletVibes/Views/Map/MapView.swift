//
//  MapView.swift
//  VioletVibes
//

import SwiftUI
import MapKit

struct MapView: View {
    @Environment(PlaceViewModel.self) private var placeViewModel
    @Environment(LocationManager.self) private var locationManager
    @State private var viewModel = MapViewModel()
    
    private let defaultLat = 40.693393
    private let defaultLng = -73.98555
    
    var body: some View {
        ZStack {
            // Map using modern iOS 17+ API
            Map(position: $viewModel.cameraPosition) {
                // User location
                if let location = locationManager.location {
                    UserAnnotation()
                }
                
                // Destination marker
                if let place = placeViewModel.selectedPlace {
                    Annotation(place.name, coordinate: place.coordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(Theme.Colors.gradientStart)
                            .font(.system(size: 32))
                    }
                }
                
                // Route polyline
                if !viewModel.polylineCoordinates.isEmpty {
                    MapPolyline(coordinates: viewModel.polylineCoordinates)
                        .stroke(Theme.Colors.gradientStart, lineWidth: 5)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
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
        .onChange(of: placeViewModel.selectedPlace) { oldValue, newValue in
            if let place = newValue {
                viewModel.updateRegion(latitude: place.latitude, longitude: place.longitude)
                Task {
                    await viewModel.fetchRoute(destinationLat: place.latitude, destinationLng: place.longitude)
                }
            }
        }
        .onChange(of: locationManager.location) { oldValue, newValue in
            if let location = newValue, placeViewModel.selectedPlace == nil {
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
}

