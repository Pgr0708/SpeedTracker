//
//  Constants.swift
//  SpeedTracker
//
//  Professional constants and configuration
//

import SwiftUI

enum AppConstants {
    
    // MARK: - App Info
    enum App {
        static let name = "SpeedTracker"
        static let bundleId = "com.speedtracker.app"
        static let version = "1.0.0"
    }
    
    // MARK: - Design System
    enum Design {
        // Spacing
        static let paddingXS: CGFloat = 4
        static let paddingS: CGFloat = 8
        static let paddingM: CGFloat = 16
        static let paddingL: CGFloat = 24
        static let paddingXL: CGFloat = 32
        static let paddingXXL: CGFloat = 48
        
        // Corner Radius
        static let cornerRadiusS: CGFloat = 8
        static let cornerRadiusM: CGFloat = 16
        static let cornerRadiusL: CGFloat = 24
        static let cornerRadiusXL: CGFloat = 32
        
        // Glass Morphism
        static let glassOpacity: Double = 0.15
        static let glassBlur: CGFloat = 20
        static let glassBorderOpacity: Double = 0.2
        
        // Animations
        static let animationFast: Double = 0.2
        static let animationMedium: Double = 0.3
        static let animationSlow: Double = 0.5
        static let springResponse: Double = 0.5
        static let springDampingFraction: Double = 0.7
    }
    
    // MARK: - Theme Colors
    enum ThemeColor: String, CaseIterable, Codable {
        case blue = "blue"
        case green = "green"
        case orange = "orange"
        case purple = "purple"
        case red = "red"
        case cyan = "cyan"
        
        var displayName: String {
            switch self {
            case .blue: return "Electric Blue"
            case .green: return "Lime Green"
            case .orange: return "Neon Orange"
            case .purple: return "Royal Purple"
            case .red: return "Racing Red"
            case .cyan: return "Cyber Cyan"
            }
        }

        var displayNameKey: String {
            switch self {
            case .blue: return "theme.blue"
            case .green: return "theme.green"
            case .orange: return "theme.orange"
            case .purple: return "theme.purple"
            case .red: return "theme.red"
            case .cyan: return "theme.cyan"
            }
        }
        
        var primaryColor: Color {
            switch self {
            case .blue: return Color(hex: "00D9FF")
            case .green: return Color(hex: "39FF14")
            case .orange: return Color(hex: "FF6B35")
            case .purple: return Color(hex: "9D4EDD")
            case .red: return Color(hex: "FF3B5C")
            case .cyan: return Color(hex: "00E5FF")
            }
        }
        
        var secondaryColor: Color {
            switch self {
            case .blue: return Color(hex: "0099CC")
            case .green: return Color(hex: "00CC00")
            case .orange: return Color(hex: "FF8C42")
            case .purple: return Color(hex: "7B2FBE")
            case .red: return Color(hex: "D4314A")
            case .cyan: return Color(hex: "00B8D4")
            }
        }
        
        var gradient: LinearGradient {
            LinearGradient(
                colors: [primaryColor, secondaryColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // MARK: - Adaptive Colors (Dark/Light mode)
    enum Colors {
        // Primary Palette (theme-dependent - use ThemeManager)
        static let electricBlue = Color(hex: "00D9FF")
        static let neonOrange = Color(hex: "FF6B35")
        static let limeGreen = Color(hex: "39FF14")
        
        // Background - Dark
        static let deepNavy = Color(hex: "0A1128")
        static let darkBlue = Color(hex: "1E2749")
        static let surfaceBlue = Color(hex: "2A3B5F")
        
        // Background - Light
        static let lightBg = Color(hex: "F5F7FA")
        static let lightSurface = Color(hex: "FFFFFF")
        static let lightCard = Color(hex: "F0F2F5")
        
        // Text - Dark
        static let textPrimary = Color.white
        static let textSecondary = Color(hex: "B8C1EC")
        static let textTertiary = Color(hex: "7B8AB8")
        
        // Text - Light
        static let textPrimaryLight = Color(hex: "1A1A2E")
        static let textSecondaryLight = Color(hex: "6B7280")
        static let textTertiaryLight = Color(hex: "9CA3AF")
        
        // Gradients
        static let primaryGradient = LinearGradient(
            colors: [electricBlue, Color(hex: "0099CC")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let accentGradient = LinearGradient(
            colors: [neonOrange, Color(hex: "FF8C42")],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let successGradient = LinearGradient(
            colors: [limeGreen, Color(hex: "00CC00")],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let backgroundGradient = LinearGradient(
            colors: [deepNavy, darkBlue, surfaceBlue],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let lightBackgroundGradient = LinearGradient(
            colors: [lightBg, lightSurface],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Typography
    enum Typography {
        // Font Names
        static let orbitronBold = "Orbitron-Bold"
        static let rajdhaniMedium = "Rajdhani-Medium"
        static let rajdhaniRegular = "Rajdhani-Regular"
        
        // Font Sizes
        static let displayLarge: CGFloat = 72
        static let displayMedium: CGFloat = 56
        static let displaySmall: CGFloat = 48
        static let headingLarge: CGFloat = 36
        static let headingMedium: CGFloat = 28
        static let headingSmall: CGFloat = 24
        static let bodyLarge: CGFloat = 18
        static let bodyMedium: CGFloat = 16
        static let bodySmall: CGFloat = 14
        static let caption: CGFloat = 12
    }
    
    // MARK: - Animation Names
    enum Animations {
        static let speedometer = "speedometer"
        static let onboarding1 = "onboarding_1"
        static let onboarding2 = "onboarding_2"
        static let onboarding3 = "onboarding_3"
        static let success = "success"
        static let loading = "loading"
    }
    
    // MARK: - UserDefaults Keys
    enum UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let hasSelectedLanguage = "hasSelectedLanguage"
        static let hasCompletedPaywall = "hasCompletedPaywall"
        static let hasCompletedPreferences = "hasCompletedPreferences"
        static let preferredSpeedUnit = "preferredSpeedUnit"
        static let preferredLanguage = "preferredLanguage"
        static let isHapticEnabled = "isHapticEnabled"
        static let isDarkModeEnabled = "isDarkModeEnabled"
        static let themeColor = "themeColor"
        static let maxSpeedLimit = "maxSpeedLimit"
        static let minSpeedLimit = "minSpeedLimit"
        static let isPremium = "isPremium"
        static let isHUDModeEnabled = "isHUDModeEnabled"
        static let isSoundMuted = "isSoundMuted"
        static let isMirrorModeEnabled = "isMirrorModeEnabled"
        static let didLogOut = "didLogOut"
        static let isNotificationsEnabled = "isNotificationsEnabled"
        static let userProfile = "userProfile"
        static let hasShownSplash = "hasShownSplash"
        static let pedometerSessions = "pedometerSessions"
        static let hasSeenHUDTiltTip = "hasSeenHUDTiltTip"
        static let hasSeenHUDMirrorTip = "hasSeenHUDMirrorTip"
        static let lastCloudKitSync = "lastCloudKitSync"
        static let pendingCloudKitUploads = "pendingCloudKitUploads"
        static let currentPlanName = "currentPlanName"
        static let currentProductID = "currentProductID"
        static let currentExpirationDate = "currentExpirationDate"
    }

    // MARK: - RevenueCat & IAP
    enum Purchase {
        static let revenueCatAPIKey = "appl_qMtIhfXHEBEDXsfTOfNHxUSPcgd"
        static let primaryEntitlementID = "pro"
        static let lifetimeEntitlementID = "lifetime"
        static let weeklyProductID = "speedtracker_weekly"
        static let monthlyProductID = "speedtracker_monthly"
        static let yearlyProductID = "speedtracker_yearly"
        static let lifetimeProductID = "speedtracker_lifetime"
    }

    // MARK: - URLs
    enum URLs {
        static let contactUs = "https://sites.google.com/view/inovexa"
        static let privacyPolicy = "https://sites.google.com/view/inovexa/privacy-policy"
        static let termsOfService = "https://sites.google.com/view/inovexa/terms-and-conditions"
        static let termsAndConditions = "https://sites.google.com/view/inovexa/terms-and-conditions"
        static let rateApp = "https://apps.apple.com/app/id0000000000" // replace with real App Store ID
    }

    // MARK: - iCloud
    enum CloudKit {
        static let containerID = "iCloud.container.bhavik.speedtracker"
        static let tripRecordType = "TripRecord"
        static let pedometerSessionType = "PedometerSession"
        static let userPreferencesType = "UserPreferences"
    }
    
    // MARK: - Speed Units
    enum SpeedUnit: String, CaseIterable, Codable {
        case kmh = "km/h"
        case mph = "mph"
        case ms = "m/s"
        case knots = "knots"
        
        var conversionFromMPS: Double {
            switch self {
            case .kmh: return 3.6
            case .mph: return 2.23694
            case .ms: return 1.0
            case .knots: return 1.94384
            }
        }

        var localizationKey: String {
            switch self {
            case .kmh: return "unit.kmh"
            case .mph: return "unit.mph"
            case .ms: return "unit.ms"
            case .knots: return "unit.knots"
            }
        }
    }
    
    // MARK: - Supported Languages
    enum SupportedLanguage: String, CaseIterable {
        case english = "en"
        case korean = "ko"
        case japanese = "ja"
        case greek = "el"
        case french = "fr"
        case german = "de"
        case spanish = "es"
        case portuguese = "pt"
        case chineseSimplified = "zh-Hans"
        case vietnamese = "vi"
        case portugueseBrazil = "pt-BR"
        case turkish = "tr"
        case italian = "it"
        case arabic = "ar"
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .korean: return "한국어"
            case .japanese: return "日本語"
            case .greek: return "Ελληνικά"
            case .french: return "Français"
            case .german: return "Deutsch"
            case .spanish: return "Español"
            case .portuguese: return "Português"
            case .chineseSimplified: return "简体中文"
            case .vietnamese: return "Tiếng Việt"
            case .portugueseBrazil: return "Português (Brasil)"
            case .turkish: return "Türkçe"
            case .italian: return "Italiano"
            case .arabic: return "العربية"
            }
        }
        
        var flagEmoji: String {
            switch self {
            case .english: return "🇺🇸"
            case .korean: return "🇰🇷"
            case .japanese: return "🇯🇵"
            case .greek: return "🇬🇷"
            case .french: return "🇫🇷"
            case .german: return "🇩🇪"
            case .spanish: return "🇪🇸"
            case .portuguese: return "🇵🇹"
            case .chineseSimplified: return "🇨🇳"
            case .vietnamese: return "🇻🇳"
            case .portugueseBrazil: return "🇧🇷"
            case .turkish: return "🇹🇷"
            case .italian: return "🇮🇹"
            case .arabic: return "🇸🇦"
            }
        }
        
        var isRTL: Bool {
            return self == .arabic
        }
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
