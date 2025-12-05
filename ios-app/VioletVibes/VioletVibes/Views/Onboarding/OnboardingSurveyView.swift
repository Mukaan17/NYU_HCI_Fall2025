//
//  OnboardingSurveyView.swift
//  VioletVibes
//

import SwiftUI

struct OnboardingSurveyView: View {
    @Environment(OnboardingViewModel.self) private var onboardingViewModel
    @Environment(UserSession.self) private var userSession
    @State private var selectedCategories: Set<String> = []
    @State private var budgetSelection: BudgetOption = .noPreference
    @State private var selectedDietaryRestrictions: Set<String> = []
    @State private var walkingDistance: WalkingDistanceOption = .noPreference
    @State private var hobbies: String = ""
    @State private var isSaving = false
    
    private let storage = StorageService.shared
    private let api = APIService.shared
    
    // Category options
    private let categoryOptions = [
        "Study Spots / Cozy Cafés",
        "Free Events & Pop-Ups",
        "Food Around Campus",
        "Nightlife",
        "Explore All / I'm open to anything"
    ]
    
    // Dietary restriction options
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
                        .frame(height: 60)
                    
                    // Title
                    VStack(spacing: Theme.Spacing.sm) {
                        Text("Tell us about yourself")
                            .themeFont(size: .`3xl`, weight: .bold)
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Text("Help us personalize your experience")
                            .themeFont(size: .lg)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    
                    // What are you looking for?
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
                    
                    // Budget
                    PreferenceSectionView(title: "Budget (Optional)") {
                        BudgetSelectorView(selection: $budgetSelection)
                    }
                    
                    // Dietary Restrictions
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
                    
                    // Walking Distance
                    PreferenceSectionView(title: "Walking Distance from Campus") {
                        WalkingDistanceSelectorView(selection: $walkingDistance)
                    }
                    
                    // Hobbies/Interests
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
                    
                    // Continue Button
                    Button(action: {
                        savePreferences()
                    }) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Continue")
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
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, Theme.Spacing.`2xl`)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    private func savePreferences() {
        isSaving = true
        
        Task {
            // Convert budget selection to min/max
            let (budgetMin, budgetMax) = budgetSelection.toBudgetRange()
            
            // Convert walking distance to minutes
            let maxWalkMinutes = walkingDistance.toMinutes()
            
            let preferences = UserPreferences(
                categories: selectedCategories,
                budgetMin: budgetMin,
                budgetMax: budgetMax,
                dietaryRestrictions: selectedDietaryRestrictions,
                maxWalkMinutes: maxWalkMinutes,
                hobbies: hobbies.isEmpty ? nil : hobbies,
                googleCalendarEnabled: false,
                notificationsEnabled: false,
                usePreferencesForPersonalization: true
            )
            
            // Save preferences to backend if user is logged in
            if let jwt = userSession.jwt {
                do {
                    _ = try await api.saveUserPreferences(preferences: preferences, jwt: jwt)
                } catch {
                    print("Failed to save preferences to backend: \(error)")
                    // Continue anyway - preferences saved locally
                }
            }
            
            // Also save locally
            await storage.saveUserPreferences(preferences)
            await storage.setHasCompletedOnboardingSurvey(true)
            
            await MainActor.run {
                isSaving = false
                onboardingViewModel.markOnboardingSurveyCompleted()
            }
        }
    }
}

// MARK: - Budget Option
enum BudgetOption: String, CaseIterable {
    case noPreference = "No preference"
    case low = "$"
    case medium = "$$"
    case high = "$$$"
    
    func toBudgetRange() -> (Int?, Int?) {
        switch self {
        case .noPreference:
            return (nil, nil)
        case .low:
            return (1, 20)
        case .medium:
            return (21, 50)
        case .high:
            return (51, nil)
        }
    }
}

// MARK: - Walking Distance Option
enum WalkingDistanceOption: String, CaseIterable {
    case fiveToTen = "5–10 min"
    case tenToFifteen = "10–15 min"
    case fifteenToTwenty = "15–20 min"
    case noPreference = "No preference"
    
    func toMinutes() -> Int? {
        switch self {
        case .fiveToTen:
            return 10
        case .tenToFifteen:
            return 15
        case .fifteenToTwenty:
            return 20
        case .noPreference:
            return nil
        }
    }
}

// MARK: - Preference Section View
struct PreferenceSectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.`2xl`) {
            Text(title)
                .themeFont(size: .xl, weight: .bold)
                .foregroundColor(Theme.Colors.textPrimary)
            
            content
        }
        .padding(Theme.Spacing.`3xl`)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.BorderRadius.lg)
                    .fill(.regularMaterial)
                
                LinearGradient(
                    colors: [
                        Theme.Colors.gradientStart.opacity(0.1),
                        Theme.Colors.gradientEnd.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(Theme.BorderRadius.lg)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.BorderRadius.lg)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Preference Checkbox
struct PreferenceCheckbox: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.`2xl`) {
                Text(title)
                    .themeFont(size: .base)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(isSelected ? Theme.Colors.gradientStart : Color.clear)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Theme.Colors.gradientStart : Theme.Colors.border, lineWidth: 2)
                        )
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(Theme.Spacing.`2xl`)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                        .fill(.ultraThinMaterial)
                    
                    if !isSelected {
                        RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                            .fill(Color.black.opacity(0.3))
                    }
                    
                    if isSelected {
                        LinearGradient(
                            colors: [
                                Theme.Colors.gradientStart.opacity(0.2),
                                Theme.Colors.gradientEnd.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .cornerRadius(Theme.BorderRadius.md)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                    .stroke(isSelected ? Theme.Colors.gradientStart.opacity(0.3) : Theme.Colors.border, lineWidth: 1)
            )
            .cornerRadius(Theme.BorderRadius.md)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Budget Selector View
struct BudgetSelectorView: View {
    @Binding var selection: BudgetOption
    
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Dollar sign options in a row on top
            HStack(spacing: Theme.Spacing.md) {
                ForEach([BudgetOption.low, .medium, .high], id: \.self) { option in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selection = option
                        }
                    }) {
                        Text(option.rawValue)
                            .themeFont(size: .base, weight: selection == option ? .semiBold : .regular)
                            .foregroundColor(selection == option ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.lg)
                            .background {
                                ZStack {
                                    RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                        .fill(.ultraThinMaterial)
                                    
                                    if selection != option {
                                        RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                            .fill(Color.black.opacity(0.3))
                                    }
                                    
                                    if selection == option {
                                        LinearGradient(
                                            colors: [
                                                Theme.Colors.gradientStart.opacity(0.2),
                                                Theme.Colors.gradientEnd.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        .cornerRadius(Theme.BorderRadius.md)
                                    }
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                    .stroke(selection == option ? Theme.Colors.gradientStart.opacity(0.3) : Theme.Colors.border, lineWidth: 1)
                            )
                            .cornerRadius(Theme.BorderRadius.md)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // "No preference" button on its own row at the bottom
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selection = .noPreference
                }
            }) {
                Text(BudgetOption.noPreference.rawValue)
                    .themeFont(size: .base, weight: selection == .noPreference ? .semiBold : .regular)
                    .foregroundColor(selection == .noPreference ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.lg)
                    .background {
                        ZStack {
                            RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                .fill(.ultraThinMaterial)
                            
                            if selection != .noPreference {
                                RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                    .fill(Color.black.opacity(0.3))
                            }
                            
                            if selection == .noPreference {
                                LinearGradient(
                                    colors: [
                                        Theme.Colors.gradientStart.opacity(0.2),
                                        Theme.Colors.gradientEnd.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .cornerRadius(Theme.BorderRadius.md)
                            }
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                            .stroke(selection == .noPreference ? Theme.Colors.gradientStart.opacity(0.3) : Theme.Colors.border, lineWidth: 1)
                    )
                    .cornerRadius(Theme.BorderRadius.md)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Walking Distance Selector View
struct WalkingDistanceSelectorView: View {
    @Binding var selection: WalkingDistanceOption
    
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            ForEach(WalkingDistanceOption.allCases, id: \.self) { option in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selection = option
                    }
                }) {
                    HStack {
                        Text(option.rawValue)
                            .themeFont(size: .base, weight: selection == option ? .semiBold : .regular)
                            .foregroundColor(selection == option ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                        
                        Spacer()
                        
                        if selection == option {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Theme.Colors.gradientStart)
                        }
                    }
                    .padding(Theme.Spacing.`2xl`)
                    .background {
                        ZStack {
                            RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                .fill(.ultraThinMaterial)
                            
                            if selection != option {
                                RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                                    .fill(Color.black.opacity(0.3))
                            }
                            
                            if selection == option {
                                LinearGradient(
                                    colors: [
                                        Theme.Colors.gradientStart.opacity(0.2),
                                        Theme.Colors.gradientEnd.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .cornerRadius(Theme.BorderRadius.md)
                            }
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.BorderRadius.md)
                            .stroke(selection == option ? Theme.Colors.gradientStart.opacity(0.3) : Theme.Colors.border, lineWidth: 1)
                    )
                    .cornerRadius(Theme.BorderRadius.md)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

