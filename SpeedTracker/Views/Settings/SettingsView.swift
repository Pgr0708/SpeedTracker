//
//  SettingsView.swift
//  SpeedTracker
//
//  Settings screen with glass morphism
//

import SwiftUI

struct SettingsView: View {
    @State private var selectedUnit: AppConstants.SpeedUnit = .kmh
    @State private var isHapticsEnabled = true
    @State private var selectedLanguage: AppConstants.SupportedLanguage = .english
    
    var body: some View {
        ZStack {
            AppConstants.Colors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppConstants.Design.paddingL) {
                    // Header
                    HStack {
                        Text("SETTINGS")
                            .font(.headingLarge)
                            .foregroundColor(AppConstants.Colors.textPrimary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, AppConstants.Design.paddingL)
                    .padding(.top, AppConstants.Design.paddingXL)
                    
                    // Profile Card
                    GlassMorphismCard {
                        HStack(spacing: AppConstants.Design.paddingM) {
                            // Avatar
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            AppConstants.Colors.electricBlue,
                                            AppConstants.Colors.limeGreen
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Speed Enthusiast")
                                    .font(.bodyLarge)
                                    .foregroundColor(AppConstants.Colors.textPrimary)
                                
                                Text("Free Plan")
                                    .font(.caption)
                                    .foregroundColor(AppConstants.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppConstants.Colors.textSecondary)
                        }
                    }
                    .padding(.horizontal, AppConstants.Design.paddingL)
                    
                    // Preferences
                    VStack(spacing: AppConstants.Design.paddingM) {
                        SettingsSection(title: "PREFERENCES") {
                            SettingRow(
                                icon: "gauge",
                                title: "Speed Unit",
                                value: selectedUnit.rawValue,
                                color: AppConstants.Colors.electricBlue
                            ) {}
                            
                            SettingRow(
                                icon: "globe",
                                title: "Language",
                                value: selectedLanguage.displayName,
                                color: AppConstants.Colors.limeGreen
                            ) {}
                            
                            SettingToggle(
                                icon: "waveform",
                                title: "Haptic Feedback",
                                color: AppConstants.Colors.neonOrange,
                                isOn: $isHapticsEnabled
                            )
                        }
                        
                        SettingsSection(title: "PREMIUM") {
                            SettingRow(
                                icon: "star.fill",
                                title: "Upgrade to Premium",
                                value: "",
                                color: AppConstants.Colors.neonOrange,
                                showChevron: true
                            ) {}
                        }
                        
                        SettingsSection(title: "SUPPORT") {
                            SettingRow(
                                icon: "questionmark.circle.fill",
                                title: "Help & Support",
                                color: Color(hex: "9D4EDD")
                            ) {}
                            
                            SettingRow(
                                icon: "doc.text.fill",
                                title: "Privacy Policy",
                                color: Color(hex: "9D4EDD")
                            ) {}
                            
                            SettingRow(
                                icon: "info.circle.fill",
                                title: "About",
                                value: "v1.0.0",
                                color: Color(hex: "9D4EDD")
                            ) {}
                        }
                    }
                    .padding(.horizontal, AppConstants.Design.paddingL)
                    .padding(.bottom, 100)
                }
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Design.paddingS) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppConstants.Colors.textSecondary)
                .padding(.leading, AppConstants.Design.paddingS)
            
            GlassMorphismCard(padding: 0) {
                VStack(spacing: 0) {
                    content
                }
            }
        }
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    var value: String = ""
    let color: Color
    var showChevron: Bool = true
    let action: () -> Void
    
    init(
        icon: String,
        title: String,
        value: String = "",
        color: Color,
        showChevron: Bool = true,
        action: @escaping () -> Void = {}
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.color = color
        self.showChevron = showChevron
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppConstants.Design.paddingM) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 32)
                
                Text(title)
                    .font(.bodyMedium)
                    .foregroundColor(AppConstants.Colors.textPrimary)
                
                Spacer()
                
                if !value.isEmpty {
                    Text(value)
                        .font(.bodySmall)
                        .foregroundColor(AppConstants.Colors.textSecondary)
                }
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppConstants.Colors.textSecondary)
                }
            }
            .padding(.horizontal, AppConstants.Design.paddingM)
            .padding(.vertical, AppConstants.Design.paddingM)
        }
    }
}

struct SettingToggle: View {
    let icon: String
    let title: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: AppConstants.Design.paddingM) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32)
            
            Text(title)
                .font(.bodyMedium)
                .foregroundColor(AppConstants.Colors.textPrimary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppConstants.Colors.electricBlue)
        }
        .padding(.horizontal, AppConstants.Design.paddingM)
        .padding(.vertical, AppConstants.Design.paddingM)
    }
}

#Preview {
    SettingsView()
}
