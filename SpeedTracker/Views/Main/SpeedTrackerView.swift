//
//  SpeedTrackerView.swift
//  SpeedTracker
//

import SwiftUI
import StoreKit
import StoreKit
import StoreKit

struct HUDActiveKey: PreferenceKey {
    static var defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) { value = nextValue() }
}

enum HomeMode: Int, CaseIterable {
    case normal = 0
    case hud = 1

    func title(isMirrorMode: Bool) -> String {
        switch self {
        case .normal: return L10n.string("main.tracking")
        case .hud: return isMirrorMode ? "Mirror" : "HUD"
        }
    }

    var icon: String {
        switch self {
        case .normal: return "speedometer"
        case .hud: return "car.windshield.front"
        }
    }
}

struct SpeedTrackerView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var authService: AuthService
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var tripStore = TripStore.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var audioService = AudioService.shared
    @StateObject private var tiltManager = TiltManager()

    @AppStorage(AppConstants.UserDefaultsKeys.preferredSpeedUnit) private var speedUnitRaw = AppConstants.SpeedUnit.kmh.rawValue
    @AppStorage(AppConstants.UserDefaultsKeys.maxSpeedLimit) private var maxSpeedLimit: Double = 120
    @AppStorage(AppConstants.UserDefaultsKeys.minSpeedLimit) private var minSpeedLimit: Double = 0
    @AppStorage(AppConstants.UserDefaultsKeys.isMirrorModeEnabled) private var isMirrorMode = false
    @AppStorage(AppConstants.UserDefaultsKeys.hasSeenHUDMirrorTip) private var hasSeenMirrorTip = false
    @State private var showMirrorTip = false
    @State private var mirrorTipDismissTask: DispatchWorkItem?
    @State private var showHUDControls = true
    @State private var hudControlsDismissTask: DispatchWorkItem?

    @State private var selectedMode: HomeMode = .normal
    @State private var animateGlow = false
    @State private var showStopConfirm = false
    @State private var lastMaxAlertSpeed: Double = 0
    @State private var lastMinAlertSpeed: Double = 999
    @State private var showSpeedAlert = false
    @State private var alertIsMax = true
    @State private var alertSpeed: Double = 0
    @State private var showPaywall = false
    @State private var isOverMaxVisible = false
    @State private var isBelowMinVisible = false
    @State private var hasEverExceededMinSpeed = false
    @AppStorage("savedTripCount") private var savedTripCount = 0
    @Environment(\.requestReview) var requestReview

    var speedUnit: AppConstants.SpeedUnit { AppConstants.SpeedUnit(rawValue: speedUnitRaw) ?? .kmh }
    var isPremium: Bool { purchaseService.isPremium }
    var maxGaugeValue: Double {
        switch speedUnit {
        case .kmh:   return 250
        case .mph:   return 155
        case .ms:    return 69
        case .knots: return 135
        }
    }
    var displaySpeed: Double { locationManager.convertedSpeed(locationManager.currentSpeed, unit: speedUnit) }
    var displayMaxSpeed: Double { locationManager.convertedSpeed(locationManager.maxSpeed, unit: speedUnit) }
    var displayAvgSpeed: Double { locationManager.convertedSpeed(locationManager.avgSpeed, unit: speedUnit) }
    var displayDistance: String {
        let d = locationManager.totalDistance
        return d >= 1000 ? String(format: "%.1f", d/1000) : String(format: "%.0f", d)
    }
    var distanceUnit: String { locationManager.totalDistance >= 1000 ? "km" : "m" }
    var elapsedFormatted: String {
        let t = Int(locationManager.elapsedTime); let m = t/60; let s = t%60
        return m >= 60 ? String(format:"%d:%02d:%02d",m/60,m%60,s) : String(format:"%d:%02d",m,s)
    }
    var localizedSpeedUnit: String { L10n.string(speedUnit.localizationKey) }
    var speedColor: Color {
        if displaySpeed > maxSpeedLimit { return Color(hex:"FF3B5C") }
        if displaySpeed > maxSpeedLimit * 0.8 { return AppConstants.Colors.neonOrange }
        return theme.primaryColor
    }
    var isReversedHUDDisplay: Bool { !isMirrorMode }

    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()

            switch selectedMode {
            case .normal:
                trackingContent
            case .hud:
                hudInlineContent
            }

            if showSpeedAlert && selectedMode == .normal {
                speedAlertOverlay
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if selectedMode == .normal {
                controlButton
                    .padding(.horizontal, AppConstants.Design.paddingL)
                    .padding(.top, AppConstants.Design.paddingS)
                    .padding(.bottom, 92)
                    .background(.clear)
            }
        }
        .preference(key: HUDActiveKey.self, value: selectedMode == .hud)
        .statusBar(hidden: selectedMode == .hud)
        .persistentSystemOverlays(selectedMode == .hud ? .hidden : .visible)
        .onAppear { animateGlow = true }
        .onChange(of: selectedMode) { _, newMode in
            if newMode == .hud && !isPremium {
                showPaywall = true
                selectedMode = .normal
                return
            }
            if newMode == .hud {
                tiltManager.isTrackingActive = true  // always active in HUD
                tiltManager.start()
                showHUDControls = !locationManager.isTracking
                scheduleHUDControlsAutoHideIfNeeded()
                presentMirrorTipIfNeeded()
            } else {
                tiltManager.stop()
                hideMirrorTip()
                hideHUDControls(cancelOnly: true)
            }
        }
        .onChange(of: isMirrorMode) { _, isEnabled in
            guard selectedMode == .hud else { return }
            presentMirrorTip(force: true, autoDismiss: false, mirrorEnabled: isEnabled)
        }
        .onChange(of: locationManager.isTracking) { _, isTracking in
            guard selectedMode == .hud else { return }
            if isTracking {
                showHUDControls = false
                scheduleHUDControlsAutoHideIfNeeded()
            } else {
                showHUDControls = true
                hideHUDControls(cancelOnly: true)
            }
        }
        .onChange(of: displaySpeed) { _, newSpeed in
            guard isPremium, locationManager.isTracking else { return }
            if maxSpeedLimit > 0 && newSpeed <= maxSpeedLimit {
                isOverMaxVisible = false
            }
            if minSpeedLimit > 0 && newSpeed >= minSpeedLimit {
                isBelowMinVisible = false
                hasEverExceededMinSpeed = true
            }

            if maxSpeedLimit > 0 && newSpeed > maxSpeedLimit && !isOverMaxVisible {
                lastMaxAlertSpeed = newSpeed
                isOverMaxVisible = true
                triggerAlert(isMax: true, speed: newSpeed)
                notificationManager.scheduleMaxSpeedAlert(speed: newSpeed, limit: maxSpeedLimit, unit: speedUnit)
                audioService.playMaxSpeedAlert()
                HapticManager.shared.notification(type: .error)
            }
            if minSpeedLimit > 0 && locationManager.isMoving && newSpeed < minSpeedLimit && !isBelowMinVisible && hasEverExceededMinSpeed {
                lastMinAlertSpeed = newSpeed
                isBelowMinVisible = true
                triggerAlert(isMax: false, speed: newSpeed)
                notificationManager.scheduleMinSpeedAlert(speed: newSpeed, limit: minSpeedLimit, unit: speedUnit)
                audioService.playMinSpeedAlert()
                HapticManager.shared.notification(type: .warning)
            }
            if newSpeed > minSpeedLimit {
                lastMinAlertSpeed = newSpeed
            }
        }
        .alert(L10n.string("alert.stopTrip.title"), isPresented: $showStopConfirm) {
            Button(L10n.string("alert.stopTrip.save"), role: .destructive) { stopAndSave() }
            Button(L10n.string("common.cancel"), role: .cancel) {}
        } message: { Text(L10n.string("alert.stopTrip.message")) }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(theme)
                .environmentObject(purchaseService)
                .environmentObject(authService)
        }
    }

    private func triggerAlert(isMax: Bool, speed: Double) {
        alertIsMax = isMax; alertSpeed = speed; showSpeedAlert = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { withAnimation { showSpeedAlert = false } }
    }

    // MARK: - Tracking Content
    var trackingContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: locationManager.isTracking ? AppConstants.Design.paddingL : AppConstants.Design.paddingXL) {
                headerView
                modeSelectorView
                speedGaugeView
                if locationManager.isTracking {
                    statsGrid
                    Spacer().frame(height: 120)
                } else {
                    startStateCard
                    Spacer().frame(height: 160)
                }
            }
        }
    }

    // MARK: - HUD Inline Content
    // MARK: - HUD Inline Content
    var hudInlineContent: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GeometryReader { proxy in
                let isHorizontal = proxy.size.width > proxy.size.height
                let gaugeSize = isHorizontal
                    ? min(proxy.size.width * 0.94, proxy.size.height * 0.96)
                    : min(proxy.size.width * 0.88, proxy.size.height * 0.62)

                ZStack(alignment: .topTrailing) {
                    // Speedometer centred
                    SportBikeSpeedometer(
                        speed: displaySpeed,
                        unit: localizedSpeedUnit,
                        accentColor: speedColor,
                        theme: theme,
                        maxValue: maxGaugeValue,
                        diameter: gaugeSize,
                        mirrored: isReversedHUDDisplay
                    )
                    .rotationEffect(.degrees(isMirrorMode ? tiltManager.deviceRotation : -tiltManager.deviceRotation))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard locationManager.isTracking else { return }
                        toggleHUDControls()
                    }

                    // Top controls — horizontal row
                    if showHUDControls || !locationManager.isTracking {
                        HStack(spacing: 12) {
                            // X → back to normal
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedMode = .normal
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white.opacity(0.9))
                                    .frame(width: 38, height: 38)
                                    .background(Circle().fill(.white.opacity(0.12)))
                            }

                            // Start / Stop
                            if locationManager.isTracking {
                                Button { showStopConfirm = true } label: {
                                    Text(L10n.text("main.stopMini"))
                                        .font(.label)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(Color(hex: "FF3B5C")))
                                }
                            } else {
                                Button { locationManager.startTracking() } label: {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(width: 38, height: 38)
                                        .background(Circle().fill(theme.primaryColor))
                                }
                            }
                        }
                        .rotationEffect(.degrees(isHorizontal ? 90 : 0))
                        .padding(.top, proxy.safeAreaInsets.top + 16)
                        .padding(.trailing, 20)
                        .transition(.opacity)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }

            // Mirror mode switch prompt
            if showMirrorTip {
                VStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(theme.primaryColor)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(isMirrorMode ? "Mirror mode is active" : "Mirror mode is off")
                                    .font(.rajdhaniMedium(15))
                                    .foregroundColor(.white)
                                Text(isMirrorMode ? "Switch back to direct HUD view here or in Settings." : "Switch this screen to mirrored windshield view here or in Settings.")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            Spacer()
                        }

                        HStack(spacing: 10) {
                            Button {
                                HapticManager.shared.selection()
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                    isMirrorMode.toggle()
                                }
                            } label: {
                                Text(isMirrorMode ? "Use Direct HUD" : "Switch to Mirror")
                                    .font(.rajdhaniMedium(14))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Capsule().fill(theme.primaryColor))
                            }

                            Button {
                                hideMirrorTip()
                            } label: {
                                Text("Close")
                                    .font(.rajdhaniMedium(14))
                                    .foregroundColor(.white.opacity(0.88))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Capsule().fill(Color.white.opacity(0.08)))
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(theme.primaryColor.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 110)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    // MARK: - Speed Alert Overlay
    var speedAlertOverlay: some View {
        VStack {
            VStack(spacing: 18) {
                Image(systemName: alertIsMax ? "exclamationmark.shield.fill" : "tortoise.fill")
                    .font(.system(size: 42))
                    .foregroundColor(alertIsMax ? Color(hex:"FF3B5C") : AppConstants.Colors.neonOrange)
                VStack(spacing: 6) {
                    Text(alertIsMax ? L10n.text("alert.bigMaxTitle") : L10n.text("alert.bigMinTitle"))
                        .font(.orbitron(26))
                        .foregroundColor(alertIsMax ? Color(hex:"FF6B7B") : AppConstants.Colors.neonOrange)
                        .multilineTextAlignment(.center)
                    Text(alertIsMax ? L10n.text("alert.bigMaxBody") : L10n.text("alert.bigMinBody"))
                        .font(.bodyMedium)
                        .foregroundColor(.white.opacity(0.82))
                        .multilineTextAlignment(.center)
                    Text(String(format: "%.0f %@", alertSpeed, localizedSpeedUnit))
                        .font(.orbitron(34))
                        .foregroundColor(.white)
                }
                Button(action: { audioService.toggleMute() }) {
                    HStack(spacing: 8) {
                        Image(systemName: audioService.isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill")
                        Text(audioService.isMuted ? L10n.text("settings.soundOff") : L10n.text("settings.soundOn"))
                    }
                    .font(.label)
                    .foregroundColor(.white.opacity(0.82))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
                }
            }
            .padding(.horizontal, 24).padding(.vertical, 26)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.black.opacity(0.82))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .strokeBorder((alertIsMax ? Color(hex:"FF3B5C") : AppConstants.Colors.neonOrange).opacity(0.85), lineWidth: 2)
                    )
            )
            .padding(.horizontal, 20)
            .padding(.top, 24)
            Spacer()
        }
    }

    // MARK: - Header
    var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("SPEEDTRACKER")
                    .font(.orbitron(18))
                    .foregroundColor(theme.primaryColor)
                Text(locationManager.isTracking ? L10n.string("main.tracking") : L10n.string("main.ready"))
                    .font(.bodySmall).foregroundColor(theme.textSecondary)
            }
            Spacer()
            HStack(spacing: 8) {
                if locationManager.isTracking {
                    Button {
                        showStopConfirm = true
                    } label: {
                        Text(L10n.text("main.stopMini"))
                            .font(.label)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color(hex: "FF3B5C")))
                    }
                }
                // Mute toggle
                Button(action: { audioService.toggleMute() }) {
                    Image(systemName: audioService.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 14)).foregroundColor(audioService.isMuted ? theme.textTertiary : theme.primaryColor)
                }.padding(8).background(Capsule().fill(theme.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.05)))
                // GPS pill
                HStack(spacing: 5) {
                    Circle().fill(locationManager.hasLocationPermission ? AppConstants.Colors.limeGreen : Color(hex:"FF3B5C")).frame(width: 7, height: 7)
                    Text(gpsStatusText).font(.label).foregroundColor(theme.textSecondary)
                }.padding(.horizontal, 10).padding(.vertical, 7)
                    .background(Capsule().fill(theme.isDarkMode ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.regularMaterial)))
            }
        }
        .padding(.horizontal, AppConstants.Design.paddingL).padding(.top, AppConstants.Design.paddingXL)
    }

    var gpsStatusText: String {
        if !locationManager.hasLocationPermission { return L10n.string("main.noGPS") }
        return L10n.string("main.gps")
    }

    // MARK: - Mode Selector
    var modeSelectorView: some View {
        HStack(spacing: 4) {
            ForEach(HomeMode.allCases, id: \.rawValue) { mode in
                Button {
                    HapticManager.shared.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedMode = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 13, weight: .semibold))
                        Text(mode.title(isMirrorMode: isMirrorMode))
                            .font(.rajdhaniMedium(13))
                    }
                    .foregroundColor(selectedMode == mode ? .white : theme.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedMode == mode ? theme.primaryColor : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.05))
        )
        .padding(.horizontal, AppConstants.Design.paddingL)
    }

    // MARK: - Speed Gauge
    var speedGaugeView: some View {
        SportBikeSpeedometer(
            speed: displaySpeed,
            unit: localizedSpeedUnit,
            accentColor: speedColor,
            theme: theme,
            maxValue: maxGaugeValue
        )
        .padding(.vertical, AppConstants.Design.paddingM)
    }

    // MARK: - Stats Grid
    var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppConstants.Design.paddingM) {
            StatCard(title: L10n.string("main.maxSpeed").uppercased(), value: "\(Int(displayMaxSpeed))", unit: localizedSpeedUnit, icon: "arrow.up.circle.fill", color: theme.primaryColor, theme: theme)
            StatCard(title: L10n.string("main.avgSpeed").uppercased(), value: "\(Int(displayAvgSpeed))", unit: localizedSpeedUnit, icon: "chart.line.uptrend.xyaxis", color: theme.primaryColor, theme: theme)
            StatCard(title: L10n.string("main.distance").uppercased(), value: displayDistance, unit: distanceUnit, icon: "location.fill", color: theme.primaryColor, theme: theme)
            StatCard(title: L10n.string("main.duration").uppercased(), value: elapsedFormatted, unit: "", icon: "clock.fill", color: theme.primaryColor, theme: theme)
            if locationManager.isTracking {
                premiumStatCard(title: L10n.string("compass.altitude").uppercased(), value: String(format:"%.0f",locationManager.altitude), unit: "m", icon: "mountain.2.fill")
                premiumStatCard(title: L10n.string("compass.heading").uppercased(), value: String(format:"%.0f°",locationManager.heading), unit: compassDirection(locationManager.heading), icon: "safari.fill")
            }
        }.padding(.horizontal, AppConstants.Design.paddingL)
    }

    var startStateCard: some View {
        GlassMorphismCard(cornerRadius: AppConstants.Design.cornerRadiusL, padding: AppConstants.Design.paddingL) {
            VStack(spacing: 12) {
                Text(L10n.text("main.startPromptTitle"))
                    .font(.headingSmall)
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
                Text(L10n.text("main.startPromptSubtitle"))
                    .font(.bodySmall)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, AppConstants.Design.paddingL)
    }

    @ViewBuilder
    func premiumStatCard(title: String, value: String, unit: String, icon: String) -> some View {
        if isPremium {
            StatCard(title: title, value: value, unit: unit, icon: icon, color: theme.primaryColor, theme: theme)
        } else {
            Button { showPaywall = true } label: {
                GlassMorphismCard(cornerRadius: AppConstants.Design.cornerRadiusM, padding: AppConstants.Design.paddingM) {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "lock.fill").font(.title3).foregroundColor(theme.textTertiary)
                        Text(title).font(.label).foregroundColor(theme.textTertiary)
                        Text(L10n.text("common.premium")).font(.bodyMedium).foregroundColor(Color(hex:"FFD700"))
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    func compassDirection(_ degrees: Double) -> String {
        let dirs = ["N","NE","E","SE","S","SW","W","NW"]
        return dirs[Int((degrees + 22.5) / 45) % 8]
    }

    // MARK: - Control
    var controlButton: some View {
        HStack(spacing: 12) {
            if !locationManager.isTracking {
                AnimatedButton(L10n.string("main.startTrip"),
                               icon: "play.fill",
                               variant: .primary) {
                    locationManager.startTracking()
                }
            }
        }
    }

    private func stopAndSave() {
        if let trip = locationManager.stopTracking() { tripStore.saveTrip(trip); HapticManager.shared.notification(type: .success) }
        lastMaxAlertSpeed = 0; lastMinAlertSpeed = 999
        isOverMaxVisible = false
        isBelowMinVisible = false
        hasEverExceededMinSpeed = false
        audioService.resetAlertCooldowns()
        savedTripCount += 1
        if savedTripCount == 2 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { requestReview() }
        }
    }

    private func presentMirrorTipIfNeeded() {
        if !hasSeenMirrorTip {
            presentMirrorTip(force: true, autoDismiss: true, mirrorEnabled: isMirrorMode)
            hasSeenMirrorTip = true
            return
        }
        presentMirrorTip(force: false, autoDismiss: false, mirrorEnabled: isMirrorMode)
    }

    private func presentMirrorTip(force: Bool, autoDismiss: Bool, mirrorEnabled: Bool) {
        mirrorTipDismissTask?.cancel()
        guard force || selectedMode == .hud else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard selectedMode == .hud, isMirrorMode == mirrorEnabled else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                showMirrorTip = true
            }
        }

        guard autoDismiss else { return }

        let dismissTask = DispatchWorkItem {
            hideMirrorTip()
        }
        mirrorTipDismissTask = dismissTask
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: dismissTask)
    }

    private func hideMirrorTip() {
        mirrorTipDismissTask?.cancel()
        mirrorTipDismissTask = nil
        withAnimation(.easeInOut(duration: 0.2)) {
            showMirrorTip = false
        }
    }

    private func toggleHUDControls() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showHUDControls.toggle()
        }
        scheduleHUDControlsAutoHideIfNeeded()
    }

    private func scheduleHUDControlsAutoHideIfNeeded() {
        hudControlsDismissTask?.cancel()
        guard selectedMode == .hud, locationManager.isTracking, showHUDControls else { return }

        let dismissTask = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.2)) {
                showHUDControls = false
            }
        }
        hudControlsDismissTask = dismissTask
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: dismissTask)
    }

    private func hideHUDControls(cancelOnly: Bool = false) {
        hudControlsDismissTask?.cancel()
        hudControlsDismissTask = nil
        guard !cancelOnly else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            showHUDControls = false
        }
    }
}

struct StatCard: View {
    let title: String; let value: String; let unit: String; let icon: String; let color: Color; let theme: ThemeManager
    var body: some View {
        GlassMorphismCard(cornerRadius: AppConstants.Design.cornerRadiusM, padding: AppConstants.Design.paddingM) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon).font(.title3).foregroundColor(color)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.label).foregroundColor(theme.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(value).font(.orbitron(22)).foregroundColor(theme.textPrimary).contentTransition(.numericText())
                        if !unit.isEmpty { Text(unit).font(.caption).foregroundColor(theme.textSecondary) }
                    }
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct SportBikeSpeedometer: View {
    let speed: Double
    let unit: String
    let accentColor: Color
    let theme: ThemeManager
    let maxValue: Double
    var diameter: CGFloat = 300
    var mirrored: Bool = false

    private var normalizedSpeed: Double {
        min(max(speed / maxValue, 0), 1)
    }

    private var needleAngle: Double {
        -120 + (normalizedSpeed * 240)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accentColor.opacity(0.18), .clear],
                        center: .center,
                        startRadius: diameter * 0.12,
                        endRadius: diameter * 0.54
                    )
                )
                .frame(width: diameter, height: diameter)
                .blur(radius: 18)
                .scaleEffect(animateScale)

            gaugeRing

            ZStack {
                Circle()
                    .fill(theme.isDarkMode ? Color.black.opacity(0.22) : Color.white.opacity(0.26))
                    .overlay(Circle().fill(.ultraThinMaterial).opacity(0.95))
                    .overlay(Circle().stroke(Color.white.opacity(theme.isDarkMode ? 0.08 : 0.28), lineWidth: 1))
                    .frame(width: diameter * 0.43, height: diameter * 0.43)
                    .blur(radius: 6)

                VStack(spacing: max(2, diameter * 0.012)) {
                    Text(L10n.text("main.speed"))
                        .font(.label)
                        .foregroundColor(theme.textSecondary)
                    Text("\(Int(speed))")
                        .font(.orbitron(diameter * 0.22))
                        .foregroundColor(accentColor)
                        .contentTransition(.numericText())
                    Text(unit)
                        .font(.bodyMedium)
                        .foregroundColor(theme.textSecondary)
                    if speed > maxValue * 0.8 {
                        Text(L10n.text("main.livePerformance"))
                            .font(.caption)
                            .foregroundColor(accentColor)
                    }
                }
                .offset(y: -diameter * 0.01)
            }
            .frame(width: diameter * 0.44, height: diameter * 0.44)
            .scaleEffect(x: mirrored ? -1 : 1, y: 1)
        }
        .frame(width: diameter, height: diameter)
    }

    private var animateScale: CGFloat {
        speed > 0.5 ? 1.02 : 1.0
    }

    private var gaugeRing: some View {
        ZStack {
            Circle()
                .trim(from: 0.17, to: 0.83)
                .stroke(theme.textTertiary.opacity(0.18), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(90))

            Circle()
                .trim(from: 0.17, to: 0.17 + (0.66 * normalizedSpeed))
                .stroke(
                    AngularGradient(colors: [theme.primaryColor, accentColor, Color(hex: "FF3B5C")], center: .center),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(90))

            ForEach(0..<13, id: \.self) { index in
                let angle = -120.0 + (Double(index) * 20.0)
                VStack(spacing: 6) {
                    Rectangle()
                        .fill(index > 9 ? Color(hex: "FF3B5C") : theme.textSecondary.opacity(0.65))
                        .frame(width: 2, height: index % 2 == 0 ? 14 : 10)
                    Text("\(Int((maxValue / 12) * Double(index)))")
                        .font(.rajdhaniRegular(9))
                        .foregroundColor(theme.textSecondary.opacity(0.75))
                }
                .offset(y: -(diameter * 0.34))
                .rotationEffect(.degrees(angle))
                .scaleEffect(x: mirrored ? -1 : 1, y: 1)
            }

            ZStack {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white, accentColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 6, height: diameter * 0.28)
                    .offset(y: -(diameter * 0.14))
                Circle()
                    .fill(Color.black)
                    .frame(width: diameter * 0.12, height: diameter * 0.12)
                    .overlay(Circle().strokeBorder(accentColor.opacity(0.8), lineWidth: 3))
            }
            .rotationEffect(.degrees(needleAngle))
            .animation(.spring(response: 0.25, dampingFraction: 0.82), value: needleAngle)

            Circle()
                .stroke(theme.textTertiary.opacity(0.15), lineWidth: 1)
                .frame(width: diameter * 0.52, height: diameter * 0.52)
        }
        .frame(width: diameter, height: diameter)
    }
}
