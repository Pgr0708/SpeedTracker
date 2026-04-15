//
//  SpeedTrackerView.swift
//  SpeedTracker
//
//  Main speed tracking screen with REAL GPS data
//

import SwiftUI
internal import _LocationEssentials

struct SpeedTrackerView: View {
    @EnvironmentObject var theme: ThemeManager
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var tripStore = TripStore.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    @AppStorage(AppConstants.UserDefaultsKeys.preferredSpeedUnit) private var speedUnitRaw: String = AppConstants.SpeedUnit.kmh.rawValue
    @AppStorage(AppConstants.UserDefaultsKeys.maxSpeedLimit) private var maxSpeedLimit: Double = 120
    @AppStorage(AppConstants.UserDefaultsKeys.minSpeedLimit) private var minSpeedLimit: Double = 0
    
    @State private var animateGlow = false
    @State private var showStopConfirm = false
    @State private var lastAlertSpeed: Double = 0
    
    var speedUnit: AppConstants.SpeedUnit {
        AppConstants.SpeedUnit(rawValue: speedUnitRaw) ?? .kmh
    }
    
    var displaySpeed: Double {
        locationManager.convertedSpeed(locationManager.currentSpeed, unit: speedUnit)
    }
    
    var displayMaxSpeed: Double {
        locationManager.convertedSpeed(locationManager.maxSpeed, unit: speedUnit)
    }
    
    var displayAvgSpeed: Double {
        locationManager.convertedSpeed(locationManager.avgSpeed, unit: speedUnit)
    }
    
    var displayDistance: String {
        let dist = locationManager.totalDistance
        if dist >= 1000 {
            return String(format: "%.1f", dist / 1000)
        }
        return String(format: "%.0f", dist)
    }
    
    var distanceUnit: String {
        locationManager.totalDistance >= 1000 ? "km" : "m"
    }
    
    var elapsedFormatted: String {
        let t = Int(locationManager.elapsedTime)
        let m = t / 60
        let s = t % 60
        if m >= 60 {
            return String(format: "%d:%02d:%02d", m/60, m%60, s)
        }
        return String(format: "%d:%02d", m, s)
    }
    
    var altitudeFormatted: String {
        if let altitude = locationManager.currentLocation?.altitude {
            return String(format: "%.0f", altitude)
        }
        return "--"
    }
    
    var coordinatesFormatted: (String, String) {
        if let location = locationManager.currentLocation {
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            return (String(format: "%.4f", lat), String(format: "%.4f", lon))
        }
        return ("--", "--")
    }
    
    // Speed color based on limits
    var speedColor: Color {
        if displaySpeed > maxSpeedLimit {
            return Color(hex: "FF3B5C") // red - over limit
        } else if displaySpeed > maxSpeedLimit * 0.8 {
            return AppConstants.Colors.neonOrange // warning
        }
        return theme.primaryColor
    }
    
    var body: some View {
        ZStack {
            theme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppConstants.Design.paddingL) {
                    // Header
                    headerView
                    
                    // Main Speed Display
                    speedGaugeView
                    
                    // Stats Grid
                    statsGrid
                    
                    // Control Button
                    controlButton
                    
                    Spacer().frame(height: 80)
                }
            }
        }
        .onAppear {
            animateGlow = true
        }
        .onChange(of: displaySpeed) { _, newSpeed in
            // Speed limit alert
            if newSpeed > maxSpeedLimit && newSpeed - lastAlertSpeed > 5 {
                lastAlertSpeed = newSpeed
                HapticManager.shared.notification(type: .warning)
                notificationManager.scheduleSpeedAlert(speed: newSpeed, limit: maxSpeedLimit)
            }
        }
        .alert("Stop Tracking?", isPresented: $showStopConfirm) {
            Button("Stop & Save", role: .destructive) {
                stopAndSave()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your trip will be saved to history.")
        }
    }
    
    // MARK: - Header
    var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("SPEEDTRACKER")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(theme.primaryColor)
                
                Text(locationManager.isTracking ? 
                     (locationManager.isMoving ? "Tracking..." : "Waiting for movement") : 
                     "Ready to track")
                    .font(.system(size: 13))
                    .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
            
            // GPS Status
            HStack(spacing: 6) {
                Circle()
                    .fill(locationManager.hasLocationPermission ?
                          AppConstants.Colors.limeGreen : Color(hex: "FF3B5C"))
                    .frame(width: 8, height: 8)
                    .shadow(color: locationManager.hasLocationPermission ?
                            AppConstants.Colors.limeGreen : Color(hex: "FF3B5C"), radius: 4)
                
                Text(gpsStatusText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(theme.isDarkMode ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.regularMaterial))
            )
        }
        .padding(.horizontal, AppConstants.Design.paddingL)
        .padding(.top, AppConstants.Design.paddingXL)
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
            // Outer glow ring
            Circle()
                .stroke(speedColor.opacity(0.3), lineWidth: 20)
                .blur(radius: 10)
                .frame(width: 280, height: 280)
                .scaleEffect(animateGlow && locationManager.isMoving ? 1.1 : 1.0)
                .animation(
                    locationManager.isMoving ?
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true) :
                    .easeInOut(duration: 2).repeatForever(autoreverses: true),
                    value: animateGlow
                )
            
            // Speed circle
            GlassMorphismCard(cornerRadius: 200, padding: 60) {
                VStack(spacing: 8) {
                    Text("\(Int(displaySpeed))")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(speedColor)
                        .shadow(color: speedColor.opacity(0.5), radius: 10)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: Int(displaySpeed))
                    
                    Text(speedUnit.rawValue)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                }
            }
            .frame(width: 280, height: 280)
            
            // Speed limit indicator
            if displaySpeed > maxSpeedLimit {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color(hex: "FF3B5C"))
                        Text("OVER LIMIT")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "FF3B5C"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(hex: "FF3B5C").opacity(0.2))
                    )
                }
                .frame(width: 280, height: 280)
                .offset(y: 20)
            }
        }
        .padding(.vertical, AppConstants.Design.paddingL)
    }
    
    // MARK: - Stats Grid
    var statsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: AppConstants.Design.paddingM
        ) {
            StatCard(
                title: "MAX SPEED",
                value: "\(Int(displayMaxSpeed))",
                unit: speedUnit.rawValue,
                icon: "arrow.up.circle.fill",
                color: theme.primaryColor,
                theme: theme
            )
            
            StatCard(
                title: "AVG SPEED",
                value: "\(Int(displayAvgSpeed))",
                unit: speedUnit.rawValue,
                icon: "chart.line.uptrend.xyaxis",
                color: theme.primaryColor,
                theme: theme
            )
            
            StatCard(
                title: "DISTANCE",
                value: displayDistance,
                unit: distanceUnit,
                icon: "location.fill",
                color: theme.primaryColor,
                theme: theme
            )
            
            StatCard(
                title: "DURATION",
                value: elapsedFormatted,
                unit: "",
                icon: "clock.fill",
                color: theme.primaryColor,
                theme: theme
            )
            
            StatCard(
                title: "ALTITUDE",
                value: altitudeFormatted,
                unit: "m",
                icon: "mountain.2.fill",
                color: theme.primaryColor,
                theme: theme
            )
            
            StatCard(
                title: "COORDINATES",
                value: coordinatesFormatted.0,
                unit: coordinatesFormatted.1,
                icon: "location.circle.fill",
                color: theme.primaryColor,
                theme: theme
            )
        }
        .padding(.horizontal, AppConstants.Design.paddingL)
    }
    
    // MARK: - Control Button
    var controlButton: some View {
        AnimatedButton(
            locationManager.isTracking ? "Stop Tracking" : "Start Tracking",
            icon: locationManager.isTracking ? "stop.fill" : "play.fill",
            variant: locationManager.isTracking ? .accent : .primary
        ) {
            if locationManager.isTracking {
                showStopConfirm = true
            } else {
                locationManager.startTracking()
            }
        }
        .padding(.horizontal, AppConstants.Design.paddingL)
    }
    
    // MARK: - Stop & Save
    private func stopAndSave() {
        if let trip = locationManager.stopTracking() {
            tripStore.saveTrip(trip)
            HapticManager.shared.notification(type: .success)
        }
        lastAlertSpeed = 0
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let theme: ThemeManager
    
    var body: some View {
        GlassMorphismCard(cornerRadius: AppConstants.Design.cornerRadiusM, padding: AppConstants.Design.paddingM) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                    
                    if title == "COORDINATES" {
                        // Special layout for coordinates
                        VStack(alignment: .leading, spacing: 2) {
                            Text(value)
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(theme.textPrimary)
                            Text(unit)
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(theme.textPrimary)
                        }
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(value)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(theme.textPrimary)
                                .contentTransition(.numericText())
                            
                            if !unit.isEmpty {
                                Text(unit)
                                    .font(.system(size: 12))
                                    .foregroundColor(theme.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SpeedTrackerView()
        .environmentObject(ThemeManager.shared)
}
