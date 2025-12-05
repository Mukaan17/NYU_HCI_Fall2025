//
//  OnboardingViewModel.swift
//  VioletVibes
//

import Foundation
import SwiftUI
import Observation

@Observable
final class OnboardingViewModel {
    var hasSeenWelcome: Bool = false
    var hasCompletedPermissions: Bool = false
    var hasLoggedIn: Bool = false
    var hasCompletedOnboardingSurvey: Bool = false
    
    private let storage = StorageService.shared
    
    func checkOnboardingStatus() async {
        hasSeenWelcome = await storage.hasSeenWelcome
        hasCompletedPermissions = await storage.hasCompletedPermissions
        hasLoggedIn = await storage.hasLoggedIn
        
        // Check onboarding survey status - ensure userAccount is available for user-specific checks
        // For logged-in users, check user-specific storage
        if hasLoggedIn {
            // Ensure userAccount is loaded before checking user-specific onboarding status
            let userAccount = await storage.userAccount
            if userAccount != nil {
                // Onboarding survey completion is user-specific
                hasCompletedOnboardingSurvey = await storage.hasCompletedOnboardingSurvey
                print("🔍 OnboardingViewModel: User logged in, hasCompletedOnboardingSurvey: \(hasCompletedOnboardingSurvey)")
            } else {
                // UserAccount not loaded yet - default to false (needs onboarding)
                // This will be corrected once userAccount is loaded
                hasCompletedOnboardingSurvey = false
                print("⚠️ OnboardingViewModel: UserAccount not loaded, defaulting hasCompletedOnboardingSurvey to false")
            }
        } else {
            hasCompletedOnboardingSurvey = false
        }
    }
    
    func markWelcomeSeen() {
        Task { @MainActor in
            await storage.setHasSeenWelcome(true)
        hasSeenWelcome = true
        }
    }
    
    func markPermissionsCompleted() {
        Task { @MainActor in
            await storage.setHasCompletedPermissions(true)
        hasCompletedPermissions = true
        }
    }
    
    func markLoggedIn() {
        Task { @MainActor in
            await storage.setHasLoggedIn(true)
            hasLoggedIn = true
        }
    }
    
    func markOnboardingSurveyCompleted() {
        Task { @MainActor in
            await storage.setHasCompletedOnboardingSurvey(true)
            hasCompletedOnboardingSurvey = true
        }
    }
    
    func resetOnboarding() {
        Task { @MainActor in
            await storage.resetOnboarding()
            hasSeenWelcome = false
            hasCompletedPermissions = false
            hasLoggedIn = false
            hasCompletedOnboardingSurvey = false
        }
    }
}

