//
//  HUDModeView.swift
//  SpeedTracker
//
import SwiftUI

struct HUDModeView: View {
    @EnvironmentObject var theme: ThemeManager
    @StateObject private var locationManager = LocationManager.shared

    @AppStorage(AppConstants.UserDefaultsKeys.preferredSpeedUnit) private var speedUnitRaw = AppConstants.SpeedUnit.kmh.rawValue
    @AppStorage(AppConstants.UserDefaultsKeys.maxSpeedLimit) private var maxSpeedLimit: Double = 120
    @AppStorage(AppConstants.UserDefaultsKeys.isMirrorModeEnabled) private var isMirrorMode = true
    @Environment(\.dismiss) private var dismiss

    var speedUnit: AppConstants.SpeedUnit { AppConstants.SpeedUnit(rawValue: speedUnitRaw) ?? .kmh }
    var displaySpeed: Double { locationManager.convertedSpeed(locationManager.currentSpeed, unit: speedUnit) }
    var speedColor: Color {
        if displaySpeed > maxSpeedLimit { return Color(hex:"FF3B5C") }
        if displaySpeed > maxSpeedLimit * 0.8 { return AppConstants.Colors.neonOrange }
        return theme.primaryColor
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                // Top bar (not mirrored)
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 30)).foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                    // Mirror toggle
                    Button {
                        isMirrorMode.toggle()
                        HapticManager.shared.selection()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left.arrow.right").font(.system(size: 14))
                            Text(isMirrorMode ? "Mirror ON" : "Mirror OFF").font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(.white.opacity(0.1)))
                    }
                }
                .padding(.horizontal, 28).padding(.top, 50)

                Spacer()

                // HUD Content (mirrored for windshield)
                VStack(spacing: 32) {
                    VStack(spacing: 10) {
                        Text("\(Int(displaySpeed))")
                            .font(Font.custom(AppConstants.Typography.orbitronBold, size: 110))
                            .foregroundColor(speedColor)
                            .shadow(color: speedColor.opacity(0.7), radius: 24)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3), value: Int(displaySpeed))
                        Text(speedUnit.rawValue)
                            .font(Font.custom(AppConstants.Typography.rajdhaniMedium, size: 30))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .scaleEffect(x: isMirrorMode ? -1 : 1, y: 1)

                    HStack(spacing: 40) {
                        VStack(spacing: 4) {
                            Text("HEADING").font(.system(size: 11, weight: .bold)).foregroundColor(.white.opacity(0.4))
                            Text(String(format: "%.0f°", locationManager.heading)).font(Font.custom(AppConstants.Typography.orbitronBold, size: 18)).foregroundColor(.white.opacity(0.7))
                        }
                        HStack(spacing: 8) {
                            Circle().fill(locationManager.isTracking ? AppConstants.Colors.limeGreen : Color(hex:"FF3B5C")).frame(width: 10, height: 10)
                            Text(locationManager.isTracking ? "LIVE" : "PAUSED").font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundColor(.white.opacity(0.5))
                        }
                        VStack(spacing: 4) {
                            Text("ALT").font(.system(size: 11, weight: .bold)).foregroundColor(.white.opacity(0.4))
                            Text(String(format: "%.0fm", locationManager.altitude)).font(Font.custom(AppConstants.Typography.orbitronBold, size: 18)).foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .scaleEffect(x: isMirrorMode ? -1 : 1, y: 1)

                    if displaySpeed > maxSpeedLimit {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 22))
                            Text("OVER LIMIT").font(.system(size: 17, weight: .bold))
                        }
                        .foregroundColor(Color(hex:"FF3B5C"))
                        .padding(.horizontal, 22).padding(.vertical, 10)
                        .background(Capsule().fill(Color(hex:"FF3B5C").opacity(0.2)))
                        .scaleEffect(x: isMirrorMode ? -1 : 1, y: 1)
                    }
                }

                Spacer()

                Text(isMirrorMode ? "Place below windshield — speed reflects upward" : "Direct view mode")
                    .font(.system(size: 13)).foregroundColor(.white.opacity(0.35)).padding(.bottom, 30)
            }
        }
        .statusBar(hidden: true)
        .persistentSystemOverlays(.hidden)
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
}

#Preview { HUDModeView().environmentObject(ThemeManager.shared) }
