//
//  LocalizationManager.swift
//  SpeedTracker
//
//  Localization management for 14 languages
//

import Foundation
import SwiftUI
import Combine

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: AppConstants.SupportedLanguage = .english {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: AppConstants.UserDefaultsKeys.preferredLanguage)
        }
    }
    
    private init() {
        // Load saved language
        if let savedLanguage = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.preferredLanguage),
           let language = AppConstants.SupportedLanguage(rawValue: savedLanguage) {
            currentLanguage = language
        } else {
            // Auto-detect system language
            currentLanguage = detectSystemLanguage()
        }
    }
    
    private func detectSystemLanguage() -> AppConstants.SupportedLanguage {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        
        for language in AppConstants.SupportedLanguage.allCases {
            if preferredLanguage.hasPrefix(language.rawValue) {
                return language
            }
        }
        
        return .english
    }
    
    func localized(_ key: String) -> String {
        // For now, return key. Actual localization will use .strings files
        return NSLocalizedString(key, comment: "")
    }
}

// View extension for easy localization access
extension View {
    func localized(_ key: String) -> String {
        LocalizationManager.shared.localized(key)
    }
}
