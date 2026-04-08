//
//  SpeedTrackerApp.swift
//  SpeedTracker
//
//  App entry point with proper flow:
//  Language → Onboarding → Paywall → Preferences → Permissions → Home
//

import SwiftUI

@main
struct SpeedTrackerApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    
    @AppStorage(AppConstants.UserDefaultsKeys.hasSelectedLanguage)
    private var hasSelectedLanguage = false
    
    @AppStorage(AppConstants.UserDefaultsKeys.hasCompletedOnboarding)
    private var hasCompletedOnboarding = false
    
    @AppStorage(AppConstants.UserDefaultsKeys.hasCompletedPaywall)
    private var hasCompletedPaywall = false
    
    @AppStorage(AppConstants.UserDefaultsKeys.hasCompletedPreferences)
    private var hasCompletedPreferences = false
    
    @State private var hasGrantedPermissions = false
    
    init() {
        // Enable haptics by default
        if UserDefaults.standard.object(forKey: AppConstants.UserDefaultsKeys.isHapticEnabled) == nil {
            UserDefaults.standard.set(true, forKey: AppConstants.UserDefaultsKeys.isHapticEnabled)
        }
        // Default dark mode
        if UserDefaults.standard.object(forKey: AppConstants.UserDefaultsKeys.isDarkModeEnabled) == nil {
            UserDefaults.standard.set(true, forKey: AppConstants.UserDefaultsKeys.isDarkModeEnabled)
        }
        // Default speed limits
        if UserDefaults.standard.object(forKey: AppConstants.UserDefaultsKeys.maxSpeedLimit) == nil {
            UserDefaults.standard.set(120.0, forKey: AppConstants.UserDefaultsKeys.maxSpeedLimit)
        }
        if UserDefaults.standard.object(forKey: AppConstants.UserDefaultsKeys.minSpeedLimit) == nil {
            UserDefaults.standard.set(0.0, forKey: AppConstants.UserDefaultsKeys.minSpeedLimit)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !hasSelectedLanguage {
                    LanguageSelectionView()
                } else if !hasCompletedOnboarding {
                    OnboardingContainerView()
                } else if !hasCompletedPaywall {
                    PaywallView()
                } else if !hasCompletedPreferences {
                    PreferencesSetupView()
                } else if !hasGrantedPermissions {
                    PermissionsView(hasGrantedPermissions: $hasGrantedPermissions)
                } else {
                    MainTabView()
                }
            }
            .environmentObject(themeManager)
            .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
            .onAppear {
                // If user has been through everything before, skip permissions check
                if hasCompletedPreferences {
                    let locManager = LocationManager.shared
                    if locManager.hasLocationPermission {
                        hasGrantedPermissions = true
                    }
                }
            }
        }
    }
}
