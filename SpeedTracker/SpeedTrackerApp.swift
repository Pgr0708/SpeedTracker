//
//  SpeedTrackerApp.swift
//  SpeedTracker
//
//  Created by Minaxi on 08/04/26.
//

import SwiftUI

@main
struct SpeedTrackerApp: App {
    @AppStorage(AppConstants.UserDefaultsKeys.hasCompletedOnboarding) 
    private var hasCompletedOnboarding = false
    
    init() {
        // Enable haptics by default
        if UserDefaults.standard.object(forKey: AppConstants.UserDefaultsKeys.isHapticEnabled) == nil {
            UserDefaults.standard.set(true, forKey: AppConstants.UserDefaultsKeys.isHapticEnabled)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingContainerView()
            }
        }
    }
}
