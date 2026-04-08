//
//  SpeedTrackerView.swift
//  SpeedTracker
//
//  Main speed tracking screen with liquid glass UI
//

import SwiftUI

struct SpeedTrackerView: View {
    @State private var currentSpeed: Double = 0
    @State private var maxSpeed: Double = 0
    @State private var avgSpeed: Double = 0
    @State private var isTracking = false
    @State private var animateGlow = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppConstants.Design.paddingL) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SPEEDTRACKER")
                            .font(.headingSmall)
                            .foregroundColor(AppConstants.Colors.electricBlue)
                        
                        Text("Ready to track")
                            .font(.caption)
                            .foregroundColor(AppConstants.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // GPS Status
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppConstants.Colors.limeGreen)
                            .frame(width: 8, height: 8)
                            .shadow(color: AppConstants.Colors.limeGreen, radius: 4)
                        
                        Text("GPS")
                            .font(.caption)
                            .foregroundColor(AppConstants.Colors.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                }
                .padding(.horizontal, AppConstants.Design.paddingL)
                .padding(.top, AppConstants.Design.paddingXL)
                
                // Main Speed Display
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(
                            AppConstants.Colors.electricBlue.opacity(0.3),
                            lineWidth: 20
                        )
                        .blur(radius: 10)
                        .scaleEffect(animateGlow ? 1.1 : 1.0)
                        .animation(
                            .easeInOut(duration: 2)
                            .repeatForever(autoreverses: true),
                            value: animateGlow
                        )
                    
                    // Speed circle
                    GlassMorphismCard(cornerRadius: 200, padding: 60) {
                        VStack(spacing: 8) {
                            Text("\(Int(currentSpeed))")
                                .font(.custom(AppConstants.Typography.orbitronBold, size: 80))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            AppConstants.Colors.electricBlue,
                                            AppConstants.Colors.limeGreen
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: AppConstants.Colors.electricBlue, radius: 20)
                            
                            Text("km/h")
                                .font(.headingMedium)
                                .foregroundColor(AppConstants.Colors.textSecondary)
                        }
                    }
                    .frame(width: 280, height: 280)
                }
                .padding(.vertical, AppConstants.Design.paddingL)
                .onAppear {
                    animateGlow = true
                }
                
                // Stats Grid
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: AppConstants.Design.paddingM
                ) {
                    StatCard(
                        title: "MAX SPEED",
                        value: "\(Int(maxSpeed))",
                        unit: "km/h",
                        icon: "arrow.up.circle.fill",
                        color: AppConstants.Colors.neonOrange
                    )
                    
                    StatCard(
                        title: "AVG SPEED",
                        value: "\(Int(avgSpeed))",
                        unit: "km/h",
                        icon: "chart.line.uptrend.xyaxis",
                        color: AppConstants.Colors.limeGreen
                    )
                    
                    StatCard(
                        title: "DISTANCE",
                        value: "0.0",
                        unit: "km",
                        icon: "location.fill",
                        color: AppConstants.Colors.electricBlue
                    )
                    
                    StatCard(
                        title: "DURATION",
                        value: "00:00",
                        unit: "min",
                        icon: "clock.fill",
                        color: Color(hex: "9D4EDD")
                    )
                }
                .padding(.horizontal, AppConstants.Design.paddingL)
                
                // Control Button
                AnimatedButton(
                    isTracking ? "Stop Tracking" : "Start Tracking",
                    icon: isTracking ? "stop.fill" : "play.fill",
                    variant: isTracking ? .accent : .primary
                ) {
                    isTracking.toggle()
                    if isTracking {
                        startMockTracking()
                    } else {
                        stopTracking()
                    }
                }
                .padding(.horizontal, AppConstants.Design.paddingL)
                .padding(.bottom, 100) // Space for tab bar
            }
        }
        .sportGradientBackground()
    }
    
    private func startMockTracking() {
        // Mock speed animation for demo
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !isTracking {
                timer.invalidate()
                return
            }
            
            currentSpeed = Double.random(in: 0...120)
            if currentSpeed > maxSpeed {
                maxSpeed = currentSpeed
            }
            avgSpeed = (avgSpeed + currentSpeed) / 2
        }
    }
    
    private func stopTracking() {
        currentSpeed = 0
        maxSpeed = 0
        avgSpeed = 0
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
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
                        .font(.caption)
                        .foregroundColor(AppConstants.Colors.textSecondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(value)
                            .font(.headingMedium)
                            .foregroundColor(AppConstants.Colors.textPrimary)
                        
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(AppConstants.Colors.textSecondary)
                    }
                }
            }
        }
    }
}

#Preview {
    SpeedTrackerView()
}
