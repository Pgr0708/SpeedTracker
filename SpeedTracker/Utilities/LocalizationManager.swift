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

    var currentLocale: Locale {
        Locale(identifier: currentLanguage.rawValue)
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
        bundle(for: currentLanguage).localizedString(forKey: key, value: key, table: nil)
    }

    private func bundle(for language: AppConstants.SupportedLanguage) -> Bundle {
        if let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return .main
    }
}

enum L10n {
    static func text(_ key: String) -> LocalizedStringKey {
        LocalizedStringKey(key)
    }

    static func string(_ key: String) -> String {
        LocalizationManager.shared.localized(key)
    }

    static func string(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: Locale.current, arguments: arguments)
    }
}
