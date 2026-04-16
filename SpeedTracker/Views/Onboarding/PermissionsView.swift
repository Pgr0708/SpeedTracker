//
//  PermissionsView.swift
//  SpeedTracker
//
import SwiftUI
import CoreLocation
import CoreMotion
import HealthKit

struct PermissionsView: View {
    @EnvironmentObject var theme: ThemeManager
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @Binding var hasGrantedPermissions: Bool
    @State private var appeared = false
    @State private var locationRequested = false
    @State private var motionRequested = false
    @State private var healthRequested = false
    @State private var motionAuthorized = false
    @State private var healthAuthorized = false

    private let motionManager = CMMotionActivityManager()
    private let healthStore = HKHealthStore()

    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                ZStack {
                    Circle().fill(RadialGradient(colors: [theme.primaryColor.opacity(0.25), .clear], center: .center, startRadius: 30, endRadius: 100)).frame(width: 180, height: 180)
                    Image(systemName: "location.fill.viewfinder").font(.system(size: 64, weight: .light)).foregroundStyle(theme.primaryGradient)
                }.scaleEffect(appeared ? 1 : 0.5).opacity(appeared ? 1 : 0)

                VStack(spacing: 10) {
                    Text("Permissions Required").font(.system(size: 26, weight: .bold, design: .rounded)).foregroundColor(theme.textPrimary)
                    Text("SpeedTracker needs access to track speed and activity").font(.system(size: 15)).foregroundColor(theme.textSecondary).multilineTextAlignment(.center).padding(.horizontal, 40)
                }.padding(.top, 20).opacity(appeared ? 1 : 0)

                Spacer()

                VStack(spacing: 14) {
                    PermissionCard(icon: "location.fill", title: "Location Access", description: "Required for GPS speed tracking", status: locationStatus, statusColor: locationStatusColor, theme: theme) {
                        locationManager.requestPermission(); locationRequested = true
                    }
                    PermissionCard(icon: "figure.walk.motion", title: "Motion & Fitness", description: "Required for pedometer tracking", status: motionStatus, statusColor: motionStatusColor, theme: theme) {
                        requestMotion()
                    }
                    PermissionCard(icon: "heart.fill", title: "Health (Optional)", description: "For calorie & fitness data sync", status: healthStatus, statusColor: healthStatusColor, theme: theme) {
                        requestHealth()
                    }
                    PermissionCard(icon: "bell.badge.fill", title: "Notifications", description: "Speed alerts & trip summaries", status: notificationStatus, statusColor: notificationStatusColor, theme: theme) {
                        Task { await notificationManager.requestPermission() }
                    }
                }
                .padding(.horizontal, 22).opacity(appeared ? 1 : 0)

                Spacer()

                VStack(spacing: 10) {
                    AnimatedButton(locationManager.hasLocationPermission ? "Continue" : "Grant Location Access", icon: locationManager.hasLocationPermission ? "arrow.right" : "location.fill", variant: .primary) {
                        if locationManager.hasLocationPermission {
                            withAnimation { hasGrantedPermissions = true }
                        } else {
                            locationManager.requestPermission(); locationRequested = true
                        }
                    }
                    if locationRequested && !locationManager.hasLocationPermission {
                        Button("Open Settings") { UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) }
                            .font(.system(size: 14, weight: .medium)).foregroundColor(theme.primaryColor)
                    }
                }
                .padding(.horizontal, 24).padding(.bottom, 50)
            }
        }
        .onAppear { withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) { appeared = true } }
    }

    private func requestMotion() {
        let status = CMMotionActivityManager.authorizationStatus()
        switch status {
        case .denied, .restricted:
            // Already denied — open Settings so user can enable
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        case .notDetermined:
            // Trigger the system prompt
            motionManager.startActivityUpdates(to: .main) { _ in }
            motionRequested = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let newStatus = CMMotionActivityManager.authorizationStatus()
                motionAuthorized = (newStatus == .authorized)
                motionRequested = true
            }
        case .authorized:
            motionAuthorized = true; motionRequested = true
        @unknown default:
            motionManager.startActivityUpdates(to: .main) { _ in }
            motionRequested = true
        }
    }

    private func requestHealth() {
        guard HKHealthStore.isHealthDataAvailable() else {
            // HealthKit not available on this device (e.g. iPod Touch)
            healthRequested = true; return
        }
        let types: Set<HKSampleType> = [HKQuantityType(.stepCount), HKQuantityType(.activeEnergyBurned)]
        healthStore.requestAuthorization(toShare: nil, read: types) { granted, error in
            DispatchQueue.main.async {
                if let error {
                    // Likely missing entitlement — open Settings
                    print("HealthKit error: \(error.localizedDescription)")
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }
                healthAuthorized = granted; healthRequested = true
            }
        }
    }

    var locationStatus: String {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: return "Granted"
        case .denied, .restricted: return "Denied"
        default: return "Required"
        }
    }
    var locationStatusColor: Color {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: return AppConstants.Colors.limeGreen
        case .denied, .restricted: return Color(hex:"FF3B5C")
        default: return AppConstants.Colors.neonOrange
        }
    }
    var motionStatus: String { motionAuthorized ? "Granted" : (motionRequested ? "Denied" : "Tap to Grant") }
    var motionStatusColor: Color { motionAuthorized ? AppConstants.Colors.limeGreen : (motionRequested ? Color(hex:"FF3B5C") : AppConstants.Colors.neonOrange) }
    var healthStatus: String { healthAuthorized ? "Granted" : (healthRequested ? "Denied" : "Optional") }
    var healthStatusColor: Color { healthAuthorized ? AppConstants.Colors.limeGreen : theme.textSecondary }
    var notificationStatus: String { notificationManager.isAuthorized ? "Granted" : "Optional" }
    var notificationStatusColor: Color { notificationManager.isAuthorized ? AppConstants.Colors.limeGreen : theme.textSecondary }
}

#Preview { PermissionsView(hasGrantedPermissions: .constant(false)).environmentObject(ThemeManager.shared) }

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let status: String
    let statusColor: Color
    let theme: ThemeManager
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(theme.primaryColor)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(theme.textPrimary)
                    Text(description).font(.system(size: 12)).foregroundColor(theme.textSecondary)
                }
                Spacer()
                Text(status)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(statusColor.opacity(0.15)))
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(theme.isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.04)))
        }
        .buttonStyle(.plain)
    }
}
