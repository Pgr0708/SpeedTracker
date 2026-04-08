//
//  AnimatedButton.swift
//  SpeedTracker
//
//  Animated button component with theme support
//

import SwiftUI

enum ButtonVariant {
    case primary
    case secondary
    case accent
    case ghost
}

struct AnimatedButton: View {
    let title: String
    let icon: String?
    let variant: ButtonVariant
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(
        _ title: String,
        icon: String? = nil,
        variant: ButtonVariant = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.variant = variant
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.impact(style: .medium)
            action()
        }) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 32)
            .background(backgroundView)
            .foregroundColor(foregroundColor)
            .cornerRadius(AppConstants.Design.cornerRadiusM)
            .shadow(color: shadowColor, radius: 15, x: 0, y: 8)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(
            .spring(
                response: AppConstants.Design.springResponse,
                dampingFraction: AppConstants.Design.springDampingFraction
            ),
            value: isPressed
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        let theme = ThemeManager.shared
        switch variant {
        case .primary:
            theme.primaryGradient
        case .secondary:
            LinearGradient(
                colors: [
                    theme.isDarkMode ? AppConstants.Colors.darkBlue : Color(hex: "E8EAED"),
                    theme.isDarkMode ? AppConstants.Colors.surfaceBlue : Color(hex: "D5D7DA")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .accent:
            AppConstants.Colors.accentGradient
        case .ghost:
            Color.clear
        }
    }
    
    private var foregroundColor: Color {
        let theme = ThemeManager.shared
        switch variant {
        case .ghost:
            return theme.primaryColor
        case .secondary:
            return theme.isDarkMode ? .white : Color(hex: "1A1A2E")
        default:
            return .white
        }
    }
    
    private var shadowColor: Color {
        let theme = ThemeManager.shared
        switch variant {
        case .primary:
            return theme.primaryColor.opacity(0.4)
        case .accent:
            return AppConstants.Colors.neonOrange.opacity(0.4)
        case .secondary, .ghost:
            return Color.black.opacity(0.1)
        }
    }
}

// Preview
#Preview {
    ZStack {
        AppConstants.Colors.backgroundGradient
            .ignoresSafeArea()
        
        VStack(spacing: 24) {
            AnimatedButton("Start Tracking", icon: "play.fill", variant: .primary) {}
            AnimatedButton("View History", icon: "clock.fill", variant: .secondary) {}
            AnimatedButton("Premium", icon: "star.fill", variant: .accent) {}
            AnimatedButton("Skip", variant: .ghost) {}
        }
        .padding()
    }
}
