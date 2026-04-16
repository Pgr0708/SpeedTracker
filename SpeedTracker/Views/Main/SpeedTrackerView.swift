//
//  SpeedTrackerView.swift
//  SpeedTracker
//
import SwiftUI

struct SpeedTrackerView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var purchaseService: PurchaseService
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var tripStore = TripStore.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var audioService = AudioService.shared

    @AppStorage(AppConstants.UserDefaultsKeys.preferredSpeedUnit) private var speedUnitRaw = AppConstants.SpeedUnit.kmh.rawValue
    @AppStorage(AppConstants.UserDefaultsKeys.maxSpeedLimit) private var maxSpeedLimit: Double = 120
    @AppStorage(AppConstants.UserDefaultsKeys.minSpeedLimit) private var minSpeedLimit: Double = 0
    @AppStorage(AppConstants.UserDefaultsKeys.isPremium) private var isPremium = false

    @State private var animateGlow = false
    @State private var showStopConfirm = false
    @State private var lastMaxAlertSpeed: Double = 0
    @State private var lastMinAlertSpeed: Double = 999
    @State private var showSpeedAlert = false
    @State private var alertIsMax = true
    @State private var alertSpeed: Double = 0
    @State private var showPaywall = false

    var speedUnit: AppConstants.SpeedUnit { AppConstants.SpeedUnit(rawValue: speedUnitRaw) ?? .kmh }
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
    var speedColor: Color {
        if displaySpeed > maxSpeedLimit { return Color(hex:"FF3B5C") }
        if displaySpeed > maxSpeedLimit * 0.8 { return AppConstants.Colors.neonOrange }
        return theme.primaryColor
    }

    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppConstants.Design.paddingL) {
                    headerView
                    speedGaugeView
                    statsGrid
                    controlButton
                    Spacer().frame(height: 120)
                }
            }
            // Speed alert popup
            if showSpeedAlert {
                speedAlertOverlay
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .onAppear { animateGlow = true }
        .onChange(of: displaySpeed) { _, newSpeed in
            guard isPremium, locationManager.isTracking else { return }
            // Max speed check
            if maxSpeedLimit > 0 && newSpeed > maxSpeedLimit && newSpeed - lastMaxAlertSpeed > 5 {
                lastMaxAlertSpeed = newSpeed
                triggerAlert(isMax: true, speed: newSpeed)
                notificationManager.scheduleMaxSpeedAlert(speed: newSpeed, limit: maxSpeedLimit, unit: speedUnit)
                audioService.playMaxSpeedAlert()
                HapticManager.shared.notification(type: .error)
            }
            // Min speed check (only if limit > 0 and was moving)
            if minSpeedLimit > 0 && locationManager.isMoving && newSpeed < minSpeedLimit && lastMinAlertSpeed - newSpeed > 3 {
                lastMinAlertSpeed = newSpeed
                triggerAlert(isMax: false, speed: newSpeed)
                notificationManager.scheduleMinSpeedAlert(speed: newSpeed, limit: minSpeedLimit, unit: speedUnit)
                audioService.playMinSpeedAlert()
                HapticManager.shared.notification(type: .warning)
            }
            if newSpeed > minSpeedLimit { lastMinAlertSpeed = newSpeed }
        }
        .alert("Stop Tracking?", isPresented: $showStopConfirm) {
            Button("Stop & Save", role: .destructive) { stopAndSave() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Your trip will be saved to history.") }
        .sheet(isPresented: $showPaywall) { PaywallView().environmentObject(theme).environmentObject(purchaseService) }
    }

    private func triggerAlert(isMax: Bool, speed: Double) {
        alertIsMax = isMax; alertSpeed = speed; showSpeedAlert = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { withAnimation { showSpeedAlert = false } }
    }

    // MARK: - Speed Alert Overlay
    var speedAlertOverlay: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: alertIsMax ? "exclamationmark.triangle.fill" : "tortoise.fill")
                    .font(.system(size: 22)).foregroundColor(alertIsMax ? Color(hex:"FF3B5C") : AppConstants.Colors.neonOrange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(alertIsMax ? "Max Speed Exceeded!" : "Below Min Speed")
                        .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    Text(String(format: "%.0f %@", alertSpeed, speedUnit.rawValue))
                        .font(.system(size: 13)).foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                Button(action: { audioService.toggleMute() }) {
                    Image(systemName: audioService.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 16)).foregroundColor(.white.opacity(0.7))
                }.padding(8)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14).fill(alertIsMax ? Color(hex:"FF3B5C").opacity(0.9) : AppConstants.Colors.neonOrange.opacity(0.9)))
            .padding(.horizontal, 20)
            Spacer()
        }.padding(.top, 16)
    }

    // MARK: - Header
    var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("SPEEDTRACKER")
                    .font(Font.custom(AppConstants.Typography.orbitronBold, size: 18))
                    .foregroundColor(theme.primaryColor)
                Text(locationManager.isTracking ? (locationManager.isMoving ? "Tracking..." : "Waiting...") : "Ready")
                    .font(.system(size: 13)).foregroundColor(theme.textSecondary)
            }
            Spacer()
            HStack(spacing: 8) {
                // Mute toggle
                Button(action: { audioService.toggleMute() }) {
                    Image(systemName: audioService.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 14)).foregroundColor(audioService.isMuted ? theme.textTertiary : theme.primaryColor)
                }.padding(8).background(Capsule().fill(theme.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.05)))
                // GPS pill
                HStack(spacing: 5) {
                    Circle().fill(locationManager.hasLocationPermission ? AppConstants.Colors.limeGreen : Color(hex:"FF3B5C")).frame(width: 7, height: 7)
                    Text(gpsStatusText).font(.system(size: 12, weight: .medium)).foregroundColor(theme.textSecondary)
                }.padding(.horizontal, 10).padding(.vertical, 7)
                    .background(Capsule().fill(theme.isDarkMode ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.regularMaterial)))
            }
        }
        .padding(.horizontal, AppConstants.Design.paddingL).padding(.top, AppConstants.Design.paddingXL)
    }

    var gpsStatusText: String {
        if !locationManager.hasLocationPermission { return "No GPS" }
        if locationManager.gpsAccuracy < 0 { return "GPS" }
        if locationManager.gpsAccuracy < 10 { return "GPS ★★★" }
        if locationManager.gpsAccuracy < 25 { return "GPS ★★" }
        return "GPS ★"
    }

    // MARK: - Speed Gauge
    var speedGaugeView: some View {
        ZStack {
            Circle().stroke(speedColor.opacity(0.25), lineWidth: 18).blur(radius: 10).frame(width: 270, height: 270)
                .scaleEffect(animateGlow && locationManager.isMoving ? 1.08 : 1.0)
                .animation(locationManager.isMoving ? .easeInOut(duration: 1.4).repeatForever(autoreverses: true) : .default, value: animateGlow)
            GlassMorphismCard(cornerRadius: 200, padding: 55) {
                VStack(spacing: 6) {
                    Text("\(Int(displaySpeed))")
                        .font(Font.custom(AppConstants.Typography.orbitronBold, size: 72))
                        .foregroundColor(speedColor)
                        .shadow(color: speedColor.opacity(0.5), radius: 12)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: Int(displaySpeed))
                    Text(speedUnit.rawValue)
                        .font(Font.custom(AppConstants.Typography.rajdhaniMedium, size: 18))
                        .foregroundColor(theme.textSecondary)
                    if displaySpeed > maxSpeedLimit && isPremium {
                        Text("OVER LIMIT").font(.system(size: 11, weight: .bold)).foregroundColor(Color(hex:"FF3B5C"))
                    }
                }
            }.frame(width: 270, height: 270)
        }.padding(.vertical, AppConstants.Design.paddingM)
    }

    // MARK: - Stats Grid
    var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppConstants.Design.paddingM) {
            StatCard(title: "MAX SPEED", value: "\(Int(displayMaxSpeed))", unit: speedUnit.rawValue, icon: "arrow.up.circle.fill", color: theme.primaryColor, theme: theme)
            StatCard(title: "AVG SPEED", value: "\(Int(displayAvgSpeed))", unit: speedUnit.rawValue, icon: "chart.line.uptrend.xyaxis", color: theme.primaryColor, theme: theme)
            StatCard(title: "DISTANCE", value: displayDistance, unit: distanceUnit, icon: "location.fill", color: theme.primaryColor, theme: theme)
            StatCard(title: "DURATION", value: elapsedFormatted, unit: "", icon: "clock.fill", color: theme.primaryColor, theme: theme)
            // Premium stats — only when tracking
            if locationManager.isTracking {
                premiumStatCard(title: "ALTITUDE", value: String(format:"%.0f",locationManager.altitude), unit: "m", icon: "mountain.2.fill")
                premiumStatCard(title: "HEADING", value: String(format:"%.0f°",locationManager.heading), unit: compassDirection(locationManager.heading), icon: "safari.fill")
            }
        }.padding(.horizontal, AppConstants.Design.paddingL)
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
                        Text(title).font(.system(size: 11, weight: .medium)).foregroundColor(theme.textTertiary)
                        Text("Premium").font(.system(size: 14, weight: .bold)).foregroundColor(Color(hex:"FFD700"))
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
            AnimatedButton(locationManager.isTracking ? "Stop & Save" : "Start Trip",
                           icon: locationManager.isTracking ? "stop.fill" : "play.fill",
                           variant: locationManager.isTracking ? .accent : .primary) {
                if locationManager.isTracking { showStopConfirm = true } else { locationManager.startTracking() }
            }
        }.padding(.horizontal, AppConstants.Design.paddingL)
    }

    private func stopAndSave() {
        if let trip = locationManager.stopTracking() { tripStore.saveTrip(trip); HapticManager.shared.notification(type: .success) }
        lastMaxAlertSpeed = 0; lastMinAlertSpeed = 999
    }
}

struct StatCard: View {
    let title: String; let value: String; let unit: String; let icon: String; let color: Color; let theme: ThemeManager
    var body: some View {
        GlassMorphismCard(cornerRadius: AppConstants.Design.cornerRadiusM, padding: AppConstants.Design.paddingM) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon).font(.title3).foregroundColor(color)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 11, weight: .medium)).foregroundColor(theme.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(value).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(theme.textPrimary).contentTransition(.numericText())
                        if !unit.isEmpty { Text(unit).font(.system(size: 11)).foregroundColor(theme.textSecondary) }
                    }
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview { SpeedTrackerView().environmentObject(ThemeManager.shared).environmentObject(PurchaseService.shared) }
