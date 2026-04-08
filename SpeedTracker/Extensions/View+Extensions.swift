//
//  View+Extensions.swift
//  SpeedTracker
//
//  View modifier extensions
//

import SwiftUI

// MARK: - Glass Morphism Effect
extension View {
    func glassMorphism(
        cornerRadius: CGFloat = AppConstants.Design.cornerRadiusM,
        opacity: Double = AppConstants.Design.glassOpacity,
        blur: CGFloat = AppConstants.Design.glassBlur
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(opacity)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(AppConstants.Design.glassBorderOpacity),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Animated Button Style
struct AnimatedButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.95
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(
                .spring(
                    response: AppConstants.Design.springResponse,
                    dampingFraction: AppConstants.Design.springDampingFraction
                ),
                value: configuration.isPressed
            )
    }
}

extension View {
    func animatedButton(scale: CGFloat = 0.95) -> some View {
        self.buttonStyle(AnimatedButtonStyle(scale: scale))
    }
}

// MARK: - Shimmer Effect
extension View {
    func shimmer(active: Bool = true) -> some View {
        self.modifier(ShimmerModifier(isActive: active))
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isActive {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                Color.white.opacity(0.3),
                                .clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: -geometry.size.width + phase * geometry.size.width * 2)
                        .mask(content)
                    }
                }
            )
            .onAppear {
                if isActive {
                    withAnimation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                    ) {
                        phase = 1
                    }
                }
            }
    }
}

// MARK: - Gradient Background
extension View {
    func sportGradientBackground() -> some View {
        self
            .background(
                AppConstants.Colors.backgroundGradient
                    .ignoresSafeArea()
            )
    }
}

// MARK: - Conditional Modifier
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
