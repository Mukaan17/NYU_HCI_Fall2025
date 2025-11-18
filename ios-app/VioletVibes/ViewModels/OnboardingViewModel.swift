//
//  OnboardingViewModel.swift
//  VioletVibes
//

import Foundation
import SwiftUI

class OnboardingViewModel: ObservableObject {
    @Published var hasSeenWelcome: Bool = false
    @Published var hasCompletedPermissions: Bool = false
    
    private let storage = StorageService.shared
    
    func checkOnboardingStatus() async {
        await MainActor.run {
            hasSeenWelcome = storage.hasSeenWelcome
            hasCompletedPermissions = storage.hasCompletedPermissions
        }
    }
    
    func markWelcomeSeen() {
        storage.hasSeenWelcome = true
        hasSeenWelcome = true
    }
    
    func markPermissionsCompleted() {
        storage.hasCompletedPermissions = true
        hasCompletedPermissions = true
    }
}

