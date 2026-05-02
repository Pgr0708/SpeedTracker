//
//  HistoryView.swift
//  SpeedTracker
//
import SwiftUI

enum HistoryTab { case trips, steps }

struct HistoryView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var authService: AuthService
    @StateObject private var tripStore = TripStore.shared
    @StateObject private var pedometerService = PedometerService.shared
    @AppStorage(AppConstants.UserDefaultsKeys.preferredSpeedUnit) private var speedUnitRaw: String = AppConstants.SpeedUnit.kmh.rawValue
    @State private var selectedTrip: TripRecord?
    @State private var selectedSession: PedometerSession?
    @State private var showPaywall = false
    @State private var selectedTab: HistoryTab = .trips

    var speedUnit: AppConstants.SpeedUnit { AppConstants.SpeedUnit(rawValue: speedUnitRaw) ?? .kmh }
    var isPremium: Bool { purchaseService.isPremium }

    // Free users see only last 5 trips
    var visibleTrips: [TripRecord] {
        isPremium ? tripStore.trips : Array(tripStore.trips.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppConstants.Design.paddingL) {
                        // Title
                        HStack {
                            Text(L10n.text("history.title"))
                                .font(.headingMedium)
                                .foregroundColor(theme.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, AppConstants.Design.paddingL)
                        .padding(.top, AppConstants.Design.paddingXL)

                        // Trips / Steps toggle
                        tabToggle

                        if selectedTab == .trips {
                            tripsContent
                        } else {
                            stepsContent
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationDestination(item: $selectedTrip) { trip in
                TripDetailView(trip: trip)
                    .environmentObject(theme)
                    .environmentObject(purchaseService)
            }
            .navigationDestination(item: $selectedSession) { session in
                PedometerDetailView(session: session)
                    .environmentObject(theme)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(theme)
                .environmentObject(purchaseService)
                .environmentObject(authService)
        }
    }

    // MARK: - Tab Toggle
    var tabToggle: some View {
        HStack(spacing: 0) {
            tabButton(title: "Trips", icon: "car.fill", tab: .trips)
            tabButton(title: "Steps", icon: "figure.walk", tab: .steps)
        }
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Design.cornerRadiusM)
                .fill(theme.isDarkMode ? Color.white.opacity(0.07) : Color.black.opacity(0.05))
        )
        .padding(.horizontal, AppConstants.Design.paddingL)
    }

    @ViewBuilder
    func tabButton(title: String, icon: String, tab: HistoryTab) -> some View {
        let isSelected = selectedTab == tab
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
            HapticManager.shared.selection()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13))
                Text(title).font(.bodySmall)
            }
            .foregroundColor(isSelected ? .white : theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.Design.cornerRadiusM - 2)
                    .fill(isSelected ? theme.primaryColor : Color.clear)
                    .padding(3)
            )
        }
    }

    // MARK: - Trips Content
    var tripsContent: some View {
        Group {
            if tripStore.trips.isEmpty {
                emptyState(icon: "car.fill", message: "No trips yet.\nStart a trip to see your history here.")
            } else {
                VStack(spacing: AppConstants.Design.paddingL) {
                    tripSummaryCard

                    if !isPremium && tripStore.trips.count > 5 { upgradeBanner }

                    LazyVStack(spacing: AppConstants.Design.paddingM) {
                        ForEach(visibleTrips) { trip in
                            TripCard(trip: trip, speedUnit: speedUnit, theme: theme)
                                .onTapGesture { selectedTrip = trip; HapticManager.shared.selection() }
                        }
                        .onDelete { offsets in tripStore.deleteTrips(at: offsets) }

                        if !isPremium && tripStore.trips.count > 5 { lockedTripsFooter }
                    }
                    .padding(.horizontal, AppConstants.Design.paddingL)
                }
            }
        }
    }

    // MARK: - Steps Content
    var stepsContent: some View {
        Group {
            if pedometerService.sessions.isEmpty {
                emptyState(icon: "figure.walk", message: "No step sessions yet.\nStart a walk or run in the Steps tab.")
            } else {
                VStack(spacing: AppConstants.Design.paddingL) {
                    stepsSummaryCard

                    LazyVStack(spacing: AppConstants.Design.paddingM) {
                        ForEach(pedometerService.sessions) { session in
                            GlassMorphismCard(padding: AppConstants.Design.paddingM) {
                                PedometerSessionRow(session: session, theme: theme)
                            }
                            .onTapGesture { selectedSession = session; HapticManager.shared.selection() }
                        }
                        .onDelete { offsets in
                            offsets.forEach { pedometerService.deleteSession(pedometerService.sessions[$0]) }
                        }
                    }
                    .padding(.horizontal, AppConstants.Design.paddingL)
                }
            }
        }
    }

    // MARK: - Empty State
    func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: icon).font(.system(size: 60)).foregroundColor(theme.textTertiary)
            Text(message)
                .font(.bodySmall).foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
        .padding(.horizontal, AppConstants.Design.paddingXL)
    }

    // MARK: - Trip Summary Card
    var tripSummaryCard: some View {
        GlassMorphismCard {
            HStack(spacing: AppConstants.Design.paddingL) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("history.totalTrips")).font(.label).foregroundColor(theme.textSecondary)
                    Text("\(tripStore.totalTrips)").font(.orbitron(28)).foregroundColor(theme.primaryColor)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(L10n.text("history.totalDistance")).font(.label).foregroundColor(theme.textSecondary)
                    Text(formatTotalDistance(tripStore.totalDistance))
                        .font(.orbitron(22)).foregroundColor(AppConstants.Colors.limeGreen)
                }
            }
        }
        .padding(.horizontal, AppConstants.Design.paddingL)
    }

    // MARK: - Steps Summary Card
    var stepsSummaryCard: some View {
        let totalSteps = pedometerService.sessions.reduce(0) { $0 + $1.steps }
        let totalDist = pedometerService.sessions.reduce(0.0) { $0 + $1.distance }
        return GlassMorphismCard {
            HStack(spacing: AppConstants.Design.paddingL) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Steps").font(.label).foregroundColor(theme.textSecondary)
                    Text("\(totalSteps)").font(.orbitron(28)).foregroundColor(theme.primaryColor)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Distance").font(.label).foregroundColor(theme.textSecondary)
                    Text(formatTotalDistance(totalDist))
                        .font(.orbitron(22)).foregroundColor(AppConstants.Colors.limeGreen)
                }
            }
        }
        .padding(.horizontal, AppConstants.Design.paddingL)
    }

    // MARK: - Upgrade Banner
    var upgradeBanner: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill").font(.system(size: 18)).foregroundColor(Color(hex: "FFD700"))
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.string("history.showingTrips", 5, tripStore.trips.count))
                        .font(.bodySmall).foregroundColor(theme.textPrimary)
                    Text(L10n.text("history.upgradeDesc")).font(.caption).foregroundColor(theme.textSecondary)
                }
                Spacer()
                Text(L10n.text("history.upgrade")).font(.label)
                    .foregroundColor(Color(hex: "FFD700"))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color(hex: "FFD700").opacity(0.2)).cornerRadius(8)
            }
            .padding(.horizontal, AppConstants.Design.paddingM).padding(.vertical, AppConstants.Design.paddingM)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.Design.cornerRadiusM)
                    .fill(Color(hex: "FFD700").opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: AppConstants.Design.cornerRadiusM)
                        .strokeBorder(Color(hex: "FFD700").opacity(0.3), lineWidth: 1))
            )
        }
        .padding(.horizontal, AppConstants.Design.paddingL)
    }

    // MARK: - Locked Trips Footer
    var lockedTripsFooter: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "lock.fill").font(.system(size: 14)).foregroundColor(theme.textTertiary)
                Text(L10n.string("history.lockedTrips", tripStore.trips.count - 5))
                    .font(.caption).foregroundColor(theme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: AppConstants.Design.cornerRadiusM)
                .fill(theme.textTertiary.opacity(0.06)))
        }
    }

    func formatTotalDistance(_ meters: Double) -> String {
        meters >= 1000 ? String(format: "%.1f km", meters / 1000) : String(format: "%.0f m", meters)
    }
}

// MARK: - Trip Card
struct TripCard: View {
    let trip: TripRecord
    let speedUnit: AppConstants.SpeedUnit
    let theme: ThemeManager

    var body: some View {
        GlassMorphismCard(padding: AppConstants.Design.paddingM) {
            VStack(spacing: AppConstants.Design.paddingM) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.date, style: .date).font(.system(size: 16, weight: .semibold)).foregroundColor(theme.textPrimary)
                        Text(trip.date, style: .time).font(.system(size: 13)).foregroundColor(theme.textSecondary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                    Image(systemName: "clock").font(.system(size: 12))
                        Text(trip.durationFormatted).font(.caption)
                    }
                    .foregroundColor(theme.textSecondary).padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(theme.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.05)))
                    Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(theme.textTertiary)
                }
                Divider().background(theme.textSecondary.opacity(0.2))
                HStack(spacing: AppConstants.Design.paddingL) {
                    TripStatView(icon: "speedometer", value: "\(Int(trip.maxSpeedConverted(speedUnit)))", unit: L10n.string(speedUnit.localizationKey), label: L10n.string("history.maxShort"), color: AppConstants.Colors.neonOrange, theme: theme)
                    TripStatView(icon: "chart.line.uptrend.xyaxis", value: "\(Int(trip.avgSpeedConverted(speedUnit)))", unit: L10n.string(speedUnit.localizationKey), label: L10n.string("history.avgShort"), color: theme.primaryColor, theme: theme)
                    TripStatView(icon: "location.fill", value: trip.distanceFormatted, unit: "", label: L10n.string("history.distShort"), color: AppConstants.Colors.limeGreen, theme: theme)
                }
            }
        }
    }
}

struct TripStatView: View {
    let icon: String; let value: String; let unit: String; let label: String; let color: Color; let theme: ThemeManager
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.bodyMedium).foregroundColor(theme.textPrimary)
                if !unit.isEmpty { Text(unit).font(.caption).foregroundColor(theme.textSecondary) }
            }
            Text(label).font(.caption).foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HistoryView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(PurchaseService.shared)
        .environmentObject(AuthService.shared)
}
