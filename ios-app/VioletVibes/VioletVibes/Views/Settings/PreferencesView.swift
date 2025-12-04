//
//  PreferencesView.swift
//  VioletVibes
//

import SwiftUI

struct PreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserSession.self) private var session

    @State private var selectedCategories: Set<String> = []
    @State private var budgetSelection: BudgetOption = .noPreference
    @State private var selectedDietaryRestrictions: Set<String> = []
    @State private var walkingDistance: WalkingDistanceOption = .noPreference
    @State private var hobbies: String = ""
    @State private var isSaving = false

    private let storage = StorageService.shared
    private let api = APIService.shared

    private let categoryOptions = [
        "Study Spots / Cozy Cafés",
        "Free Events & Pop-Ups",
        "Food Around Campus",
        "Nightlife",
        "Explore All / I'm open to anything"
    ]

    private let dietaryOptions = [
        "Vegetarian",
        "Vegan",
        "Halal",
        "Kosher",
        "Gluten-Free",
        "Dairy-Free",
        "Pork-Free",
        "Seafood Allergy",
        "Other"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
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

                // Blur Shapes
                GeometryReader { geometry in
                    Circle()
                        .fill(Theme.Colors.gradientStart.opacity(0.15))
                        .frame(width: 300, height: 300)
                        .offset(x: -50, y: -100)
                        .blur(radius: 60)

                    Circle()
                        .fill(Theme.Colors.gradientStart.opacity(0.12))
                        .frame(width: 250, height: 250)
                        .offset(x: geometry.size.width - 200, y: geometry.size.height - 200)
                        .blur(radius: 50)
                }
                .allowsHitTesting(false)

                ScrollView {
                    VStack(spacing: Theme.Spacing.`4xl`) {
                        Spacer()
                            .frame(height: 20)

                        // Categories
                        PreferenceSectionView(title: "What are you looking for?") {
                            LazyVStack(spacing: Theme.Spacing.md) {
                                ForEach(categoryOptions, id: \.self) { category in
                                    PreferenceCheckbox(
                                        title: category,
                                        isSelected: selectedCategories.contains(category)
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            if selectedCategories.contains(category) {
                                                selectedCategories.remove(category)
                                            } else {
                                                selectedCategories.insert(category)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.`2xl`)

                        // Budget
                        PreferenceSectionView(title: "Budget (Optional)") {
                            BudgetSelectorView(selection: $budgetSelection)
                        }
                        .padding(.horizontal, Theme.Spacing.`2xl`)

                        // Dietary
                        PreferenceSectionView(title: "Dietary Restrictions") {
                            LazyVStack(spacing: Theme.Spacing.md) {
                                ForEach(dietaryOptions, id: \.self) { restriction in
                                    PreferenceCheckbox(
                                        title: restriction,
                                        isSelected: selectedDietaryRestrictions.contains(restriction)
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            if selectedDietaryRestrictions.contains(restriction) {
                                                selectedDietaryRestrictions.remove(restriction)
                                            } else {
                                                selectedDietaryRestrictions.insert(restriction)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.`2xl`)

                        // Walking distance
                        PreferenceSectionView(title: "Walking Distance from Campus") {
                            WalkingDistanceSelectorView(selection: $walkingDistance)
                        }
                        .padding(.horizontal, Theme.Spacing.`2xl`)

                        // Hobbies
                        PreferenceSectionView(title: "Hobbies / Interests (Optional)") {
                            TextField("Tell us about your interests", text: $hobbies, axis: .vertical)
                                .themeFont(size: .base)
                                .foregroundColor(Theme.Colors.textPrimary)
                                .padding(Theme.Spacing.`2xl`)
                                .background(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                        .stroke(Theme.Colors.border, lineWidth: 1)
                                )
                                .cornerRadius(Theme.BorderRadius.md)
                                .lineLimit(3...6)
                        }
                        .padding(.horizontal, Theme.Spacing.`2xl`)

                        // Save
                        Button(action: {
                            savePreferences()
                        }) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Save Preferences")
                                        .themeFont(size: .lg, weight: .bold)
                                        .foregroundColor(Theme.Colors.textPrimary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.lg)
                            .background(
                                LinearGradient(
                                    colors: [Theme.Colors.gradientStart, Theme.Colors.gradientEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(Theme.BorderRadius.md)
                        }
                        .disabled(isSaving)
                        .opacity(isSaving ? 0.5 : 1.0)
                        .padding(.horizontal, Theme.Spacing.`2xl`)
                        .padding(.bottom, Theme.Spacing.`4xl`)
                    }
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.gradientStart)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .task {
                await loadPreferences()
            }
        }
    }

    private func loadPreferences() async {
        // Prefer live session (which should already be merged from backend),
        // fall back to storage if it's still default.
        var prefs = session.preferences
        if prefs == UserPreferences() {
            let local = await storage.userPreferences
            prefs = local
        }

        await MainActor.run {
            selectedCategories = prefs.categories
            budgetSelection = BudgetOption.fromBudgetRange(min: prefs.budgetMin, max: prefs.budgetMax)
            selectedDietaryRestrictions = prefs.dietaryRestrictions
            walkingDistance = WalkingDistanceOption.fromMinutes(prefs.maxWalkMinutes)
            hobbies = prefs.hobbies ?? ""
        }
    }

    private func savePreferences() {
        isSaving = true

        Task {
            let (budgetMin, budgetMax) = budgetSelection.toBudgetRange()
            let maxWalkMinutes = walkingDistance.toMinutes()

            var prefs = session.preferences
            prefs.categories = selectedCategories
            prefs.budgetMin = budgetMin
            prefs.budgetMax = budgetMax
            prefs.dietaryRestrictions = selectedDietaryRestrictions
            prefs.maxWalkMinutes = maxWalkMinutes
            prefs.hobbies = hobbies.isEmpty ? nil : hobbies

            do {
                if let jwt = session.jwt {
                    let backendPrefs = try await api.saveUserPreferences(preferences: prefs, jwt: jwt)
                    prefs = UserPreferences.fromBackendPreferencesPayload(backendPrefs, existing: prefs)
                }

                await storage.saveUserPreferences(prefs)
                session.preferences = prefs

                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                print("Preferences save error:", error)
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Budget / Distance helpers

extension BudgetOption {
    static func fromBudgetRange(min: Int?, max: Int?) -> BudgetOption {
        guard let min = min, let max = max else {
            return .noPreference
        }

        if min <= 20 && max <= 20 {
            return .low
        } else if min <= 50 && max <= 50 {
            return .medium
        } else {
            return .high
        }
    }
}

extension WalkingDistanceOption {
    static func fromMinutes(_ minutes: Int?) -> WalkingDistanceOption {
        guard let minutes = minutes else {
            return .noPreference
        }

        switch minutes {
        case 5...10:
            return .fiveToTen
        case 11...15:
            return .tenToFifteen
        case 16...20:
            return .fifteenToTwenty
        default:
            return .noPreference
        }
    }
}
