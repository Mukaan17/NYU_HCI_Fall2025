//
//  AppStateManager.swift
//  VioletVibes
//
//  Industry-standard app state management using state machine pattern
//

import Foundation
import SwiftUI
import Observation

/// App navigation state - single source of truth for app flow
enum AppNavigationState: Equatable {
    case loading
    case unauthenticated(showWelcome: Bool)  // showWelcome: true = WelcomeView, false = LoginView
    case authenticated(needsOnboarding: Bool)  // needsOnboarding: true = Preferences, false = Dashboard
}

/// App state manager - manages app lifecycle and navigation state
@Observable
final class AppStateManager {
    // MARK: - State
    var navigationState: AppNavigationState = .loading
    var isInitialized: Bool = false
    
    private let storage = StorageService.shared
    
    // MARK: - Initialization
    
    /// Initialize app state from storage
    /// This is the single source of truth for app initialization
    @MainActor
    func initialize(userSession: UserSession, onboardingViewModel: OnboardingViewModel) async {
        guard !isInitialized else {
            print("⚠️ AppStateManager: Already initialized, skipping")
            return
        }
        
        print("🚀 AppStateManager: Initializing app state...")
        
        // Step 1: Load session from storage (authoritative source)
        let loadedSession = await storage.loadUserSession()
        let hasValidSession = loadedSession.jwt != nil && !(loadedSession.jwt?.isEmpty ?? true)
        
        print("🔍 AppStateManager: Session loaded - hasValidSession: \(hasValidSession)")
        
        // Step 2: Update UserSession with loaded data
        userSession.jwt = loadedSession.jwt
        
        // Step 3: Determine navigation state based on session
        if hasValidSession {
            // User is authenticated - determine onboarding status
            // CRITICAL: For logged-in users with valid sessions, default to dashboard
            // Only show preferences screen for new signups who haven't completed preferences
            
            // Load userAccount first (needed for user-specific storage checks)
            let userAccount = await storage.userAccount
            
            // Check onboarding status (will use userAccount if available)
            await onboardingViewModel.checkOnboardingStatus()
            
            // Determine if onboarding is needed
            // Strategy: 
            // 1. If userAccount exists and has email, check explicit onboarding status
            // 2. If onboarding status is false but user has valid session, they're likely an existing user
            //    who logged in before the fix - default to dashboard
            // 3. Only show preferences for new signups who explicitly need onboarding
            let needsOnboarding: Bool
            if let account = userAccount, !account.email.isEmpty {
                // UserAccount is loaded with email - check explicit onboarding status
                let completedOnboarding = await storage.hasCompletedOnboardingSurvey
                
                // If onboarding status is false but user has valid session, they're an existing logged-in user
                // Default to dashboard (they logged in before, so they should go to dashboard)
                // Only new signups who haven't completed preferences should see preferences screen
                if !completedOnboarding {
                    // Check if this is a returning user (has logged in before) vs new signup
                    // If userAccount has hasLoggedIn = true, they've logged in before - go to dashboard
                    if account.hasLoggedIn {
                        print("⚠️ AppStateManager: User has valid session but onboarding status is false - likely existing user, defaulting to dashboard")
                        // Update onboarding status to true for future restarts
                        await storage.setHasCompletedOnboardingSurvey(true)
                        needsOnboarding = false
                    } else {
                        // New signup who hasn't completed onboarding
                        needsOnboarding = true
                    }
                } else {
                    needsOnboarding = false
                }
                
                print("✅ AppStateManager: User authenticated with account (\(account.email)) - hasCompletedOnboardingSurvey: \(completedOnboarding), needsOnboarding: \(needsOnboarding)")
            } else {
                // UserAccount not loaded or empty - for existing sessions with valid JWT, default to dashboard
                // This handles cases where userAccount might not be loaded yet but user has valid session
                print("⚠️ AppStateManager: UserAccount not loaded or empty, but user has valid session - defaulting to dashboard")
                needsOnboarding = false // Default to dashboard for existing logged-in users
            }
            
            navigationState = .authenticated(needsOnboarding: needsOnboarding)
            
            // Update onboarding flags
            onboardingViewModel.hasLoggedIn = true
        } else {
            // User is not authenticated - determine if they've seen welcome
            await onboardingViewModel.checkOnboardingStatus()
            let hasSeenWelcome = onboardingViewModel.hasSeenWelcome
            
            // CRITICAL: If no session exists, ensure clean state
            // This handles the case after logout
            await ensureUnauthenticatedState(onboardingViewModel: onboardingViewModel)
            
            print("⚠️ AppStateManager: User not authenticated - hasSeenWelcome: \(onboardingViewModel.hasSeenWelcome)")
            navigationState = .unauthenticated(showWelcome: !onboardingViewModel.hasSeenWelcome)
        }
        
        isInitialized = true
        print("✅ AppStateManager: Initialization complete - state: \(navigationState)")
    }
    
    /// Ensure clean unauthenticated state (called after logout or when no session exists)
    private func ensureUnauthenticatedState(onboardingViewModel: OnboardingViewModel) async {
        // Clear all onboarding flags to ensure clean state
        await storage.clearAllWelcomeStatuses()
        await storage.clearAllPermissionsStatuses()
        await storage.clearAllOnboardingStatuses()
        
        // Set flags to false explicitly
        await storage.setHasSeenWelcome(false)
        await storage.setHasCompletedPermissions(false)
        await storage.setHasCompletedOnboardingSurvey(false)
        await storage.setHasLoggedIn(false)
        
        // Update view model to match
        await MainActor.run {
            onboardingViewModel.hasSeenWelcome = false
            onboardingViewModel.hasCompletedPermissions = false
            onboardingViewModel.hasCompletedOnboardingSurvey = false
            onboardingViewModel.hasLoggedIn = false
        }
        
        print("🔄 AppStateManager: Ensured clean unauthenticated state")
    }
    
    // MARK: - State Transitions
    
    /// Handle authentication state change (login/signup)
    @MainActor
    func handleAuthentication(
        userSession: UserSession,
        onboardingViewModel: OnboardingViewModel,
        needsOnboarding: Bool
    ) async {
        guard userSession.jwt != nil else {
            print("⚠️ AppStateManager: handleAuthentication called but no JWT present")
            return
        }
        
        print("🔐 AppStateManager: User authenticated - needsOnboarding: \(needsOnboarding)")
        navigationState = .authenticated(needsOnboarding: needsOnboarding)
        onboardingViewModel.hasLoggedIn = true
    }
    
    /// Handle logout - reset to unauthenticated state
    @MainActor
    func handleLogout(
        userSession: UserSession,
        onboardingViewModel: OnboardingViewModel
    ) async {
        print("🚪 AppStateManager: Handling logout...")
        
        // Clear session in memory
        userSession.jwt = nil
        userSession.preferences = UserPreferences()
        userSession.settings = nil
        
        // Clear session from storage
        await storage.clearUserSession()
        
        // Verify session is cleared
        let verifySession = await storage.loadUserSession()
        if verifySession.jwt != nil {
            print("⚠️ AppStateManager: Session still exists after clearing, force clearing...")
            // Force clear all session keys
            let userDefaults = UserDefaults.standard
            let allKeys = userDefaults.dictionaryRepresentation().keys
            for key in allKeys {
                if key.hasPrefix("vv_user_session") {
                    userDefaults.removeObject(forKey: key)
                }
            }
        }
        
        // Clear all user data
        await clearAllUserData()
        
        // Reset to unauthenticated state with welcome screen
        await ensureUnauthenticatedState(onboardingViewModel: onboardingViewModel)
        navigationState = .unauthenticated(showWelcome: true)
        
        print("✅ AppStateManager: Logout complete - returning to welcome screen")
    }
    
    /// Clear all user-specific data
    private func clearAllUserData() async {
        await storage.clearCurrentUserHomeAddress()
        await storage.clearCurrentUserOnboardingStatus()
        await storage.clearCurrentUserPreferences()
        await storage.clearCurrentUserTrustedContacts()
        await storage.clearCurrentUserWelcomeStatus()
        await storage.clearCurrentUserPermissionsStatus()
        await storage.clearCurrentUserCalendarOAuthStatus()
        
        // Clear user account
        await storage.saveUserAccount(UserAccount(email: "", firstName: "", hasLoggedIn: false))
        await storage.setHasLoggedIn(false)
    }
    
    /// Handle welcome screen completion
    @MainActor
    func handleWelcomeCompleted(onboardingViewModel: OnboardingViewModel) async {
        await onboardingViewModel.markWelcomeSeen()
        navigationState = .unauthenticated(showWelcome: false)
        print("✅ AppStateManager: Welcome completed - showing login")
    }
    
    /// Handle onboarding completion
    @MainActor
    func handleOnboardingCompleted(onboardingViewModel: OnboardingViewModel) async {
        await onboardingViewModel.markOnboardingSurveyCompleted()
        if case .authenticated = navigationState {
            navigationState = .authenticated(needsOnboarding: false)
        }
        print("✅ AppStateManager: Onboarding completed - showing dashboard")
    }
    
}
