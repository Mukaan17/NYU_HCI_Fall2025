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
    var hasCompletedCalendarOAuth: Bool = false
    
    private let storage = StorageService.shared
    
    func checkOnboardingStatus() async {
        hasSeenWelcome = await storage.hasSeenWelcome
        hasCompletedPermissions = await storage.hasCompletedPermissions
        hasLoggedIn = await storage.hasLoggedIn
        
        // Check onboarding survey status from backend if user is logged in
        // This ensures proper isolation between users
        if hasLoggedIn {
            // Onboarding survey completion is now user-specific
            // Check from storage (which is user-scoped)
            hasCompletedOnboardingSurvey = await storage.hasCompletedOnboardingSurvey
            hasCompletedCalendarOAuth = await storage.hasCompletedCalendarOAuth
        } else {
            hasCompletedOnboardingSurvey = false
            hasCompletedCalendarOAuth = false
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
    
    func markCalendarOAuthCompleted() {
        Task { @MainActor in
            await storage.setHasCompletedCalendarOAuth(true)
            hasCompletedCalendarOAuth = true
        }
    }
    
    func resetOnboarding() {
        Task { @MainActor in
            await storage.resetOnboarding()
            hasSeenWelcome = false
            hasCompletedPermissions = false
            hasLoggedIn = false
            hasCompletedOnboardingSurvey = false
            hasCompletedCalendarOAuth = false
        }
    }
}

