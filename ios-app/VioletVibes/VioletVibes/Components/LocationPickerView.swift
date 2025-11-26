//
//  LocationPickerView.swift
//  VioletVibes
//

import SwiftUI
import MapKit

struct LocationPickerView: View {
    @Binding var address: String
    @State private var searchText: String = ""
    @State private var searchCompleter = MKLocalSearchCompleter()
    @State private var searchResults: [MKLocalSearchCompletion] = []
    @State private var isSearching = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Text Field
            TextField("Enter address", text: $searchText)
                .themeFont(size: .base)
                .foregroundColor(Theme.Colors.textPrimary)
                .padding(Theme.Spacing.`2xl`)
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                        .stroke(isTextFieldFocused ? Theme.Colors.gradientStart.opacity(0.3) : Theme.Colors.border, lineWidth: 1)
                )
                .cornerRadius(Theme.BorderRadius.md)
                .focused($isTextFieldFocused)
                .onChange(of: searchText) { oldValue, newValue in
                    // Debounce search
                    Task {
                        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                        if searchText == newValue {
                            performSearch(query: newValue)
                        }
                    }
                }
            
            // Search Results
            if !searchResults.isEmpty && isTextFieldFocused {
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.xs) {
                        ForEach(searchResults, id: \.self) { result in
                            LocationSuggestionRow(completion: result) {
                                selectAddress(result)
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
                .padding(Theme.Spacing.md)
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                            .fill(.regularMaterial)
                        
                        LinearGradient(
                            colors: [
                                Theme.Colors.gradientStart.opacity(0.1),
                                Theme.Colors.gradientEnd.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .cornerRadius(Theme.BorderRadius.md)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
                .cornerRadius(Theme.BorderRadius.md)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onAppear {
            setupSearchCompleter()
            searchText = address
        }
    }
    
    private func setupSearchCompleter() {
        searchCompleter.delegate = LocationCompleterDelegate { results in
            searchResults = results
        }
        searchCompleter.resultTypes = [.address, .pointOfInterest]
    }
    
    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        searchCompleter.queryFragment = query
    }
    
    private func selectAddress(_ completion: MKLocalSearchCompletion) {
        // Perform search to get full address details
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        
        search.start { response, error in
            guard let response = response, let mapItem = response.mapItems.first else {
                return
            }
            
            // Format address
            let formattedAddress = formatAddress(from: mapItem)
            
            DispatchQueue.main.async {
                address = formattedAddress
                searchText = formattedAddress
                searchResults = []
                isTextFieldFocused = false
            }
        }
    }
    
    private func formatAddress(from mapItem: MKMapItem) -> String {
        let placemark = mapItem.placemark
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
        if let state = placemark.administrativeArea {
            addressComponents.append(state)
        }
        if let zipCode = placemark.postalCode {
            addressComponents.append(zipCode)
        }
        
        return addressComponents.joined(separator: " ")
    }
}

// MARK: - Location Suggestion Row
struct LocationSuggestionRow: View {
    let completion: MKLocalSearchCompletion
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.`2xl`) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(Theme.Colors.gradientStart)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(completion.title)
                        .themeFont(size: .base, weight: .medium)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    if !completion.subtitle.isEmpty {
                        Text(completion.subtitle)
                            .themeFont(size: .sm)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
            }
            .padding(Theme.Spacing.`2xl`)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                        .fill(Color.black.opacity(0.3))
                }
            }
            .cornerRadius(Theme.BorderRadius.md)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Location Completer Delegate
class LocationCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    let onResults: ([MKLocalSearchCompletion]) -> Void
    
    init(onResults: @escaping ([MKLocalSearchCompletion]) -> Void) {
        self.onResults = onResults
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onResults(completer.results)
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        onResults([])
    }
}

