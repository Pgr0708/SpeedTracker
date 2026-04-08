//
//  SettingsView.swift
//  SpeedTracker
//
//  Settings screen with real preferences and dark/light mode
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var theme: ThemeManager
    @AppStorage(AppConstants.UserDefaultsKeys.preferredSpeedUnit) private var speedUnitRaw: String = AppConstants.SpeedUnit.kmh.rawValue
    @AppStorage(AppConstants.UserDefaultsKeys.isHapticEnabled) private var isHapticsEnabled = true
    @AppStorage(AppConstants.UserDefaultsKeys.isDarkModeEnabled) private var isDarkMode = true
    @AppStorage(AppConstants.UserDefaultsKeys.maxSpeedLimit) private var maxSpeedLimit: Double = 120
    @AppStorage(AppConstants.UserDefaultsKeys.minSpeedLimit) private var minSpeedLimit: Double = 0
    @AppStorage(AppConstants.UserDefaultsKeys.preferredLanguage) private var preferredLanguage: String = "en"
    
    @State private var showSpeedUnitPicker = false
    @State private var showColorPicker = false
    @State private var showLanguagePicker = false
    @State private var showResetAlert = false
    
    var speedUnit: AppConstants.SpeedUnit {
        AppConstants.SpeedUnit(rawValue: speedUnitRaw) ?? .kmh
    }
    
    var currentLanguage: AppConstants.SupportedLanguage {
        AppConstants.SupportedLanguage(rawValue: preferredLanguage) ?? .english
    }
    
    var body: some View {
        ZStack {
            theme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppConstants.Design.paddingL) {
                    // Header
                    HStack {
                        Text("SETTINGS")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textPrimary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, AppConstants.Design.paddingL)
                    .padding(.top, AppConstants.Design.paddingXL)
                    
                    // Appearance Section
                    VStack(spacing: AppConstants.Design.paddingM) {
                        SettingsSection(title: "APPEARANCE", theme: theme) {
                            // Dark Mode Toggle
                            SettingToggle(
                                icon: isDarkMode ? "moon.fill" : "sun.max.fill",
                                title: "Dark Mode",
                                color: Color(hex: "9D4EDD"),
                                isOn: Binding(
                                    get: { isDarkMode },
                                    set: { newVal in
                                        isDarkMode = newVal
                                        theme.isDarkMode = newVal
                                    }
                                ),
                                theme: theme
                            )
                            
                            // Theme Color
                            SettingRow(
                                icon: "paintpalette.fill",
                                title: "Theme Color",
                                value: theme.themeColor.displayName,
                                color: theme.primaryColor,
                                theme: theme
                            ) {
                                showColorPicker = true
                            }
                        }
                        
                        // Tracking Section
                        SettingsSection(title: "TRACKING", theme: theme) {
                            SettingRow(
                                icon: "gauge",
                                title: "Speed Unit",
                                value: speedUnit.rawValue,
                                color: theme.primaryColor,
                                theme: theme
                            ) {
                                showSpeedUnitPicker = true
                            }
                            
                            // Max Speed Limit
                            VStack(spacing: 8) {
                                HStack(spacing: AppConstants.Design.paddingM) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.title3)
                                        .foregroundColor(AppConstants.Colors.neonOrange)
                                        .frame(width: 32)
                                    
                                    Text("Max Speed Limit")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(theme.textPrimary)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(maxSpeedLimit)) \(speedUnit.rawValue)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(AppConstants.Colors.neonOrange)
                                }
                                
                                Slider(value: $maxSpeedLimit, in: 20...300, step: 5)
                                    .tint(AppConstants.Colors.neonOrange)
                            }
                            .padding(.horizontal, AppConstants.Design.paddingM)
                            .padding(.vertical, AppConstants.Design.paddingM)
                            
                            // Min Speed Limit
                            VStack(spacing: 8) {
                                HStack(spacing: AppConstants.Design.paddingM) {
                                    Image(systemName: "tortoise.fill")
                                        .font(.title3)
                                        .foregroundColor(AppConstants.Colors.limeGreen)
                                        .frame(width: 32)
                                    
                                    Text("Min Speed Threshold")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(theme.textPrimary)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(minSpeedLimit)) \(speedUnit.rawValue)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(AppConstants.Colors.limeGreen)
                                }
                                
                                Slider(value: $minSpeedLimit, in: 0...50, step: 1)
                                    .tint(AppConstants.Colors.limeGreen)
                            }
                            .padding(.horizontal, AppConstants.Design.paddingM)
                            .padding(.vertical, AppConstants.Design.paddingM)
                            
                            SettingToggle(
                                icon: "waveform",
                                title: "Haptic Feedback",
                                color: AppConstants.Colors.neonOrange,
                                isOn: $isHapticsEnabled,
                                theme: theme
                            )
                        }
                        
                        // General Section
                        SettingsSection(title: "GENERAL", theme: theme) {
                            SettingRow(
                                icon: "globe",
                                title: "Language",
                                value: currentLanguage.displayName,
                                color: AppConstants.Colors.limeGreen,
                                theme: theme
                            ) {
                                showLanguagePicker = true
                            }
                        }
                        
                        // Support Section
                        SettingsSection(title: "SUPPORT", theme: theme) {
                            SettingRow(
                                icon: "star.fill",
                                title: "Rate App",
                                color: Color(hex: "FFD700"),
                                theme: theme
                            ) { }
                            
                            SettingRow(
                                icon: "questionmark.circle.fill",
                                title: "Help & Support",
                                color: Color(hex: "9D4EDD"),
                                theme: theme
                            ) { }
                            
                            SettingRow(
                                icon: "doc.text.fill",
                                title: "Privacy Policy",
                                color: Color(hex: "9D4EDD"),
                                theme: theme
                            ) { }
                            
                            SettingRow(
                                icon: "info.circle.fill",
                                title: "About",
                                value: "v\(AppConstants.App.version)",
                                color: Color(hex: "9D4EDD"),
                                theme: theme
                            ) { }
                        }
                        
                        // Danger Zone
                        SettingsSection(title: "DATA", theme: theme) {
                            SettingRow(
                                icon: "trash.fill",
                                title: "Reset All Data",
                                color: Color(hex: "FF3B5C"),
                                theme: theme
                            ) {
                                showResetAlert = true
                            }
                        }
                    }
                    .padding(.horizontal, AppConstants.Design.paddingL)
                    .padding(.bottom, 100)
                }
            }
        }
        // Speed Unit Picker Sheet
        .sheet(isPresented: $showSpeedUnitPicker) {
            PickerSheet(title: "Speed Unit", theme: theme) {
                ForEach(AppConstants.SpeedUnit.allCases, id: \.rawValue) { unit in
                    Button {
                        speedUnitRaw = unit.rawValue
                        showSpeedUnitPicker = false
                        HapticManager.shared.selection()
                    } label: {
                        HStack {
                            Text(unit.rawValue)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(theme.textPrimary)
                            Spacer()
                            if speedUnit == unit {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(theme.primaryColor)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        // Color Picker Sheet
        .sheet(isPresented: $showColorPicker) {
            PickerSheet(title: "Theme Color", theme: theme) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(AppConstants.ThemeColor.allCases, id: \.rawValue) { color in
                        Button {
                            theme.themeColor = color
                            showColorPicker = false
                            HapticManager.shared.selection()
                        } label: {
                            VStack(spacing: 8) {
                                Circle()
                                    .fill(color.gradient)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: theme.themeColor == color ? 3 : 0)
                                    )
                                    .shadow(color: color.primaryColor.opacity(theme.themeColor == color ? 0.5 : 0), radius: 8)
                                
                                Text(color.displayName)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(theme.textSecondary)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        // Language Picker Sheet
        .sheet(isPresented: $showLanguagePicker) {
            PickerSheet(title: "Language", theme: theme) {
                ForEach(AppConstants.SupportedLanguage.allCases, id: \.rawValue) { lang in
                    Button {
                        preferredLanguage = lang.rawValue
                        showLanguagePicker = false
                        HapticManager.shared.selection()
                    } label: {
                        HStack(spacing: 12) {
                            Text(lang.flagEmoji)
                                .font(.system(size: 20))
                            Text(lang.displayName)
                                .font(.system(size: 16))
                                .foregroundColor(theme.textPrimary)
                            Spacer()
                            if currentLanguage == lang {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(theme.primaryColor)
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        .alert("Reset All Data?", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) {
                // Clear onboarding flags and trip data
                let domain = Bundle.main.bundleIdentifier!
                UserDefaults.standard.removePersistentDomain(forName: domain)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will delete all trips and reset preferences. This cannot be undone.")
        }
    }
}

// MARK: - Setting Components
struct SettingsSection<Content: View>: View {
    let title: String
    let theme: ThemeManager
    let content: Content
    
    init(title: String, theme: ThemeManager, @ViewBuilder content: () -> Content) {
        self.title = title
        self.theme = theme
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Design.paddingS) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(theme.textSecondary)
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
    let theme: ThemeManager
    let action: () -> Void
    
    init(
        icon: String,
        title: String,
        value: String = "",
        color: Color,
        showChevron: Bool = true,
        theme: ThemeManager,
        action: @escaping () -> Void = {}
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.color = color
        self.showChevron = showChevron
        self.theme = theme
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
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                if !value.isEmpty {
                    Text(value)
                        .font(.system(size: 13))
                        .foregroundColor(theme.textSecondary)
                }
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textTertiary)
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
    let theme: ThemeManager
    
    var body: some View {
        HStack(spacing: AppConstants.Design.paddingM) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32)
            
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(theme.textPrimary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(theme.primaryColor)
        }
        .padding(.horizontal, AppConstants.Design.paddingM)
        .padding(.vertical, AppConstants.Design.paddingM)
    }
}

// MARK: - Picker Sheet
struct PickerSheet<Content: View>: View {
    let title: String
    let theme: ThemeManager
    let content: Content
    
    init(title: String, theme: ThemeManager, @ViewBuilder content: () -> Content) {
        self.title = title
        self.theme = theme
        self.content = content()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        content
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager.shared)
}
