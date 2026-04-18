//
//  SpeedTrackerApp.swift
//  SpeedTracker
//
import SwiftUI

@main
struct SpeedTrackerApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var authService = AuthService.shared
    @StateObject private var purchaseService = PurchaseService.shared
    @StateObject private var cloudKitService = CloudKitService.shared
    @StateObject private var localizationManager = LocalizationManager.shared

    @AppStorage(AppConstants.UserDefaultsKeys.hasSelectedLanguage) private var hasSelectedLanguage = false
    @AppStorage(AppConstants.UserDefaultsKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(AppConstants.UserDefaultsKeys.hasCompletedPaywall) private var hasCompletedPaywall = false
    @AppStorage(AppConstants.UserDefaultsKeys.hasCompletedPreferences) private var hasCompletedPreferences = false
    @AppStorage(AppConstants.UserDefaultsKeys.didLogOut) private var didLogOut = false

    @State private var hasGrantedPermissions = false
    @State private var showSplash = true

    init() {
        setDefaults()
        PurchaseService.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView { showSplash = false }
                } else if !hasSelectedLanguage {
                    LanguageSelectionView()
                } else if !hasCompletedOnboarding {
                    OnboardingContainerView()
                } else if !hasCompletedPaywall {
                    PaywallView()
                } else if !hasGrantedPermissions && !hasCompletedPreferences {
                    PermissionsView(hasGrantedPermissions: $hasGrantedPermissions)
                } else if !hasCompletedPreferences {
                    PreferencesSetupView()
                } else {
                    MainTabView()
                }
            }
            .environmentObject(themeManager)
            .environmentObject(authService)
            .environmentObject(purchaseService)
            .environmentObject(cloudKitService)
            .environmentObject(localizationManager)
            .environment(\.locale, localizationManager.currentLocale)
            .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
            .onAppear {
                authService.checkCredentialState()
                if hasCompletedPreferences && LocationManager.shared.hasLocationPermission {
                    hasGrantedPermissions = true
                }
            }
        }
    }

    private func setDefaults() {
        let ud = UserDefaults.standard
        didLogOut = false
        if ud.object(forKey: AppConstants.UserDefaultsKeys.isHapticEnabled) == nil { ud.set(true, forKey: AppConstants.UserDefaultsKeys.isHapticEnabled) }
        if ud.object(forKey: AppConstants.UserDefaultsKeys.isDarkModeEnabled) == nil { ud.set(true, forKey: AppConstants.UserDefaultsKeys.isDarkModeEnabled) }
        if ud.object(forKey: AppConstants.UserDefaultsKeys.maxSpeedLimit) == nil { ud.set(120.0, forKey: AppConstants.UserDefaultsKeys.maxSpeedLimit) }
        if ud.object(forKey: AppConstants.UserDefaultsKeys.minSpeedLimit) == nil { ud.set(0.0, forKey: AppConstants.UserDefaultsKeys.minSpeedLimit) }
        if ud.object(forKey: AppConstants.UserDefaultsKeys.isSoundMuted) == nil { ud.set(false, forKey: AppConstants.UserDefaultsKeys.isSoundMuted) }
    }
}
