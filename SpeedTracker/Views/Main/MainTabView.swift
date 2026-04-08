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
            CustomTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, AppConstants.Design.paddingL)
                .padding(.bottom, AppConstants.Design.paddingS)
        }
        .environmentObject(theme)
    }
}

struct CustomTabBar: View {
    @EnvironmentObject var theme: ThemeManager
    @Binding var selectedTab: Int
    
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
    let theme: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(isSelected ? theme.primaryColor : theme.textSecondary)
                
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
