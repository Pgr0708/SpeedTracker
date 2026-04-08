//
//  OnboardingPageView.swift
//  SpeedTracker
//
//  Individual onboarding page with animations
//

import SwiftUI

struct OnboardingPageView: View {
    @EnvironmentObject var theme: ThemeManager
    let page: OnboardingPage
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: AppConstants.Design.paddingXL) {
            Spacer()
            
            // Icon/Animation container
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: page.accentColor).opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 20)
                    .scaleEffect(animate ? 1.1 : 0.9)
                
                // Glass circle background
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 200, height: 200)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color(hex: page.accentColor).opacity(0.3), radius: 30)
                
                // Icon
                Image(systemName: page.iconName)
                    .font(.system(size: 80, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: page.accentColor),
                                Color(hex: page.accentColor).opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animate ? 1.0 : 0.8)
                    .rotationEffect(.degrees(animate ? 0 : -10))
            }
            .padding(.bottom, AppConstants.Design.paddingXL)
            
            // Content
            VStack(spacing: AppConstants.Design.paddingM) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 20)
                
                Text(page.description)
                    .font(.system(size: 16))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, AppConstants.Design.paddingL)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 30)
            }
            
            Spacer()
        }
        .onAppear {
            withAnimation(
                .spring(response: 0.8, dampingFraction: 0.7)
                .delay(0.2)
            ) {
                animate = true
            }
        }
        .onDisappear {
            animate = false
        }
    }
}

#Preview {
    ZStack {
        AppConstants.Colors.backgroundGradient
            .ignoresSafeArea()
        
        OnboardingPageView(page: OnboardingPage.pages[0])
            .environmentObject(ThemeManager.shared)
    }
}
