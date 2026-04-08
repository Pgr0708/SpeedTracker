//
//  PermissionsView.swift
//  SpeedTracker
//
//  Permissions screen - location + notifications (step 5)
//

import SwiftUI
import CoreLocation

struct PermissionsView: View {
    @EnvironmentObject var theme: ThemeManager
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @Binding var hasGrantedPermissions: Bool
    @State private var appeared = false
    @State private var locationRequested = false
    @State private var notificationRequested = false
    
    var body: some View {
        ZStack {
            theme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [theme.primaryColor.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 30,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                    
                    Image(systemName: "location.fill.viewfinder")
                        .font(.system(size: 70, weight: .light))
                        .foregroundStyle(theme.primaryGradient)
                }
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)
                
                VStack(spacing: 12) {
                    Text("Permissions Required")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                    
                    Text("SpeedTracker needs these permissions to track your speed accurately")
                        .font(.system(size: 15))
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                
                Spacer()
                
                // Permission Cards
                VStack(spacing: 16) {
                    PermissionCard(
                        icon: "location.fill",
                        title: "Location Access",
                        description: "Required for GPS speed tracking",
                        status: locationStatus,
                        statusColor: locationStatusColor,
                        theme: theme
                    ) {
                        locationManager.requestPermission()
                        locationRequested = true
                    }
                    
                    PermissionCard(
                        icon: "bell.badge.fill",
                        title: "Notifications",
                        description: "Speed limit alerts & trip summaries",
                        status: notificationStatus,
                        statusColor: notificationStatusColor,
                        theme: theme
                    ) {
                        Task {
                            await notificationManager.requestPermission()
                            notificationRequested = true
                        }
                    }
                }
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)
                
                Spacer()
                
                // Continue
                VStack(spacing: 12) {
                    AnimatedButton(
                        locationManager.hasLocationPermission ? "Start Tracking" : "Grant Permissions",
                        icon: locationManager.hasLocationPermission ? "arrow.right" : "hand.raised.fill",
                        variant: .primary
                    ) {
                        if locationManager.hasLocationPermission {
                            withAnimation { hasGrantedPermissions = true }
                        } else {
                            locationManager.requestPermission()
                            locationRequested = true
                        }
                    }
                    
                    if locationRequested && !locationManager.hasLocationPermission {
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.primaryColor)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
        }
        .onChange(of: locationManager.authorizationStatus) { _, status in
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                // Auto-proceed if notification was also handled (or just proceed)
                if notificationRequested || true {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation { hasGrantedPermissions = true }
                    }
                }
            }
        }
    }
    
    // MARK: - Status Helpers
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
        case .denied, .restricted: return Color(hex: "FF3B5C")
        default: return AppConstants.Colors.neonOrange
        }
    }
    
    var notificationStatus: String {
        if notificationManager.isAuthorized { return "Granted" }
        if notificationRequested { return "Denied" }
        return "Optional"
    }
    
    var notificationStatusColor: Color {
        if notificationManager.isAuthorized { return AppConstants.Colors.limeGreen }
        if notificationRequested { return Color(hex: "FF3B5C") }
        return theme.textSecondary
    }
}

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
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(theme.primaryColor)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(theme.primaryColor.opacity(0.15))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                    
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                // Status badge
                Text(status)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.15))
                    )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(theme.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.08), lineWidth: 1)
            )
        }
    }
}

#Preview {
    PermissionsView(hasGrantedPermissions: .constant(false))
        .environmentObject(ThemeManager.shared)
}
