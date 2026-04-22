//
//  SettingsView.swift
//  SpeedTracker
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var authService = AuthService.shared

    @AppStorage(AppConstants.UserDefaultsKeys.preferredSpeedUnit) private var speedUnitRaw: String = AppConstants.SpeedUnit.kmh.rawValue
    @AppStorage(AppConstants.UserDefaultsKeys.isHapticEnabled) private var isHapticsEnabled = true
    @AppStorage(AppConstants.UserDefaultsKeys.isDarkModeEnabled) private var isDarkMode = true
    @AppStorage(AppConstants.UserDefaultsKeys.maxSpeedLimit) private var maxSpeedLimit: Double = 120
    @AppStorage(AppConstants.UserDefaultsKeys.minSpeedLimit) private var minSpeedLimit: Double = 0
    @AppStorage(AppConstants.UserDefaultsKeys.preferredLanguage) private var preferredLanguage: String = "en"
    @AppStorage(AppConstants.UserDefaultsKeys.isSoundMuted) private var isSoundMuted = false
    @AppStorage(AppConstants.UserDefaultsKeys.isMirrorModeEnabled) private var isMirrorModeEnabled = false
    @AppStorage(AppConstants.UserDefaultsKeys.isPremium) private var isPremium = false
    @AppStorage(AppConstants.UserDefaultsKeys.lastCloudKitSync) private var lastCloudKitSync: Double = 0

    @State private var showSpeedUnitPicker = false
    @State private var showColorPicker = false
    @State private var showLanguagePicker = false
    @State private var showResetAlert = false
    @State private var showLogoutAlert = false
    @State private var showPaywall = false

    var speedUnit: AppConstants.SpeedUnit { AppConstants.SpeedUnit(rawValue: speedUnitRaw) ?? .kmh }
    var currentLanguage: AppConstants.SupportedLanguage { AppConstants.SupportedLanguage(rawValue: preferredLanguage) ?? .english }
    var localizedThemeName: String { L10n.string(theme.themeColor.displayNameKey) }

    var lastSyncText: String {
        guard lastCloudKitSync > 0 else { return L10n.string("common.never") }
        let date = Date(timeIntervalSince1970: lastCloudKitSync)
        let f = RelativeDateTimeFormatter(); f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }

    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppConstants.Design.paddingL) {
                    headerView
                    VStack(spacing: AppConstants.Design.paddingM) {
                        accountSection
                        appearanceSection
                        trackingSection
                        generalSection
                        supportSection
                        dataSection
                    }
                    .padding(.horizontal, AppConstants.Design.paddingL)
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showSpeedUnitPicker) { speedUnitPickerSheet }
        .sheet(isPresented: $showColorPicker) { colorPickerSheet }
        .sheet(isPresented: $showLanguagePicker) { languagePickerSheet }
        .sheet(isPresented: $showPaywall) { PaywallView().environmentObject(theme).environmentObject(purchaseService) }
        .alert(L10n.string("alert.resetData.title"), isPresented: $showResetAlert) {
            Button(L10n.string("alert.resetData.confirm"), role: .destructive) {
                let domain = Bundle.main.bundleIdentifier ?? "com.centillion.SpeedTracker"
                UserDefaults.standard.removePersistentDomain(forName: domain)
            }
            Button(L10n.string("common.cancel"), role: .cancel) {}
        } message: { Text(L10n.string("alert.resetData.message")) }
        .alert(L10n.string("alert.signOut.title"), isPresented: $showLogoutAlert) {
            Button(L10n.string("alert.signOut.confirm"), role: .destructive) {
                authService.signOut()
            }
            Button(L10n.string("common.cancel"), role: .cancel) {}
        } message: { Text(L10n.string("alert.signOut.message")) }
    }

    // MARK: - Header
    var headerView: some View {
        HStack {
            Text(L10n.text("settings.title"))
                .font(.headingMedium)
                .foregroundColor(theme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, AppConstants.Design.paddingL)
        .padding(.top, AppConstants.Design.paddingXL)
    }

    // MARK: - Account Section
    var accountSection: some View {
        SettingsSection(title: L10n.string("settings.account").uppercased(), theme: theme) {
            // Profile row
            HStack(spacing: AppConstants.Design.paddingM) {
                ZStack {
                    Circle()
                        .fill(theme.primaryColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: authService.isAuthenticated ? "person.fill" : "person.crop.circle.badge.questionmark")
                        .font(.system(size: 20))
                        .foregroundColor(theme.primaryColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    if authService.isAuthenticated {
                        Text(authService.displayName.isEmpty ? L10n.string("settings.defaultUser") : authService.displayName)
                            .font(.bodyMedium)
                            .foregroundColor(theme.textPrimary)
                        Text(authService.email.isEmpty ? L10n.string("settings.appleSignIn") : authService.email)
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    } else {
                        Text(L10n.string("settings.defaultUser"))
                            .font(.bodyMedium)
                            .foregroundColor(theme.textPrimary)
                        Text("Free Plan")
                            .font(.caption)
                            .foregroundColor(theme.textTertiary)
                    }
                }
                Spacer()
                if isPremium && authService.isAuthenticated {
                    Label(L10n.string("common.premium"), systemImage: "crown.fill")
                        .font(.caption)
                        .foregroundColor(theme.primaryColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(theme.primaryColor.opacity(0.12))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, AppConstants.Design.paddingM)
            .padding(.vertical, AppConstants.Design.paddingM)

            Divider().background(theme.textTertiary.opacity(0.3))

            if !isPremium {
                SettingRow(icon: "crown.fill", title: L10n.string("settings.upgradePremium"), color: theme.primaryColor, theme: theme) {
                    showPaywall = true
                }
                Divider().background(theme.textTertiary.opacity(0.3))
            }

            // Restore Purchases — always show when authenticated
            if authService.isAuthenticated {
                SettingRow(icon: "arrow.clockwise", title: L10n.string("settings.restorePurchases"), color: theme.primaryColor, theme: theme) {
                    Task { await purchaseService.restore() }
                }
                Divider().background(theme.textTertiary.opacity(0.3))
            }

            // iCloud Sync status
            if authService.isAuthenticated && isPremium {
                SettingRow(icon: "icloud.fill", title: L10n.string("settings.iCloudSync"), value: L10n.string("settings.lastSyncPrefix") + " \(lastSyncText)", color: theme.primaryColor, theme: theme) {
                    Task {
                        CloudKitService.shared.syncAll(tripStore: TripStore.shared, pedometerService: PedometerService.shared)
                        lastCloudKitSync = Date().timeIntervalSince1970
                    }
                }
            } else {
                SettingRow(icon: "icloud.slash.fill", title: L10n.string("settings.iCloudSync"), value: L10n.string("settings.off"), color: theme.textTertiary, showChevron: false, theme: theme) {}
            }

            Divider().background(theme.textTertiary.opacity(0.3))

            // Sign In / Sign Out
            if authService.isAuthenticated {
                SettingRow(icon: "rectangle.portrait.and.arrow.right", title: L10n.string("settings.signOut"), color: Color(hex: "FF3B5C"), showChevron: false, theme: theme) {
                    showLogoutAlert = true
                }
            } else {
                SettingRow(icon: "apple.logo", title: L10n.string("settings.appleSignIn"), color: theme.primaryColor, theme: theme) {
                    authService.signIn { }
                }
            }
        }
    }

    // MARK: - Appearance Section
    var appearanceSection: some View {
        SettingsSection(title: L10n.string("settings.appearance").uppercased(), theme: theme) {
            SettingToggle(
                icon: isDarkMode ? "moon.fill" : "sun.max.fill",
                title: L10n.string("settings.darkMode"),
                color: theme.primaryColor,
                isOn: Binding(get: { isDarkMode }, set: { isDarkMode = $0; theme.isDarkMode = $0 }),
                theme: theme
            )
            Divider().background(theme.textTertiary.opacity(0.3))
            if isPremium {
                SettingRow(icon: "paintpalette.fill", title: L10n.string("settings.themeColor"), value: localizedThemeName, color: theme.primaryColor, theme: theme) {
                    showColorPicker = true
                }
            } else {
                lockedPremiumRow(icon: "paintpalette.fill", title: L10n.string("settings.themeColor"))
            }
            Divider().background(theme.textTertiary.opacity(0.3))
            SettingToggle(icon: "arrow.left.arrow.right", title: L10n.string("settings.mirrorMode"), color: theme.primaryColor, isOn: $isMirrorModeEnabled, theme: theme)
        }
    }

    // MARK: - Tracking Section
    var trackingSection: some View {
        SettingsSection(title: L10n.string("settings.tracking").uppercased(), theme: theme) {
            SettingRow(icon: "gauge", title: L10n.string("settings.speedUnit"), value: L10n.string(speedUnit.localizationKey), color: theme.primaryColor, theme: theme) {
                showSpeedUnitPicker = true
            }
            Divider().background(theme.textTertiary.opacity(0.3))

            if isPremium {
                VStack(spacing: 8) {
                    HStack(spacing: AppConstants.Design.paddingM) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.title3)
                            .foregroundColor(theme.primaryColor).frame(width: 32)
                        Text(L10n.text("settings.maxSpeedLimit")).font(.bodyMedium).foregroundColor(theme.textPrimary)
                        Spacer()
                        Text("\(Int(maxSpeedLimit)) \(L10n.string(speedUnit.localizationKey))").font(.bodySmall)
                            .foregroundColor(theme.primaryColor)
                    }
                    Slider(value: $maxSpeedLimit, in: 20...300, step: 5).tint(theme.primaryColor)
                }
                .padding(.horizontal, AppConstants.Design.paddingM)
                .padding(.vertical, AppConstants.Design.paddingM)
            } else {
                lockedPremiumRow(icon: "exclamationmark.triangle.fill", title: L10n.string("settings.maxSpeedLimit"))
            }

            Divider().background(theme.textTertiary.opacity(0.3))

            if isPremium {
                VStack(spacing: 8) {
                    HStack(spacing: AppConstants.Design.paddingM) {
                        Image(systemName: "tortoise.fill").font(.title3)
                            .foregroundColor(theme.primaryColor).frame(width: 32)
                        Text(L10n.text("settings.minSpeedThreshold")).font(.bodyMedium).foregroundColor(theme.textPrimary)
                        Spacer()
                        Text("\(Int(minSpeedLimit)) \(L10n.string(speedUnit.localizationKey))").font(.bodySmall)
                            .foregroundColor(theme.primaryColor)
                    }
                    Slider(value: $minSpeedLimit, in: 0...50, step: 1).tint(theme.primaryColor)
                }
                .padding(.horizontal, AppConstants.Design.paddingM)
                .padding(.vertical, AppConstants.Design.paddingM)
            } else {
                lockedPremiumRow(icon: "tortoise.fill", title: L10n.string("settings.minSpeedThreshold"))
            }

            Divider().background(theme.textTertiary.opacity(0.3))

            SettingToggle(icon: isSoundMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                          title: L10n.string("settings.soundAlerts"),
                          color: theme.primaryColor,
                          isOn: Binding(get: { !isSoundMuted }, set: { isSoundMuted = !$0 }),
                          theme: theme)

            Divider().background(theme.textTertiary.opacity(0.3))

            SettingToggle(icon: "waveform", title: L10n.string("settings.hapticFeedback"), color: theme.primaryColor, isOn: $isHapticsEnabled, theme: theme)
        }
    }

    @ViewBuilder
    func lockedPremiumRow(icon: String, title: String) -> some View {
        SettingRow(icon: icon, title: title, value: L10n.string("common.premium"), color: Color(hex: "FFD700"), theme: theme) {
            showPaywall = true
        }
    }

    // MARK: - General Section
    var generalSection: some View {
        SettingsSection(title: L10n.string("settings.general").uppercased(), theme: theme) {
            SettingRow(icon: "globe", title: L10n.string("settings.language"), value: currentLanguage.displayName,
                       color: theme.primaryColor, theme: theme) {
                showLanguagePicker = true
            }
        }
    }

    // MARK: - Support Section
    var supportSection: some View {
        SettingsSection(title: L10n.string("settings.support").uppercased(), theme: theme) {
            SettingRow(icon: "star.fill", title: L10n.string("settings.rateApp"), color: theme.primaryColor, theme: theme) {
                if let url = URL(string: AppConstants.URLs.rateApp) { UIApplication.shared.open(url) }
            }
            Divider().background(theme.textTertiary.opacity(0.3))
            SettingRow(icon: "questionmark.circle.fill", title: L10n.string("settings.contactUs"), color: theme.primaryColor, theme: theme) {
                if let url = URL(string: AppConstants.URLs.contactUs) { UIApplication.shared.open(url) }
            }
            Divider().background(theme.textTertiary.opacity(0.3))
            SettingRow(icon: "doc.text.fill", title: L10n.string("settings.privacyPolicy"), color: theme.primaryColor, theme: theme) {
                if let url = URL(string: AppConstants.URLs.privacyPolicy) { UIApplication.shared.open(url) }
            }
            Divider().background(theme.textTertiary.opacity(0.3))
            SettingRow(icon: "doc.plaintext.fill", title: L10n.string("settings.termsOfService"), color: theme.primaryColor, theme: theme) {
                if let url = URL(string: AppConstants.URLs.termsOfService) { UIApplication.shared.open(url) }
            }
            Divider().background(theme.textTertiary.opacity(0.3))
            SettingRow(icon: "info.circle.fill", title: L10n.string("settings.about"), value: "v\(AppConstants.App.version)",
                       color: theme.primaryColor, showChevron: false, theme: theme) {}
        }
    }

    // MARK: - Data Section
    var dataSection: some View {
        SettingsSection(title: L10n.string("settings.data").uppercased(), theme: theme) {
            SettingRow(icon: "trash.fill", title: L10n.string("settings.resetAllData"), color: Color(hex: "FF3B5C"), theme: theme) {
                showResetAlert = true
            }
        }
    }

    // MARK: - Picker Sheets
    var speedUnitPickerSheet: some View {
        PickerSheet(title: L10n.string("settings.speedUnit"), theme: theme) {
            ForEach(AppConstants.SpeedUnit.allCases, id: \.rawValue) { unit in
                Button {
                    speedUnitRaw = unit.rawValue
                    showSpeedUnitPicker = false
                    HapticManager.shared.selection()
                } label: {
                    HStack {
                        Text(L10n.string(unit.localizationKey)).font(.bodyLarge).foregroundColor(theme.textPrimary)
                        Spacer()
                        if speedUnit == unit { Image(systemName: "checkmark.circle.fill").foregroundColor(theme.primaryColor) }
                    }
                    .padding(.vertical, 12).padding(.horizontal, 20)
                }
            }
        }
    }

    var colorPickerSheet: some View {
        PickerSheet(title: L10n.string("settings.themeColor"), theme: theme) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                ForEach(AppConstants.ThemeColor.allCases, id: \.rawValue) { color in
                    Button {
                        theme.themeColor = color; showColorPicker = false; HapticManager.shared.selection()
                    } label: {
                        VStack(spacing: 8) {
                            Circle().fill(color.gradient).frame(width: 50, height: 50)
                                .overlay(Circle().strokeBorder(Color.white, lineWidth: theme.themeColor == color ? 3 : 0))
                                .shadow(color: color.primaryColor.opacity(theme.themeColor == color ? 0.5 : 0), radius: 8)
                            Text(L10n.string(color.displayNameKey)).font(.caption).foregroundColor(theme.textSecondary)
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    var languagePickerSheet: some View {
        PickerSheet(title: L10n.string("settings.language"), theme: theme) {
            ForEach(AppConstants.SupportedLanguage.allCases, id: \.rawValue) { lang in
                Button {
                    showLanguagePicker = false
                    if lang.rawValue != preferredLanguage {
                        preferredLanguage = lang.rawValue
                        localizationManager.currentLanguage = lang
                    }
                    HapticManager.shared.selection()
                } label: {
                    HStack(spacing: 12) {
                        Text(lang.flagEmoji).font(.system(size: 20))
                        Text(lang.displayName).font(.bodyMedium).foregroundColor(theme.textPrimary)
                        Spacer()
                        if currentLanguage == lang { Image(systemName: "checkmark.circle.fill").foregroundColor(theme.primaryColor) }
                    }
                    .padding(.vertical, 10).padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Setting Components (reused across app)
struct SettingsSection<Content: View>: View {
    let title: String
    let theme: ThemeManager
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.label)
                .foregroundColor(theme.textTertiary)
                .padding(.horizontal, AppConstants.Design.paddingM)
                .padding(.bottom, 8)
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

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppConstants.Design.paddingM) {
                Image(systemName: icon).font(.title3).foregroundColor(color).frame(width: 32)
                Text(title).font(.bodyMedium).foregroundColor(theme.textPrimary)
                Spacer()
                if !value.isEmpty {
                    Text(value).font(.bodySmall).foregroundColor(theme.textSecondary)
                }
                if showChevron {
                    Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(theme.textTertiary)
                }
            }
            .padding(.horizontal, AppConstants.Design.paddingM)
            .padding(.vertical, AppConstants.Design.paddingM)
        }
        .buttonStyle(.plain)
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
            Image(systemName: icon).font(.title3).foregroundColor(color).frame(width: 32)
            Text(title).font(.bodyMedium).foregroundColor(theme.textPrimary)
            Spacer()
            Toggle("", isOn: $isOn).tint(theme.primaryColor).labelsHidden()
        }
        .padding(.horizontal, AppConstants.Design.paddingM)
        .padding(.vertical, AppConstants.Design.paddingM)
    }
}

struct PickerSheet<Content: View>: View {
    let title: String
    let theme: ThemeManager
    @ViewBuilder let content: Content

    var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        content
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
