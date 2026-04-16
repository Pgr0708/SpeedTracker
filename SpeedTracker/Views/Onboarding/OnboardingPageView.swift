//
//  OnboardingPageView.swift
//  SpeedTracker
//
import SwiftUI

struct OnboardingPageView: View {
    @EnvironmentObject var theme: ThemeManager
    let page: OnboardingPage

    @State private var iconScale: CGFloat = 0.4
    @State private var iconOpacity: Double = 0
    @State private var ring1Scale: CGFloat = 0.5
    @State private var ring2Scale: CGFloat = 0.5
    @State private var ring1Opacity: Double = 0
    @State private var orbitAngle: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 28
    @State private var descOpacity: Double = 0
    @State private var descOffset: CGFloat = 20
    @State private var bullet1Opacity: Double = 0
    @State private var bullet2Opacity: Double = 0
    @State private var bullet3Opacity: Double = 0
    @State private var glowPulse: CGFloat = 1.0

    var accentColor: Color { Color(hex: page.accentColor) }

    var bullets: [(String, String)] {
        switch page.iconName {
        case "speedometer":
            return [("gauge.with.needle", "Real-time GPS precision"),
                    ("arrow.up.right", "km/h · mph · m/s · knots"),
                    ("waveform.path.ecg", "Live speed graph")]
        case "map.fill":
            return [("mappin.and.ellipse", "Full route on map"),
                    ("chart.line.uptrend.xyaxis", "Speed & altitude data"),
                    ("clock.fill", "Duration & distance")]
        default:
            return [("trophy.fill", "Personal records"),
                    ("figure.run", "Pedometer & calories"),
                    ("paintbrush.fill", "Custom themes")]
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // ── Icon area ──────────────────────────────
            ZStack {
                // Outer glow
                Circle()
                    .fill(RadialGradient(
                        colors: [accentColor.opacity(0.28), accentColor.opacity(0.05), .clear],
                        center: .center, startRadius: 30, endRadius: 160
                    ))
                    .frame(width: 320, height: 320)
                    .scaleEffect(glowPulse)
                    .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: glowPulse)

                // Outer ring
                Circle()
                    .stroke(accentColor.opacity(0.15), lineWidth: 1.5)
                    .frame(width: 220, height: 220)
                    .scaleEffect(ring2Scale)
                    .opacity(ring1Opacity)

                // Inner ring
                Circle()
                    .stroke(
                        AngularGradient(colors: [accentColor.opacity(0.6), accentColor.opacity(0.05), accentColor.opacity(0.6)], center: .center),
                        lineWidth: 2
                    )
                    .frame(width: 168, height: 168)
                    .scaleEffect(ring1Scale)
                    .opacity(ring1Opacity)
                    .rotationEffect(.degrees(orbitAngle))

                // Orbiting dot
                Circle()
                    .fill(accentColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: accentColor.opacity(0.8), radius: 4)
                    .offset(y: -84)
                    .rotationEffect(.degrees(orbitAngle))
                    .opacity(ring1Opacity)

                // Glass card behind icon
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 140, height: 140)
                    .overlay(
                        Circle().strokeBorder(
                            LinearGradient(colors: [Color.white.opacity(0.35), accentColor.opacity(0.2)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.5
                        )
                    )
                    .shadow(color: accentColor.opacity(0.25), radius: 20)

                // Main icon
                Image(systemName: page.iconName)
                    .font(.system(size: 62, weight: .semibold))
                    .foregroundStyle(LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.65)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .shadow(color: accentColor.opacity(0.6), radius: 14)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
            }
            .frame(height: 260)

            Spacer().frame(height: 32)

            // ── Text ──────────────────────────────────
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)

                Text(page.description)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 32)
                    .opacity(descOpacity)
                    .offset(y: descOffset)
            }

            Spacer().frame(height: 28)

            // ── Feature bullets ───────────────────────
            VStack(spacing: 10) {
                ForEach(Array(bullets.enumerated()), id: \.offset) { i, b in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(accentColor.opacity(0.15)).frame(width: 32, height: 32)
                            Image(systemName: b.0)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(accentColor)
                        }
                        Text(b.1)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 36)
                    .opacity([bullet1Opacity, bullet2Opacity, bullet3Opacity][i])
                    .offset(x: [bullet1Opacity, bullet2Opacity, bullet3Opacity][i] == 0 ? -16 : 0)
                }
            }

            Spacer()
        }
        .onAppear { runEntrance() }
        .onDisappear { resetAll() }
    }

    private func runEntrance() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.05)) {
            ring1Scale = 1; ring2Scale = 1; ring1Opacity = 1
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.15)) {
            iconScale = 1; iconOpacity = 1
        }
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            orbitAngle = 360
        }
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.3)) {
            glowPulse = 1.06
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
            titleOpacity = 1; titleOffset = 0
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.45)) {
            descOpacity = 1; descOffset = 0
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.6)) { bullet1Opacity = 1 }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.75)) { bullet2Opacity = 1 }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.9)) { bullet3Opacity = 1 }
    }

    private func resetAll() {
        iconScale = 0.4; iconOpacity = 0
        ring1Scale = 0.5; ring2Scale = 0.5; ring1Opacity = 0
        orbitAngle = 0; glowPulse = 1.0
        titleOpacity = 0; titleOffset = 28
        descOpacity = 0; descOffset = 20
        bullet1Opacity = 0; bullet2Opacity = 0; bullet3Opacity = 0
    }
}

#Preview {
    ZStack {
        Color(hex: "0A1128").ignoresSafeArea()
        OnboardingPageView(page: OnboardingPage.pages[0])
            .environmentObject(ThemeManager.shared)
    }
}
