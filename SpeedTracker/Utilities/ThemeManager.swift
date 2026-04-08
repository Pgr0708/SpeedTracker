//
//  ThemeManager.swift
//  SpeedTracker
//
//  Manages theme (dark/light) and accent color preferences
//

import SwiftUI
import Combine

@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage(AppConstants.UserDefaultsKeys.isDarkModeEnabled) var isDarkMode: Bool = true
    @AppStorage(AppConstants.UserDefaultsKeys.themeColor) private var themeColorRaw: String = AppConstants.ThemeColor.blue.rawValue
    
    var themeColor: AppConstants.ThemeColor {
        get { AppConstants.ThemeColor(rawValue: themeColorRaw) ?? .blue }
        set { 
            themeColorRaw = newValue.rawValue
            objectWillChange.send()
        }
    }
    
    // MARK: - Adaptive Colors
    var primaryColor: Color { themeColor.primaryColor }
    var secondaryColor: Color { themeColor.secondaryColor }
    var primaryGradient: LinearGradient { themeColor.gradient }
    
    var backgroundColor: Color {
        isDarkMode ? AppConstants.Colors.deepNavy : AppConstants.Colors.lightBg
    }
    
    var surfaceColor: Color {
        isDarkMode ? AppConstants.Colors.darkBlue : AppConstants.Colors.lightSurface
    }
    
    var cardColor: Color {
        isDarkMode ? AppConstants.Colors.surfaceBlue : AppConstants.Colors.lightCard
    }
    
    var textPrimary: Color {
        isDarkMode ? AppConstants.Colors.textPrimary : AppConstants.Colors.textPrimaryLight
    }
    
    var textSecondary: Color {
        isDarkMode ? AppConstants.Colors.textSecondary : AppConstants.Colors.textSecondaryLight
    }
    
    var textTertiary: Color {
        isDarkMode ? AppConstants.Colors.textTertiary : AppConstants.Colors.textTertiaryLight
    }
    
    var backgroundGradient: LinearGradient {
        isDarkMode ? AppConstants.Colors.backgroundGradient : AppConstants.Colors.lightBackgroundGradient
    }
    
    var colorScheme: ColorScheme {
        isDarkMode ? .dark : .light
    }
    
    var glassBackground: some ShapeStyle {
        isDarkMode ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.regularMaterial)
    }
    
    private init() {}
}
