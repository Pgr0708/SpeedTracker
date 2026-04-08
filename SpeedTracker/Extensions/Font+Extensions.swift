//
//  Font+Extensions.swift
//  SpeedTracker
//
//  Custom font extensions
//

import SwiftUI

extension Font {
    
    // MARK: - Orbitron (Headings/Speed/Branding)
    static func orbitron(_ size: CGFloat) -> Font {
        .custom(AppConstants.Typography.orbitronBold, size: size)
    }
    
    static var displayLarge: Font {
        .orbitron(AppConstants.Typography.displayLarge)
    }
    
    static var displayMedium: Font {
        .orbitron(AppConstants.Typography.displayMedium)
    }
    
    static var displaySmall: Font {
        .orbitron(AppConstants.Typography.displaySmall)
    }
    
    static var headingLarge: Font {
        .orbitron(AppConstants.Typography.headingLarge)
    }
    
    static var headingMedium: Font {
        .orbitron(AppConstants.Typography.headingMedium)
    }
    
    static var headingSmall: Font {
        .orbitron(AppConstants.Typography.headingSmall)
    }
    
    // MARK: - Rajdhani (UI/Buttons/Labels)
    static func rajdhaniMedium(_ size: CGFloat) -> Font {
        .custom(AppConstants.Typography.rajdhaniMedium, size: size)
    }
    
    static func rajdhaniRegular(_ size: CGFloat) -> Font {
        .custom(AppConstants.Typography.rajdhaniRegular, size: size)
    }
    
    static var bodyLarge: Font {
        .rajdhaniMedium(AppConstants.Typography.bodyLarge)
    }
    
    static var bodyMedium: Font {
        .rajdhaniMedium(AppConstants.Typography.bodyMedium)
    }
    
    static var bodySmall: Font {
        .rajdhaniRegular(AppConstants.Typography.bodySmall)
    }
    
    static var caption: Font {
        .rajdhaniRegular(AppConstants.Typography.caption)
    }
    
    static var button: Font {
        .rajdhaniMedium(AppConstants.Typography.bodyMedium)
    }
    
    static var label: Font {
        .rajdhaniMedium(AppConstants.Typography.bodySmall)
    }
}
