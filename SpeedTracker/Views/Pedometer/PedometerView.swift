//
//  PedometerView.swift
//  SpeedTracker
//
import SwiftUI
import CoreMotion

struct PedometerView: View {
    @EnvironmentObject var theme: ThemeManager
    @StateObject private var pedometerService = PedometerService.shared
    @State private var showStopConfirm = false
    @State private var animateRing = false
    @State private var showMotionError = false

    var elapsedFormatted: String {
        let t = Int(pedometerService.elapsedTime); let m = t / 60; let s = t % 60
        return m >= 60 ? String(format: "%d:%02d:%02d", m / 60, m % 60, s) : String(format: "%d:%02d", m, s)
    }

    var distanceFormatted: String {
        let d = pedometerService.distance
        return d >= 1000 ? String(format: "%.2f km", d / 1000) : String(format: "%.0f m", d)
    }

    var paceFormatted: String {
        let p = pedometerService.currentPace
        guard p > 0 else { return "--" }
        let mins = Int(p); let secs = Int((p - Double(mins)) * 60)
        return String(format: "%d'%02d\"", mins, secs)
    }

    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppConstants.Design.paddingL) {
                    headerView
                    goalRingView
                    statsGridView
                    controlButton
                    if !pedometerService.sessions.isEmpty { sessionHistoryView }
                    Spacer().frame(height: 80)
                }
            }
        }
        .alert(L10n.string("pedometer.stopConfirm.title"), isPresented: $showStopConfirm) {
            Button(L10n.string("pedometer.stopAndSave"), role: .destructive) { stopAndSave() }
            Button(L10n.string("common.cancel"), role: .cancel) {}
        } message: { Text(L10n.string("pedometer.stopConfirm.message")) }
    }

    // MARK: - Header
    var headerView: some View {
        HStack {
            Text(L10n.text("pedometer.title"))
                .font(.headingMedium)
                .foregroundColor(theme.textPrimary)
            Spacer()
            if pedometerService.isTracking {
                HStack(spacing: 6) {
                    Circle().fill(AppConstants.Colors.limeGreen).frame(width: 8, height: 8)
                        .scaleEffect(animateRing ? 1.4 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animateRing)
                    Text(L10n.text("pedometer.active"))
                        .font(.label)
                        .foregroundColor(AppConstants.Colors.limeGreen)
                }
                .onAppear { animateRing = true }
            }
        }
        .padding(.horizontal, AppConstants.Design.paddingL)
        .padding(.top, AppConstants.Design.paddingXL)
    }

    // MARK: - Goal Ring
    var goalRingView: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(theme.textTertiary.opacity(0.2), lineWidth: 18)
                .frame(width: 200, height: 200)

            // Progress ring
            Circle()
                .trim(from: 0, to: pedometerService.goalProgress)
                .stroke(
                    AngularGradient(
                        colors: [AppConstants.Colors.limeGreen, theme.primaryColor],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: pedometerService.goalProgress)

            // Center content
            VStack(spacing: 4) {
                Text("\(pedometerService.steps)")
                    .font(Font.custom(AppConstants.Typography.orbitronBold, size: 36))
                    .foregroundColor(theme.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(L10n.text("pedometer.steps"))
                    .font(Font.custom(AppConstants.Typography.rajdhaniMedium, size: 14))
                    .foregroundColor(theme.textSecondary)
                Text(L10n.string("pedometer.goalStatus", Int(pedometerService.goalProgress * 100)))
                    .font(Font.custom(AppConstants.Typography.rajdhaniMedium, size: 12))
                    .foregroundColor(AppConstants.Colors.limeGreen)
            }
        }
        .padding(.vertical, AppConstants.Design.paddingM)
    }

    // MARK: - Stats Grid
    var statsGridView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppConstants.Design.paddingM) {
            PedometerStatCard(icon: "ruler", title: L10n.string("pedometer.distance"), value: distanceFormatted, color: theme.primaryColor, theme: theme)
            PedometerStatCard(icon: "flame.fill", title: L10n.string("pedometer.calories"), value: String(format: "%.0f kcal", pedometerService.calories), color: AppConstants.Colors.neonOrange, theme: theme)
            PedometerStatCard(icon: "timer", title: L10n.string("pedometer.elapsed"), value: elapsedFormatted, color: theme.primaryColor, theme: theme)
            PedometerStatCard(icon: "hare.fill", title: L10n.string("pedometer.pace"), value: paceFormatted + "/km", color: theme.primaryColor, theme: theme)
        }
        .padding(.horizontal, AppConstants.Design.paddingL)
    }

    // MARK: - Control Button
    var controlButton: some View {
        VStack(spacing: 10) {
            AnimatedButton(
                pedometerService.isTracking ? L10n.string("pedometer.stopWorkout") : L10n.string("pedometer.startWorkout"),
                icon: pedometerService.isTracking ? "stop.fill" : "figure.walk",
                variant: pedometerService.isTracking ? .secondary : .primary
            ) {
                HapticManager.shared.impact(style: .medium)
                if pedometerService.isTracking {
                    showStopConfirm = true
                } else {
                    let status = CMPedometer.authorizationStatus()
                    if status == .denied || status == .restricted {
                        showMotionError = true
                    } else {
                        showMotionError = false
                        pedometerService.startTracking()
                    }
                }
            }
            if showMotionError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(AppConstants.Colors.neonOrange)
                    Text(L10n.text("pedometer.motionRequired"))
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    Button(L10n.string("common.settings")) {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    }
                    .font(.caption)
                    .foregroundColor(theme.primaryColor)
                }
                .padding(.horizontal, 8)
                .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, AppConstants.Design.paddingL)
    }

    // MARK: - Session History
    var sessionHistoryView: some View {
        VStack(alignment: .leading, spacing: AppConstants.Design.paddingM) {
            Text(L10n.text("pedometer.recentSessions"))
                .font(.label)
                .foregroundColor(theme.textSecondary)
                .padding(.leading, AppConstants.Design.paddingS)

            VStack(spacing: 0) {
                ForEach(pedometerService.sessions.prefix(5)) { session in
                    PedometerSessionRow(session: session, theme: theme)
                    if session.id != pedometerService.sessions.prefix(5).last?.id {
                        Divider().background(theme.textTertiary.opacity(0.3)).padding(.leading, 56)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: AppConstants.Design.cornerRadiusM)
                    .fill(theme.isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppConstants.Design.cornerRadiusM)
                            .strokeBorder(theme.textTertiary.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, AppConstants.Design.paddingL)
    }

    // MARK: - Actions
    private func stopAndSave() {
        if let session = pedometerService.stopTracking() {
            pedometerService.saveSession(session)
        }
        animateRing = false
    }
}

// MARK: - Stat Card
struct PedometerStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let theme: ThemeManager

    var body: some View {
        GlassMorphismCard(padding: AppConstants.Design.paddingM) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
                    Text(title)
                        .font(Font.custom(AppConstants.Typography.rajdhaniMedium, size: 12))
                        .foregroundColor(theme.textSecondary)
                }
                Text(value)
                    .font(Font.custom(AppConstants.Typography.orbitronBold, size: 18))
                    .foregroundColor(theme.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Session Row
struct PedometerSessionRow: View {
    let session: PedometerSession
    let theme: ThemeManager

    var dateFormatted: String {
        let f = DateFormatter(); f.dateStyle = .short; f.timeStyle = .short
        return f.string(from: session.date)
    }
    var distanceFormatted: String {
        session.distance >= 1000
            ? String(format: "%.2f km", session.distance / 1000)
            : String(format: "%.0f m", session.distance)
    }

    var body: some View {
        HStack(spacing: AppConstants.Design.paddingM) {
            ZStack {
                Circle().fill(theme.primaryColor.opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: session.activityType == "running" ? "figure.run" : "figure.walk")
                    .font(.system(size: 18)).foregroundColor(theme.primaryColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.string("pedometer.stepsCount", session.steps))
                    .font(.bodyMedium).foregroundColor(theme.textPrimary)
                Text(dateFormatted)
                    .font(.system(size: 12)).foregroundColor(theme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(distanceFormatted)
                    .font(.system(size: 14, weight: .medium)).foregroundColor(theme.textPrimary)
                Text(String(format: "%.0f kcal", session.calories))
                    .font(.system(size: 12)).foregroundColor(AppConstants.Colors.neonOrange)
            }
        }
        .padding(.horizontal, AppConstants.Design.paddingM)
        .padding(.vertical, AppConstants.Design.paddingM)
    }
}

#Preview { PedometerView().environmentObject(ThemeManager.shared) }
