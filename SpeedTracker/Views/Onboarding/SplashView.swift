//
//  SplashView.swift
//  SpeedTracker
//
import SwiftUI

struct SplashView: View {
    @EnvironmentObject var theme: ThemeManager
    var onComplete: () -> Void

    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var ring1Scale: CGFloat = 0.4
    @State private var ring2Scale: CGFloat = 0.4
    @State private var ring3Scale: CGFloat = 0.4
    @State private var ringOpacity: Double = 0
    @State private var needleAngle: Double = -120
    @State private var needleOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var subtitleOpacity: Double = 0
    @State private var glowRadius: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var particleOpacity: Double = 0

    private let particles: [(CGFloat, CGFloat, Double)] = (0..<8).map { i in
        let angle = Double(i) * 45.0
        let r = CGFloat.random(in: 70...110)
        return (r * CGFloat(cos(angle * .pi / 180)), r * CGFloat(sin(angle * .pi / 180)), angle)
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: theme.isDarkMode
                    ? [Color(hex: "050A1A"), Color(hex: "0A1830"), Color(hex: "061020")]
                    : [Color(hex: "F0F4FF"), Color(hex: "FFFFFF")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Ambient glow behind logo
            Circle()
                .fill(RadialGradient(
                    colors: [theme.primaryColor.opacity(0.25), theme.primaryColor.opacity(0.05), .clear],
                    center: .center, startRadius: 10, endRadius: 160
                ))
                .frame(width: 320, height: 320)
                .blur(radius: glowRadius)
                .scaleEffect(pulseScale)
                .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulseScale)

            // Particle dots
            ForEach(Array(particles.enumerated()), id: \.offset) { i, p in
                Circle()
                    .fill(theme.primaryColor.opacity(0.6))
                    .frame(width: CGFloat([4,3,5,3,4,3,5,4][i % 8]), height: CGFloat([4,3,5,3,4,3,5,4][i % 8]))
                    .offset(x: p.0, y: p.1)
                    .opacity(particleOpacity)
            }

            VStack(spacing: 0) {
                // Logo area
                ZStack {
                    // Outer rings
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(
                                theme.primaryColor.opacity(0.12 - Double(i) * 0.03),
                                lineWidth: CGFloat(28 - i * 8)
                            )
                            .frame(width: CGFloat(180 + i * 52), height: CGFloat(180 + i * 52))
                            .scaleEffect([ring1Scale, ring2Scale, ring3Scale][i])
                            .opacity(ringOpacity)
                    }

                    // Gauge arc background
                    Circle()
                        .trim(from: 0.15, to: 0.85)
                        .stroke(theme.primaryColor.opacity(0.12), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(90))

                    // Gauge arc fill (sweeps in)
                    Circle()
                        .trim(from: 0.15, to: max(0.15, 0.15 + (needleAngle + 120) / 240 * 0.7))
                        .stroke(
                            AngularGradient(
                                colors: [theme.primaryColor.opacity(0.4), theme.primaryColor],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(90))
                        .animation(.easeInOut(duration: 1.2).delay(0.6), value: needleAngle)

                    // Speedometer icon
                    Image(systemName: "speedometer")
                        .font(.system(size: 64, weight: .thin))
                        .foregroundStyle(theme.primaryGradient)
                        .shadow(color: theme.primaryColor.opacity(0.7), radius: 18)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                    // Needle
                    SpeedometerNeedle(color: theme.primaryColor)
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(needleAngle))
                        .opacity(needleOpacity)
                }
                .frame(width: 260, height: 260)

                // Title
                VStack(spacing: 6) {
                    Text("SPEEDTRACKER")
                        .font(Font.custom(AppConstants.Typography.orbitronBold, size: 30))
                        .foregroundColor(theme.textPrimary)
                        .shadow(color: theme.primaryColor.opacity(0.5), radius: 12)
                        .opacity(titleOpacity)
                        .offset(y: titleOffset)

                    HStack(spacing: 6) {
                        Rectangle()
                            .fill(theme.primaryColor.opacity(0.5))
                            .frame(width: 30, height: 1)
                        Text("v\(AppConstants.App.version)")
                            .font(.label)
                            .foregroundColor(theme.textTertiary)
                        Rectangle()
                            .fill(theme.primaryColor.opacity(0.5))
                            .frame(width: 30, height: 1)
                    }
                    .opacity(subtitleOpacity)
                }
                .padding(.top, 20)
            }
        }
        .onAppear { runAnimation() }
    }

    private func runAnimation() {
        // Rings burst in
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
            ring1Scale = 1.0; ringOpacity = 1
        }
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.08)) { ring2Scale = 1.0 }
        withAnimation(.spring(response: 0.9, dampingFraction: 0.6).delay(0.16)) { ring3Scale = 1.0 }

        // Logo pop
        withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.3)) {
            logoScale = 1.0; logoOpacity = 1; glowRadius = 30
        }

        // Needle sweep
        withAnimation(.easeIn(duration: 0.3).delay(0.5)) { needleOpacity = 1 }
        withAnimation(.easeInOut(duration: 1.2).delay(0.6)) { needleAngle = 60 }

        // Particles
        withAnimation(.easeOut(duration: 0.5).delay(0.7)) { particleOpacity = 1 }

        // Title
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.9)) {
            titleOpacity = 1; titleOffset = 0
        }
        withAnimation(.easeOut(duration: 0.5).delay(1.1)) { subtitleOpacity = 1 }

        // Pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { pulseScale = 1.06 }

        // Dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeIn(duration: 0.35)) { onComplete() }
        }
    }
}

struct SpeedometerNeedle: View {
    let color: Color
    var body: some View {
        ZStack {
            // Needle line
            Rectangle()
                .fill(LinearGradient(colors: [color, color.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                .frame(width: 2.5, height: 36)
                .offset(y: -18)
            // Center dot
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .shadow(color: color.opacity(0.8), radius: 4)
        }
    }
}

#Preview {
    SplashView { }
        .environmentObject(ThemeManager.shared)
}
