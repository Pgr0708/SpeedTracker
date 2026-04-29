//
//  MainTabView.swift
//  SpeedTracker
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 0
    @State private var showPaywall = false
    @State private var isHUDActive = false
    private var isPremium: Bool { purchaseService.isPremium }

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Glow behind tab bar so liquid glass material has contrast to blur
            if !isHUDActive {
                RadialGradient(
                    colors: [theme.primaryColor.opacity(0.28), theme.primaryColor.opacity(0.08), .clear],
                    center: .center, startRadius: 0, endRadius: 180
                )
                .frame(height: 130)
                .blur(radius: 20)
                .allowsHitTesting(false)
            }
            if !isHUDActive {
                CustomTabBar(selectedTab: $selectedTab, showPaywall: $showPaywall, isPremium: isPremium)
                    .padding(.horizontal, AppConstants.Design.paddingL)
                    .padding(.bottom, AppConstants.Design.paddingS)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onPreferenceChange(HUDActiveKey.self) { active in
            withAnimation(.easeInOut(duration: 0.25)) { isHUDActive = active }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(theme)
                .environmentObject(purchaseService)
                .environmentObject(authService)
        }
    }

    @ViewBuilder var tabContent: some View {
        switch selectedTab {
        case 0: SpeedTrackerView()
        case 1: HistoryView()
        case 2: PedometerView()
        case 3: CompassView()
        case 4: SettingsView()
        default: SpeedTrackerView()
        }
    }
}

struct CustomTabBar: View {
    @EnvironmentObject var theme: ThemeManager
    @Binding var selectedTab: Int
    @Binding var showPaywall: Bool
    let isPremium: Bool

    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(icon: "speedometer", title: L10n.string("main.speed"), isSelected: selectedTab == 0, theme: theme) {
                selectedTab = 0; HapticManager.shared.selection()
            }
            Spacer()
            TabBarButton(icon: "clock.fill", title: L10n.string("history.title"), isSelected: selectedTab == 1, isPremiumLocked: !isPremium, theme: theme) {
                HapticManager.shared.selection()
                if isPremium {
                    selectedTab = 1
                } else {
                    showPaywall = true
                }
            }
            Spacer()
            // Pedometer — premium
            TabBarButton(icon: "figure.walk", title: L10n.string("pedometer.steps"), isSelected: selectedTab == 2, isPremiumLocked: !isPremium, theme: theme) {
                HapticManager.shared.selection()
                if isPremium { selectedTab = 2 } else { showPaywall = true }
            }
            Spacer()
            TabBarButton(icon: "safari", title: L10n.string("compass.title"), isSelected: selectedTab == 3, theme: theme) {
                HapticManager.shared.selection()
                selectedTab = 3
            }
            Spacer()
            TabBarButton(icon: "gearshape.fill", title: L10n.string("settings.title"), isSelected: selectedTab == 4, theme: theme) {
                selectedTab = 4; HapticManager.shared.selection()
            }
        }
        .padding(.horizontal, AppConstants.Design.paddingM)
        .padding(.vertical, AppConstants.Design.paddingM)
        .background(
            ZStack {
                // Base glass
                RoundedRectangle(cornerRadius: AppConstants.Design.cornerRadiusL)
                    .fill(.ultraThinMaterial)
                // Liquid shimmer overlay
                RoundedRectangle(cornerRadius: AppConstants.Design.cornerRadiusL)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.primaryColor.opacity(theme.isDarkMode ? 0.12 : 0.06),
                                Color.white.opacity(theme.isDarkMode ? 0.04 : 0.35),
                                theme.primaryColor.opacity(theme.isDarkMode ? 0.06 : 0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                // Border
                RoundedRectangle(cornerRadius: AppConstants.Design.cornerRadiusL)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(theme.isDarkMode ? 0.25 : 0.6),
                                theme.primaryColor.opacity(0.3),
                                Color.white.opacity(theme.isDarkMode ? 0.08 : 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: theme.primaryColor.opacity(0.18), radius: 24, y: 8)
            .shadow(color: Color.black.opacity(0.12), radius: 8, y: 2)
        )
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    var isPremiumLocked: Bool = false
    let theme: ThemeManager
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? theme.primaryColor : theme.textSecondary)
                    if isPremiumLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8))
                            .foregroundColor(Color(hex: "FFD700"))
                            .offset(x: 8, y: -4)
                    }
                }
                Text(title)
                    .font(.rajdhaniMedium(11))
                    .foregroundColor(isSelected ? theme.primaryColor : theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isSelected ? 1.08 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}
