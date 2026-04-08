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
    
    // MARK: - Sport Colors
    enum Colors {
        // Primary Palette
        static let electricBlue = Color(hex: "00D9FF")
        static let neonOrange = Color(hex: "FF6B35")
        static let limeGreen = Color(hex: "39FF14")
        
        // Background
        static let deepNavy = Color(hex: "0A1128")
        static let darkBlue = Color(hex: "1E2749")
        static let surfaceBlue = Color(hex: "2A3B5F")
        
        // Text
        static let textPrimary = Color.white
        static let textSecondary = Color(hex: "B8C1EC")
        static let textTertiary = Color(hex: "7B8AB8")
        
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
        static let preferredSpeedUnit = "preferredSpeedUnit"
        static let preferredLanguage = "preferredLanguage"
        static let isHapticEnabled = "isHapticEnabled"
        static let isDarkModeEnabled = "isDarkModeEnabled"
    }
    
    // MARK: - Speed Units
    enum SpeedUnit: String, CaseIterable {
        case kmh = "km/h"
        case mph = "mph"
        case ms = "m/s"
        case knots = "knots"
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
