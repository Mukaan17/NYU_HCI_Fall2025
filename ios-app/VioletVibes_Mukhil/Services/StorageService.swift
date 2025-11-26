//
//  StorageService.swift
//  VioletVibes
//

import Foundation

actor StorageService {
    static let shared = StorageService()
    
    nonisolated private let userDefaults = UserDefaults.standard
    
    private enum Keys {
        static let hasSeenWelcome = "hasSeenWelcome"
        static let hasCompletedPermissions = "hasCompletedPermissions"
    }
    
    nonisolated private init() {}
    
    // MARK: - Welcome
    var hasSeenWelcome: Bool {
        get { userDefaults.bool(forKey: Keys.hasSeenWelcome) }
    }
    
    func setHasSeenWelcome(_ value: Bool) {
        userDefaults.set(value, forKey: Keys.hasSeenWelcome)
    }
    
    // MARK: - Permissions
    var hasCompletedPermissions: Bool {
        get { userDefaults.bool(forKey: Keys.hasCompletedPermissions) }
    }
    
    func setHasCompletedPermissions(_ value: Bool) {
        userDefaults.set(value, forKey: Keys.hasCompletedPermissions)
    }
}

