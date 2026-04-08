//
//  PaywallView.swift
//  SpeedTracker
//
//  Paywall screen shown after onboarding (step 3)
//

import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var theme: ThemeManager
    @AppStorage(AppConstants.UserDefaultsKeys.hasCompletedPaywall) private var hasCompletedPaywall = false
    @State private var selectedPlan = 1 // 0=weekly, 1=yearly, 2=lifetime
    @State private var appeared = false
    
    let plans = [
        ("Weekly", "$1.99/week", "$1.99", "After 3-day free trial"),
        ("Yearly", "$19.99/year", "$0.38/week", "Best Value • Save 80%"),
        ("Lifetime", "$49.99", "One-time", "Pay once, own forever")
    ]
    
    var body: some View {
        ZStack {
            theme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Close / Skip
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation { hasCompletedPaywall = true }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(theme.textSecondary.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    // Crown icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hex: "FFD700").opacity(0.3),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color(hex: "FFD700").opacity(0.5), radius: 20)
                    }
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)
                    
                    // Title
                    VStack(spacing: 8) {
                        Text("Unlock Premium")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textPrimary)
                        
                        Text("Get the full speed tracking experience")
                            .font(.system(size: 16))
                            .foregroundColor(theme.textSecondary)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        PremiumFeature(icon: "speedometer", text: "Unlimited speed tracking", color: theme.primaryColor)
                        PremiumFeature(icon: "map.fill", text: "Full route history with maps", color: Color(hex: "39FF14"))
                        PremiumFeature(icon: "chart.xyaxis.line", text: "Speed-time graphs & analytics", color: Color(hex: "FF6B35"))
                        PremiumFeature(icon: "bell.badge.fill", text: "Custom speed limit alerts", color: Color(hex: "9D4EDD"))
                        PremiumFeature(icon: "paintbrush.fill", text: "All themes & customization", color: Color(hex: "FFD700"))
                    }
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
                    
                    // Plan Cards
                    VStack(spacing: 12) {
                        ForEach(0..<plans.count, id: \.self) { index in
                            PlanCard(
                                title: plans[index].0,
                                price: plans[index].1,
                                subtitle: plans[index].2,
                                badge: plans[index].3,
                                isSelected: selectedPlan == index,
                                isBest: index == 1,
                                theme: theme
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedPlan = index
                                }
                                HapticManager.shared.selection()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    
                    // Subscribe Button
                    AnimatedButton("Start Free Trial", icon: "sparkles", variant: .primary) {
                        // In production: integrate with RevenueCat/StoreKit
                        UserDefaults.standard.set(true, forKey: AppConstants.UserDefaultsKeys.isPremium)
                        withAnimation { hasCompletedPaywall = true }
                    }
                    .padding(.horizontal, 24)
                    
                    // Skip / Restore
                    HStack(spacing: 24) {
                        Button("Restore Purchases") {
                            withAnimation { hasCompletedPaywall = true }
                        }
                        .font(.system(size: 14))
                        .foregroundColor(theme.textSecondary)
                        
                        Button("Continue Free") {
                            withAnimation { hasCompletedPaywall = true }
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.primaryColor)
                    }
                    .padding(.bottom, 40)
                    
                    // Legal
                    Text("Auto-renewable subscription. Cancel anytime.")
                        .font(.system(size: 11))
                        .foregroundColor(theme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
        }
    }
}

struct PremiumFeature: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 32)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color.opacity(0.7))
        }
    }
}

struct PlanCard: View {
    let title: String
    let price: String
    let subtitle: String
    let badge: String
    let isSelected: Bool
    let isBest: Bool
    let theme: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                if isBest {
                    Text("MOST POPULAR")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(theme.primaryGradient)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(theme.textPrimary)
                        
                        Text(badge)
                            .font(.system(size: 12))
                            .foregroundColor(isBest ? theme.primaryColor : theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(price)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(theme.textPrimary)
                        
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    // Radio
                    Circle()
                        .strokeBorder(isSelected ? theme.primaryColor : theme.textSecondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .fill(isSelected ? theme.primaryColor : Color.clear)
                                .frame(width: 14, height: 14)
                        )
                        .padding(.leading, 12)
                }
                .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.isDarkMode ? Color.white.opacity(isSelected ? 0.12 : 0.06) : Color.black.opacity(isSelected ? 0.08 : 0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? theme.primaryColor : Color.clear,
                        lineWidth: 2
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(ThemeManager.shared)
}
