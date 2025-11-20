//
//  StorageService.swift
//  VioletVibes
//

import Foundation

class StorageService {
    static let shared = StorageService()
    
    private let userDefaults = UserDefaults.standard
    
    private enum Keys {
        static let hasSeenWelcome = "hasSeenWelcome"
        static let hasCompletedPermissions = "hasCompletedPermissions"
    }
    
    private init() {}
    
    // MARK: - Welcome
    var hasSeenWelcome: Bool {
        get { userDefaults.bool(forKey: Keys.hasSeenWelcome) }
        set { userDefaults.set(newValue, forKey: Keys.hasSeenWelcome) }
    }
    
    // MARK: - Permissions
    var hasCompletedPermissions: Bool {
        get { userDefaults.bool(forKey: Keys.hasCompletedPermissions) }
        set { userDefaults.set(newValue, forKey: Keys.hasCompletedPermissions) }
    }
}

