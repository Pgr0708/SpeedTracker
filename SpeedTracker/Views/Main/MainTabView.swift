//
//  MainTabView.swift
//  SpeedTracker
//
//  Main tab navigation with sport theme
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background gradient
            AppConstants.Colors.backgroundGradient
                .ignoresSafeArea()
            
            // Tab content
            TabView(selection: $selectedTab) {
                SpeedTrackerView()
                    .tag(0)
                
                HistoryView()
                    .tag(1)
                
                SettingsView()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Custom tab bar
            CustomTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, AppConstants.Design.paddingL)
                .padding(.bottom, AppConstants.Design.paddingM)
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(
                icon: "speedometer",
                title: "Speed",
                isSelected: selectedTab == 0
            ) {
                withAnimation(.spring(
                    response: AppConstants.Design.springResponse,
                    dampingFraction: AppConstants.Design.springDampingFraction
                )) {
                    selectedTab = 0
                }
                HapticManager.shared.selection()
            }
            
            Spacer()
            
            TabBarButton(
                icon: "clock.fill",
                title: "History",
                isSelected: selectedTab == 1
            ) {
                withAnimation(.spring(
                    response: AppConstants.Design.springResponse,
                    dampingFraction: AppConstants.Design.springDampingFraction
                )) {
                    selectedTab = 1
                }
                HapticManager.shared.selection()
            }
            
            Spacer()
            
            TabBarButton(
                icon: "gearshape.fill",
                title: "Settings",
                isSelected: selectedTab == 2
            ) {
                withAnimation(.spring(
                    response: AppConstants.Design.springResponse,
                    dampingFraction: AppConstants.Design.springDampingFraction
                )) {
                    selectedTab = 2
                }
                HapticManager.shared.selection()
            }
        }
        .padding(.horizontal, AppConstants.Design.paddingL)
        .padding(.vertical, AppConstants.Design.paddingM)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Design.cornerRadiusL)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.Design.cornerRadiusL)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: AppConstants.Colors.electricBlue.opacity(0.2), radius: 20, y: 10)
        )
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(
                        isSelected ? 
                        AppConstants.Colors.primaryGradient :
                        LinearGradient(
                            colors: [AppConstants.Colors.textSecondary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(
                        isSelected ? 
                        AppConstants.Colors.electricBlue : 
                        AppConstants.Colors.textSecondary
                    )
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.spring(
                response: AppConstants.Design.springResponse,
                dampingFraction: AppConstants.Design.springDampingFraction
            ), value: isSelected)
        }
    }
}

#Preview {
    MainTabView()
}
