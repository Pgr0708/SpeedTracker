//
//  PermissionsView.swift
//  SpeedTracker
//
import SwiftUI
import CoreLocation
import CoreMotion
import HealthKit
import UserNotifications

struct PermissionsView: View {
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @Binding var hasGrantedPermissions: Bool
    @State private var appeared = false
    @State private var locationRequested = false
    @State private var motionStatusValue: CMAuthorizationStatus = CMMotionActivityManager.authorizationStatus()
    @State private var healthAuthorizationStatus: HKAuthorizationStatus = .notDetermined
    @State private var healthGrantedFallback = false

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
                    Text(L10n.text("permissions.title")).font(.headingMedium).foregroundColor(theme.textPrimary)
                    Text(L10n.text("permissions.desc")).font(.bodySmall).foregroundColor(theme.textSecondary).multilineTextAlignment(.center).padding(.horizontal, 40)
                }.padding(.top, 20).opacity(appeared ? 1 : 0)

                Spacer()

                VStack(spacing: 14) {
                    PermissionCard(icon: "location.fill", title: L10n.string("permissions.location"), description: L10n.string("permissions.locationDesc"), status: locationStatus, statusColor: locationStatusColor, theme: theme) {
                        requestLocation()
                    }
                    PermissionCard(icon: "figure.walk.motion", title: L10n.string("permissions.motion"), description: L10n.string("permissions.motionDesc"), status: motionStatus, statusColor: motionStatusColor, theme: theme) {
                        requestMotion()
                    }
                    PermissionCard(icon: "heart.fill", title: L10n.string("permissions.health"), description: L10n.string("permissions.healthDesc"), status: healthStatus, statusColor: healthStatusColor, theme: theme) {
                        requestHealth()
                    }
                    PermissionCard(icon: "bell.badge.fill", title: L10n.string("permissions.notifications"), description: L10n.string("permissions.notificationsDesc"), status: notificationStatus, statusColor: notificationStatusColor, theme: theme) {
                        requestNotifications()
                    }
                }
                .padding(.horizontal, 22).opacity(appeared ? 1 : 0)

                Spacer()

                VStack(spacing: 10) {
                    AnimatedButton(locationManager.hasLocationPermission ? L10n.string("common.continue") : L10n.string("permissions.grantLocation"), icon: locationManager.hasLocationPermission ? "arrow.right" : "location.fill", variant: .primary) {
                        if locationManager.hasLocationPermission {
                            withAnimation { hasGrantedPermissions = true }
                        } else {
                            locationManager.requestPermission(); locationRequested = true
                        }
                    }
                    if locationRequested && !locationManager.hasLocationPermission {
                        Button(L10n.string("permissions.openSettings")) { UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) }
                            .font(.bodySmall).foregroundColor(theme.primaryColor)
                    }
                }
                .padding(.horizontal, 24).padding(.bottom, 50)
            }
        }
        .onAppear {
            refreshPermissionStates()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) { appeared = true }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshPermissionStates()
            }
        }
    }

    private func openSettings() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }

    private func requestLocation() {
        switch locationManager.authorizationStatus {
        case .denied, .restricted:
            openSettings()
        default:
            locationManager.requestPermission()
            locationRequested = true
        }
    }

    private func requestNotifications() {
        if notificationManager.isAuthorized {
            return
        }
        // If already denied, open Settings since iOS won't show the popup again
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .denied {
                    openSettings()
                } else {
                    Task { await notificationManager.requestPermission() }
                }
            }
        }
    }

    private func requestMotion() {
        switch motionStatusValue {
        case .denied, .restricted:
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        case .notDetermined:
            motionManager.startActivityUpdates(to: .main) { _ in }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                refreshPermissionStates()
            }
        case .authorized:
            refreshPermissionStates()
        @unknown default:
            motionManager.startActivityUpdates(to: .main) { _ in }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                refreshPermissionStates()
            }
        }
    }

    private func requestHealth() {
        guard HKHealthStore.isHealthDataAvailable() else {
            refreshPermissionStates()
            return
        }
        let types: Set<HKSampleType> = [HKQuantityType(.stepCount), HKQuantityType(.activeEnergyBurned)]
        healthStore.requestAuthorization(toShare: nil, read: types) { granted, error in
            DispatchQueue.main.async {
                if let error {
                    print("HealthKit error: \(error.localizedDescription)")
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }
                healthGrantedFallback = granted
                refreshPermissionStates()
            }
        }
    }

    private func refreshPermissionStates() {
        motionStatusValue = CMMotionActivityManager.authorizationStatus()
        if let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) {
            healthAuthorizationStatus = healthStore.authorizationStatus(for: stepType)
        } else {
            healthAuthorizationStatus = .notDetermined
        }
    }

    var locationStatus: String {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: return L10n.string("permissions.granted")
        case .denied, .restricted: return L10n.string("permissions.denied")
        default: return L10n.string("permissions.required")
        }
    }
    var locationStatusColor: Color {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: return AppConstants.Colors.limeGreen
        case .denied, .restricted: return Color(hex:"FF3B5C")
        default: return AppConstants.Colors.neonOrange
        }
    }
    var motionStatus: String {
        switch motionStatusValue {
        case .authorized: return L10n.string("permissions.granted")
        case .denied, .restricted: return L10n.string("permissions.denied")
        case .notDetermined: return L10n.string("permissions.tapToGrant")
        @unknown default: return L10n.string("permissions.tapToGrant")
        }
    }
    var motionStatusColor: Color {
        switch motionStatusValue {
        case .authorized: return AppConstants.Colors.limeGreen
        case .denied, .restricted: return Color(hex:"FF3B5C")
        case .notDetermined: return AppConstants.Colors.neonOrange
        @unknown default: return AppConstants.Colors.neonOrange
        }
    }
    var healthStatus: String {
        guard HKHealthStore.isHealthDataAvailable() else { return L10n.string("permissions.optional") }
        if healthGrantedFallback { return L10n.string("permissions.granted") }
        switch healthAuthorizationStatus {
        case .sharingAuthorized: return L10n.string("permissions.granted")
        case .sharingDenied: return L10n.string("permissions.denied")
        case .notDetermined: return L10n.string("permissions.optional")
        @unknown default: return L10n.string("permissions.optional")
        }
    }
    var healthStatusColor: Color {
        guard HKHealthStore.isHealthDataAvailable() else { return theme.textSecondary }
        if healthGrantedFallback { return AppConstants.Colors.limeGreen }
        switch healthAuthorizationStatus {
        case .sharingAuthorized: return AppConstants.Colors.limeGreen
        case .sharingDenied: return Color(hex:"FF3B5C")
        case .notDetermined: return theme.textSecondary
        @unknown default: return theme.textSecondary
        }
    }
    var notificationStatus: String { notificationManager.isAuthorized ? L10n.string("permissions.granted") : L10n.string("permissions.optional") }
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
                    Text(title).font(.bodyMedium).foregroundColor(theme.textPrimary)
                    Text(description).font(.caption).foregroundColor(theme.textSecondary)
                }
                Spacer()
                Text(status)
                    .font(.caption)
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
