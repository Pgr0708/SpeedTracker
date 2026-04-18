//
//  PreferencesSetupView.swift
//  SpeedTracker
//
//  Preferences setup after paywall - color, speed unit, speed limits
//

import SwiftUI

struct PreferencesSetupView: View {
    @EnvironmentObject var theme: ThemeManager
    @AppStorage(AppConstants.UserDefaultsKeys.hasCompletedPreferences) private var hasCompletedPreferences = false
    @AppStorage(AppConstants.UserDefaultsKeys.preferredSpeedUnit) private var speedUnitRaw: String = AppConstants.SpeedUnit.kmh.rawValue
    @AppStorage(AppConstants.UserDefaultsKeys.maxSpeedLimit) private var maxSpeedLimit: Double = 120
    @AppStorage(AppConstants.UserDefaultsKeys.minSpeedLimit) private var minSpeedLimit: Double = 0
    @AppStorage(AppConstants.UserDefaultsKeys.isDarkModeEnabled) private var isDarkMode: Bool = true
    
    @State private var selectedColor: AppConstants.ThemeColor = .blue
    @State private var selectedUnit: AppConstants.SpeedUnit = .kmh
    @State private var currentStep = 0  // 0=color, 1=mode, 2=unit, 3=limits
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            theme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { i in
                        Capsule()
                            .fill(i <= currentStep ? theme.primaryColor : theme.textSecondary.opacity(0.2))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                
                // Title area
                VStack(spacing: 8) {
                    Text(stepTitle)
                        .font(.headingMedium)
                        .foregroundColor(theme.textPrimary)
                    
                    Text(stepSubtitle)
                        .font(.bodySmall)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Step Content
                Group {
                    switch currentStep {
                    case 0: colorPickerStep
                    case 1: darkModeStep
                    case 2: speedUnitStep
                    case 3: speedLimitsStep
                    default: EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                
                Spacer()
                
                // Navigation
                VStack(spacing: 16) {
                    AnimatedButton(
                        currentStep == 3 ? L10n.string("common.done") : L10n.string("common.continue"),
                        icon: currentStep == 3 ? "checkmark.circle.fill" : "arrow.right",
                        variant: .primary
                    ) {
                        if currentStep == 3 {
                            saveAndFinish()
                        } else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentStep += 1
                            }
                        }
                    }
                    
                    if currentStep > 0 {
                        Button(L10n.string("onboarding.back")) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentStep -= 1
                            }
                        }
                        .font(.bodyMedium)
                        .foregroundColor(theme.textSecondary)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            selectedColor = theme.themeColor
            selectedUnit = AppConstants.SpeedUnit(rawValue: speedUnitRaw) ?? .kmh
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }
    
    // MARK: - Step Titles
    var stepTitle: String {
        switch currentStep {
        case 0: return L10n.string("preferences.colorTitle")
        case 1: return L10n.string("preferences.appearanceTitle")
        case 2: return L10n.string("preferences.speedUnitTitle")
        case 3: return L10n.string("preferences.speedLimitsTitle")
        default: return ""
        }
    }
    
    var stepSubtitle: String {
        switch currentStep {
        case 0: return L10n.string("preferences.colorSubtitle")
        case 1: return L10n.string("preferences.appearanceSubtitle")
        case 2: return L10n.string("preferences.speedUnitSubtitle")
        case 3: return L10n.string("preferences.speedLimitsSubtitle")
        default: return ""
        }
    }
    
    // MARK: - Step 1: Color Picker
    var colorPickerStep: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
            ForEach(AppConstants.ThemeColor.allCases, id: \.rawValue) { color in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedColor = color
                        theme.themeColor = color
                    }
                    HapticManager.shared.selection()
                } label: {
                    VStack(spacing: 12) {
                        Circle()
                            .fill(color.gradient)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                            )
                            .shadow(color: color.primaryColor.opacity(selectedColor == color ? 0.5 : 0), radius: 12)
                            .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                        
                        Text(L10n.string(color.displayNameKey))
                            .font(.caption)
                            .foregroundColor(selectedColor == color ? theme.textPrimary : theme.textSecondary)
                    }
                }
            }
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Step 2: Dark/Light Mode
    var darkModeStep: some View {
        HStack(spacing: 20) {
            ModeCard(
                title: L10n.string("preferences.dark"),
                icon: "moon.fill",
                isSelected: isDarkMode,
                colors: [Color(hex: "0A1128"), Color(hex: "1E2749")],
                theme: theme
            ) {
                withAnimation(.spring(response: 0.3)) {
                    isDarkMode = true
                    theme.isDarkMode = true
                }
                HapticManager.shared.selection()
            }
            
            ModeCard(
                title: L10n.string("preferences.light"),
                icon: "sun.max.fill",
                isSelected: !isDarkMode,
                colors: [Color(hex: "F5F7FA"), Color(hex: "FFFFFF")],
                theme: theme
            ) {
                withAnimation(.spring(response: 0.3)) {
                    isDarkMode = false
                    theme.isDarkMode = false
                }
                HapticManager.shared.selection()
            }
        }
        .padding(.horizontal, 30)
    }
    
    // MARK: - Step 3: Speed Unit
    var speedUnitStep: some View {
        VStack(spacing: 12) {
            ForEach(AppConstants.SpeedUnit.allCases, id: \.rawValue) { unit in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedUnit = unit
                    }
                    HapticManager.shared.selection()
                } label: {
                    HStack {
                        Text(unit.rawValue)
                            .font(.orbitron(20))
                            .foregroundColor(selectedUnit == unit ? .white : theme.textPrimary)
                        
                        Spacer()
                        
                        if selectedUnit == unit {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 22))
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedUnit == unit ? AnyShapeStyle(theme.primaryGradient) : AnyShapeStyle(theme.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.05)))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                selectedUnit == unit ? AnyShapeStyle(Color.clear) : AnyShapeStyle(theme.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.08)),
                                lineWidth: 1
                            )
                    )
                }
            }
        }
        .padding(.horizontal, 30)
    }
    
    // MARK: - Step 4: Speed Limits
    var speedLimitsStep: some View {
        VStack(spacing: 30) {
            // Max Speed
            VStack(spacing: 12) {
                HStack {
                    Text(L10n.text("settings.maxSpeedLimit"))
                        .font(.bodyMedium)
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                    Text("\(Int(maxSpeedLimit)) \(L10n.string(selectedUnit.localizationKey))")
                        .font(.orbitron(18))
                        .foregroundColor(AppConstants.Colors.neonOrange)
                }
                
                Slider(value: $maxSpeedLimit, in: 20...300, step: 5)
                    .tint(AppConstants.Colors.neonOrange)
                
                Text(L10n.text("preferences.maxSpeedHint"))
                    .font(.caption)
                    .foregroundColor(theme.textTertiary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
            )
            
            // Min Speed
            VStack(spacing: 12) {
                HStack {
                    Text(L10n.text("settings.minSpeedThreshold"))
                        .font(.bodyMedium)
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                    Text("\(Int(minSpeedLimit)) \(L10n.string(selectedUnit.localizationKey))")
                        .font(.orbitron(18))
                        .foregroundColor(AppConstants.Colors.limeGreen)
                }
                
                Slider(value: $minSpeedLimit, in: 0...50, step: 1)
                    .tint(AppConstants.Colors.limeGreen)
                
                Text(L10n.text("preferences.minSpeedHint"))
                    .font(.caption)
                    .foregroundColor(theme.textTertiary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
            )
        }
        .padding(.horizontal, 30)
    }
    
    // MARK: - Save
    private func saveAndFinish() {
        speedUnitRaw = selectedUnit.rawValue
        theme.themeColor = selectedColor
        HapticManager.shared.notification(type: .success)
        withAnimation { hasCompletedPreferences = true }
    }
}

struct ModeCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let colors: [Color]
    let theme: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Preview
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
                    .frame(height: 120)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: icon)
                                .font(.system(size: 30))
                                .foregroundColor(title == "Dark" ? .white : Color(hex: "1A1A2E"))
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(title == "Dark" ? Color.white.opacity(0.2) : Color.black.opacity(0.1))
                                .frame(width: 60, height: 6)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? theme.primaryColor : Color.clear,
                                lineWidth: 3
                            )
                    )
                
                Text(title)
                    .font(.bodyMedium)
                    .foregroundColor(isSelected ? theme.primaryColor : theme.textSecondary)
            }
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

#Preview {
    PreferencesSetupView()
        .environmentObject(ThemeManager.shared)
}
