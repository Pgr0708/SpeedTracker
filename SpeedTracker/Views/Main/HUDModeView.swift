//
//  HUDModeView.swift
//  SpeedTracker
//
//  HUD (Heads-Up Display) mode for windshield projection
//  Displays mirrored speed for reflection on windshield
//

import SwiftUI

struct HUDModeView: View {
    @EnvironmentObject var theme: ThemeManager
    @StateObject private var locationManager = LocationManager.shared
    
    @AppStorage(AppConstants.UserDefaultsKeys.preferredSpeedUnit) private var speedUnitRaw: String = AppConstants.SpeedUnit.kmh.rawValue
    @AppStorage(AppConstants.UserDefaultsKeys.maxSpeedLimit) private var maxSpeedLimit: Double = 120
    @AppStorage(AppConstants.UserDefaultsKeys.isHUDModeEnabled) private var isHUDMode = false
    
    @State private var animateGlow = false
    @Environment(\.dismiss) private var dismiss
    
    var speedUnit: AppConstants.SpeedUnit {
        AppConstants.SpeedUnit(rawValue: speedUnitRaw) ?? .kmh
    }
    
    var displaySpeed: Double {
        locationManager.convertedSpeed(locationManager.currentSpeed, unit: speedUnit)
    }
    
    var speedColor: Color {
        if displaySpeed > maxSpeedLimit {
            return Color(hex: "FF3B5C")
        } else if displaySpeed > maxSpeedLimit * 0.8 {
            return AppConstants.Colors.neonOrange
        }
        return theme.primaryColor
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Close button (not mirrored)
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                }
                .padding(.horizontal, 30)
                .padding(.top, 50)
                
                Spacer()
                
                // Mirrored HUD content
                VStack(spacing: 40) {
                    // Speed display (mirrored)
                    VStack(spacing: 12) {
                        Text("\(Int(displaySpeed))")
                            .font(.system(size: 120, weight: .bold, design: .rounded))
                            .foregroundColor(speedColor)
                            .shadow(color: speedColor.opacity(0.6), radius: 20)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3), value: Int(displaySpeed))
                        
                        Text(speedUnit.rawValue)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .scaleEffect(x: -1, y: 1) // Mirror horizontally
                    
                    // GPS indicator (mirrored)
                    HStack(spacing: 12) {
                        Circle()
                            .fill(locationManager.hasLocationPermission && locationManager.isTracking ?
                                  AppConstants.Colors.limeGreen : Color(hex: "FF3B5C"))
                            .frame(width: 12, height: 12)
                            .shadow(color: locationManager.hasLocationPermission && locationManager.isTracking ?
                                    AppConstants.Colors.limeGreen : Color(hex: "FF3B5C"), radius: 6)
                        
                        Text(locationManager.isTracking ? "TRACKING" : "NOT TRACKING")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .scaleEffect(x: -1, y: 1) // Mirror horizontally
                    
                    // Speed limit warning (if over limit, mirrored)
                    if displaySpeed > maxSpeedLimit {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 24))
                            Text("OVER LIMIT")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(Color(hex: "FF3B5C"))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color(hex: "FF3B5C").opacity(0.2))
                        )
                        .scaleEffect(x: -1, y: 1) // Mirror horizontally
                    }
                }
                
                Spacer()
                
                // Instructions (not mirrored)
                VStack(spacing: 8) {
                    Text("Place phone below windshield")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    Text("Speed reflects onto windshield")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.bottom, 30)
            }
        }
        .statusBar(hidden: true)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            animateGlow = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

#Preview {
    HUDModeView()
        .environmentObject(ThemeManager.shared)
}
