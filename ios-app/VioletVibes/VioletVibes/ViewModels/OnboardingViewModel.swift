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
    
    private let storage = StorageService.shared
    
    func checkOnboardingStatus() async {
        hasSeenWelcome = await storage.hasSeenWelcome
        hasCompletedPermissions = await storage.hasCompletedPermissions
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
}

