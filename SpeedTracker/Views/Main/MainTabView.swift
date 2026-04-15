//
//  MainTabView.swift
//  SpeedTracker
//
//  Main tab navigation with proper custom tab bar
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var theme: ThemeManager
    @State private var selectedTab = 0
    @State private var showHUDMode = false
    @State private var showPaywall = false
    
    @AppStorage(AppConstants.UserDefaultsKeys.isPremium) private var isPremium = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch selectedTab {
                case 0:
                    SpeedTrackerView()
                case 1:
                    HistoryView()
                case 2:
                    SettingsView()
                default:
                    SpeedTrackerView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom tab bar
            CustomTabBar(selectedTab: $selectedTab, showHUDMode: $showHUDMode, showPaywall: $showPaywall, isPremium: isPremium)
                .padding(.horizontal, AppConstants.Design.paddingL)
                .padding(.bottom, AppConstants.Design.paddingS)
        }
        .environmentObject(theme)
        .fullScreenCover(isPresented: $showHUDMode) {
            HUDModeView()
                .environmentObject(theme)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(theme)
        }
    }
}

struct CustomTabBar: View {
    @EnvironmentObject var theme: ThemeManager
    @Binding var selectedTab: Int
    @Binding var showHUDMode: Bool
    @Binding var showPaywall: Bool
    let isPremium: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(
                icon: "speedometer",
                title: "Speed",
                isSelected: selectedTab == 0,
                theme: theme
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 0
                }
                HapticManager.shared.selection()
            }
            
            Spacer()
            
            TabBarButton(
                icon: "clock.fill",
                title: "History",
                isSelected: selectedTab == 1,
                theme: theme
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 1
                }
                HapticManager.shared.selection()
            }
            
            Spacer()
            
            // HUD Mode button (premium feature)
            TabBarButton(
                icon: "windshield",
                title: "HUD",
                isSelected: false,
                isPremium: true,
                theme: theme
            ) {
                HapticManager.shared.selection()
                if isPremium {
                    showHUDMode = true
                } else {
                    showPaywall = true
                }
            }
            
            Spacer()
            
            TabBarButton(
                icon: "gearshape.fill",
                title: "Settings",
                isSelected: selectedTab == 2,
                theme: theme
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 2
                }
                HapticManager.shared.selection()
            }
        }
        .padding(.horizontal, AppConstants.Design.paddingL)
        .padding(.vertical, AppConstants.Design.paddingM)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Design.cornerRadiusL)
                .fill(theme.isDarkMode ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.regularMaterial))
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.Design.cornerRadiusL)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    theme.isDarkMode ? Color.white.opacity(0.2) : Color.black.opacity(0.05),
                                    theme.isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: theme.primaryColor.opacity(0.15), radius: 20, y: 10)
        )
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    var isPremium: Bool = false
    let theme: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(isSelected ? theme.primaryColor : theme.textSecondary)
                    
                    if isPremium {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 8))
                            .foregroundColor(Color(hex: "FFD700"))
                            .offset(x: 12, y: -10)
                    }
                }
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? theme.primaryColor : theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(ThemeManager.shared)
}
