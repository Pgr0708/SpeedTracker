//
//  SettingsView.swift
//  SpeedTracker
//
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var purchaseService: PurchaseService
    @StateObject private var authService = AuthService.shared
    @StateObject private var cloudKitService = CloudKitService.shared

    @AppStorage(AppConstants.UserDefaultsKeys.preferredSpeedUnit) private var speedUnitRaw: String = AppConstants.SpeedUnit.kmh.rawValue
    @AppStorage(AppConstants.UserDefaultsKeys.isHapticEnabled) private var isHapticsEnabled = true
    @AppStorage(AppConstants.UserDefaultsKeys.isDarkModeEnabled) private var isDarkMode = true
    @AppStorage(AppConstants.UserDefaultsKeys.maxSpeedLimit) private var maxSpeedLimit: Double = 120
    @AppStorage(AppConstants.UserDefaultsKeys.minSpeedLimit) private var minSpeedLimit: Double = 0
    @AppStorage(AppConstants.UserDefaultsKeys.preferredLanguage) private var preferredLanguage: String = "en"
    @AppStorage(AppConstants.UserDefaultsKeys.isSoundMuted) private var isSoundMuted = false
    @AppStorage(AppConstants.UserDefaultsKeys.isMirrorModeEnabled) private var isMirrorModeEnabled = false
    @AppStorage(AppConstants.UserDefaultsKeys.isPremium) private var isPremium = false
    @AppStorage(AppConstants.UserDefaultsKeys.didLogOut) private var didLogOut = false
    @AppStorage(AppConstants.UserDefaultsKeys.lastCloudKitSync) private var lastCloudKitSync: Double = 0

    @State private var showSpeedUnitPicker = false
    @State private var showColorPicker = false
    @State private var showLanguagePicker = false
    @State private var showResetAlert = false
    @State private var showLogoutAlert = false
    @State private var showLanguageRestartAlert = false
    @State private var pendingLanguage: AppConstants.SupportedLanguage?

    var speedUnit: AppConstants.SpeedUnit { AppConstants.SpeedUnit(rawValue: speedUnitRaw) ?? .kmh }
    var currentLanguage: AppConstants.SupportedLanguage { AppConstants.SupportedLanguage(rawValue: preferredLanguage) ?? .english }

    var lastSyncText: String {
        guard lastCloudKitSync > 0 else { return "Never" }
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
        .alert("Reset All Data?", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) {
                let domain = Bundle.main.bundleIdentifier ?? "com.centillion.SpeedTracker"
                UserDefaults.standard.removePersistentDomain(forName: domain)
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This will delete all trips and reset preferences. This cannot be undone.") }
        .alert("Sign Out?", isPresented: $showLogoutAlert) {
            Button("Sign Out", role: .destructive) {
                authService.signOut()
                didLogOut = true
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("You can sign back in at any time to restore your data.") }
        .alert("Restart Required", isPresented: $showLanguageRestartAlert) {
            Button("Apply & Restart") {
                if let lang = pendingLanguage {
                    preferredLanguage = lang.rawValue
                    UserDefaults.standard.set([lang.rawValue], forKey: "AppleLanguages")
                    UserDefaults.standard.synchronize()
                    // Exit so iOS relaunches with new language bundle
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { exit(0) }
                }
            }
            Button("Cancel", role: .cancel) { pendingLanguage = nil }
        } message: { Text("The app will need to restart to apply the new language.") }
    }

    // MARK: - Header
    var headerView: some View {
        HStack {
            Text("SETTINGS")
                .font(Font.custom(AppConstants.Typography.orbitronBold, size: 28))
                .foregroundColor(theme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, AppConstants.Design.paddingL)
        .padding(.top, AppConstants.Design.paddingXL)
    }

    // MARK: - Account Section
    var accountSection: some View {
        SettingsSection(title: "ACCOUNT", theme: theme) {
            // Profile display
            HStack(spacing: AppConstants.Design.paddingM) {
                ZStack {
                    Circle()
                        .fill(theme.primaryColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(theme.primaryColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(authService.displayName.isEmpty ? "SpeedTracker User" : authService.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                    Text(authService.email.isEmpty ? "Apple Sign In" : authService.email)
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                }
                Spacer()
                if isPremium {
                    Label("Premium", systemImage: "crown.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "FFD700"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "FFD700").opacity(0.15))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, AppConstants.Design.paddingM)
            .padding(.vertical, AppConstants.Design.paddingM)

            Divider().background(theme.textTertiary.opacity(0.3))

            if !isPremium {
                SettingRow(icon: "crown.fill", title: "Upgrade to Premium", color: Color(hex: "FFD700"), theme: theme) { }
                Divider().background(theme.textTertiary.opacity(0.3))
            }

            SettingRow(icon: "arrow.clockwise", title: "Restore Purchases", color: theme.primaryColor, theme: theme) {
                Task { await purchaseService.restore() }
            }

            Divider().background(theme.textTertiary.opacity(0.3))

            if isPremium {
                SettingRow(icon: "icloud.fill", title: "iCloud Sync", value: "Last: \(lastSyncText)", color: Color(hex: "00D9FF"), theme: theme) {
                    Task {
                        CloudKitService.shared.syncAll(tripStore: TripStore.shared, pedometerService: PedometerService.shared)
                        lastCloudKitSync = Date().timeIntervalSince1970
                    }
                }
                Divider().background(theme.textTertiary.opacity(0.3))
            }

            SettingRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", color: Color(hex: "FF3B5C"), showChevron: false, theme: theme) {
                showLogoutAlert = true
            }
        }
    }

    // MARK: - Appearance Section
    var appearanceSection: some View {
        SettingsSection(title: "APPEARANCE", theme: theme) {
            SettingToggle(
                icon: isDarkMode ? "moon.fill" : "sun.max.fill",
                title: "Dark Mode",
                color: theme.primaryColor,
                isOn: Binding(get: { isDarkMode }, set: { isDarkMode = $0; theme.isDarkMode = $0 }),
                theme: theme
            )
            Divider().background(theme.textTertiary.opacity(0.3))
            SettingRow(icon: "paintpalette.fill", title: "Theme Color", value: theme.themeColor.displayName, color: theme.primaryColor, theme: theme) {
                showColorPicker = true
            }
            Divider().background(theme.textTertiary.opacity(0.3))
            SettingToggle(icon: "arrow.left.arrow.right", title: "Mirror Mode (HUD)", color: Color(hex: "FF3B5C"), isOn: $isMirrorModeEnabled, theme: theme)
        }
    }

    // MARK: - Tracking Section
    var trackingSection: some View {
        SettingsSection(title: "TRACKING", theme: theme) {
            SettingRow(icon: "gauge", title: "Speed Unit", value: speedUnit.rawValue, color: theme.primaryColor, theme: theme) {
                showSpeedUnitPicker = true
            }
            Divider().background(theme.textTertiary.opacity(0.3))

            VStack(spacing: 8) {
                HStack(spacing: AppConstants.Design.paddingM) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.title3)
                        .foregroundColor(AppConstants.Colors.neonOrange).frame(width: 32)
                    Text("Max Speed Limit").font(.system(size: 15, weight: .medium)).foregroundColor(theme.textPrimary)
                    Spacer()
                    Text("\(Int(maxSpeedLimit)) \(speedUnit.rawValue)").font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppConstants.Colors.neonOrange)
                }
                Slider(value: $maxSpeedLimit, in: 20...300, step: 5).tint(AppConstants.Colors.neonOrange)
            }
            .padding(.horizontal, AppConstants.Design.paddingM)
            .padding(.vertical, AppConstants.Design.paddingM)

            Divider().background(theme.textTertiary.opacity(0.3))

            VStack(spacing: 8) {
                HStack(spacing: AppConstants.Design.paddingM) {
                    Image(systemName: "tortoise.fill").font(.title3)
                        .foregroundColor(AppConstants.Colors.limeGreen).frame(width: 32)
                    Text("Min Speed Threshold").font(.system(size: 15, weight: .medium)).foregroundColor(theme.textPrimary)
                    Spacer()
                    Text("\(Int(minSpeedLimit)) \(speedUnit.rawValue)").font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppConstants.Colors.limeGreen)
                }
                Slider(value: $minSpeedLimit, in: 0...50, step: 1).tint(AppConstants.Colors.limeGreen)
            }
            .padding(.horizontal, AppConstants.Design.paddingM)
            .padding(.vertical, AppConstants.Design.paddingM)

            Divider().background(theme.textTertiary.opacity(0.3))

            SettingToggle(icon: isSoundMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                          title: "Speed Alert Sounds",
                          color: AppConstants.Colors.neonOrange,
                          isOn: Binding(get: { !isSoundMuted }, set: { isSoundMuted = !$0 }),
                          theme: theme)

            Divider().background(theme.textTertiary.opacity(0.3))

            SettingToggle(icon: "waveform", title: "Haptic Feedback", color: theme.primaryColor, isOn: $isHapticsEnabled, theme: theme)
        }
    }

    // MARK: - General Section
    var generalSection: some View {
        SettingsSection(title: "GENERAL", theme: theme) {
            SettingRow(icon: "globe", title: "Language", value: currentLanguage.displayName,
                       color: AppConstants.Colors.limeGreen, theme: theme) {
                showLanguagePicker = true
            }
        }
    }

    // MARK: - Support Section
    var supportSection: some View {
        SettingsSection(title: "SUPPORT", theme: theme) {
            SettingRow(icon: "star.fill", title: "Rate App", color: Color(hex: "FFD700"), theme: theme) {
                if let url = URL(string: AppConstants.URLs.rateApp) { UIApplication.shared.open(url) }
            }
            Divider().background(theme.textTertiary.opacity(0.3))
            SettingRow(icon: "questionmark.circle.fill", title: "Contact Us", color: theme.primaryColor, theme: theme) {
                if let url = URL(string: AppConstants.URLs.contactUs) { UIApplication.shared.open(url) }
            }
            Divider().background(theme.textTertiary.opacity(0.3))
            SettingRow(icon: "doc.text.fill", title: "Privacy Policy", color: theme.primaryColor, theme: theme) {
                if let url = URL(string: AppConstants.URLs.privacyPolicy) { UIApplication.shared.open(url) }
            }
            Divider().background(theme.textTertiary.opacity(0.3))
            SettingRow(icon: "doc.plaintext.fill", title: "Terms of Service", color: theme.primaryColor, theme: theme) {
                if let url = URL(string: AppConstants.URLs.termsOfService) { UIApplication.shared.open(url) }
            }
            Divider().background(theme.textTertiary.opacity(0.3))
            SettingRow(icon: "info.circle.fill", title: "About", value: "v\(AppConstants.App.version)",
                       color: theme.primaryColor, showChevron: false, theme: theme) {}
        }
    }

    // MARK: - Data Section
    var dataSection: some View {
        SettingsSection(title: "DATA", theme: theme) {
            SettingRow(icon: "trash.fill", title: "Reset All Data", color: Color(hex: "FF3B5C"), theme: theme) {
                showResetAlert = true
            }
        }
    }

    // MARK: - Picker Sheets
    var speedUnitPickerSheet: some View {
        PickerSheet(title: "Speed Unit", theme: theme) {
            ForEach(AppConstants.SpeedUnit.allCases, id: \.rawValue) { unit in
                Button {
                    speedUnitRaw = unit.rawValue
                    showSpeedUnitPicker = false
                    HapticManager.shared.selection()
                } label: {
                    HStack {
                        Text(unit.rawValue).font(.system(size: 18, weight: .semibold)).foregroundColor(theme.textPrimary)
                        Spacer()
                        if speedUnit == unit { Image(systemName: "checkmark.circle.fill").foregroundColor(theme.primaryColor) }
                    }
                    .padding(.vertical, 12).padding(.horizontal, 20)
                }
            }
        }
    }

    var colorPickerSheet: some View {
        PickerSheet(title: "Theme Color", theme: theme) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                ForEach(AppConstants.ThemeColor.allCases, id: \.rawValue) { color in
                    Button {
                        theme.themeColor = color; showColorPicker = false; HapticManager.shared.selection()
                    } label: {
                        VStack(spacing: 8) {
                            Circle().fill(color.gradient).frame(width: 50, height: 50)
                                .overlay(Circle().strokeBorder(Color.white, lineWidth: theme.themeColor == color ? 3 : 0))
                                .shadow(color: color.primaryColor.opacity(theme.themeColor == color ? 0.5 : 0), radius: 8)
                            Text(color.displayName).font(.system(size: 11, weight: .medium)).foregroundColor(theme.textSecondary)
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    var languagePickerSheet: some View {
        PickerSheet(title: "Language", theme: theme) {
            ForEach(AppConstants.SupportedLanguage.allCases, id: \.rawValue) { lang in
                Button {
                    showLanguagePicker = false
                    if lang.rawValue != preferredLanguage {
                        pendingLanguage = lang
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showLanguageRestartAlert = true }
                    }
                    HapticManager.shared.selection()
                } label: {
                    HStack(spacing: 12) {
                        Text(lang.flagEmoji).font(.system(size: 20))
                        Text(lang.displayName).font(.system(size: 16)).foregroundColor(theme.textPrimary)
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
    let content: Content

    init(title: String, theme: ThemeManager, @ViewBuilder content: () -> Content) {
        self.title = title; self.theme = theme; self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Design.paddingS) {
            Text(title).font(.system(size: 12, weight: .bold)).foregroundColor(theme.textSecondary)
                .padding(.leading, AppConstants.Design.paddingS)
            GlassMorphismCard(padding: 0) { VStack(spacing: 0) { content } }
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

    init(icon: String, title: String, value: String = "", color: Color, showChevron: Bool = true, theme: ThemeManager, action: @escaping () -> Void = {}) {
        self.icon = icon; self.title = title; self.value = value
        self.color = color; self.showChevron = showChevron; self.theme = theme; self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppConstants.Design.paddingM) {
                Image(systemName: icon).font(.title3).foregroundColor(color).frame(width: 32)
                Text(title).font(.system(size: 15, weight: .medium)).foregroundColor(theme.textPrimary)
                Spacer()
                if !value.isEmpty { Text(value).font(.system(size: 13)).foregroundColor(theme.textSecondary) }
                if showChevron { Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(theme.textTertiary) }
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
            Image(systemName: icon).font(.title3).foregroundColor(color).frame(width: 32)
            Text(title).font(.system(size: 15, weight: .medium)).foregroundColor(theme.textPrimary)
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden().tint(theme.primaryColor)
        }
        .padding(.horizontal, AppConstants.Design.paddingM)
        .padding(.vertical, AppConstants.Design.paddingM)
    }
}

struct PickerSheet<Content: View>: View {
    let title: String
    let theme: ThemeManager
    let content: Content

    init(title: String, theme: ThemeManager, @ViewBuilder content: () -> Content) {
        self.title = title; self.theme = theme; self.content = content()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                ScrollView { VStack(spacing: 0) { content }.padding(.top, 20) }
            }
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

#Preview { SettingsView().environmentObject(ThemeManager.shared).environmentObject(PurchaseService.shared) }
