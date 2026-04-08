//
//  Haptics.swift
//  SpeedTracker
//
//  Haptic feedback manager
//

import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.isHapticEnabled) else { return }
        
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.isHapticEnabled) else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        guard UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.isHapticEnabled) else { return }
        
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
