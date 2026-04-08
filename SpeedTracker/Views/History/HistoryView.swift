//
//  HistoryView.swift
//  SpeedTracker
//
//  Trip history with REAL data from TripStore
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var theme: ThemeManager
    @StateObject private var tripStore = TripStore.shared
    @AppStorage(AppConstants.UserDefaultsKeys.preferredSpeedUnit) private var speedUnitRaw: String = AppConstants.SpeedUnit.kmh.rawValue
    @State private var selectedTrip: TripRecord?
    
    var speedUnit: AppConstants.SpeedUnit {
        AppConstants.SpeedUnit(rawValue: speedUnitRaw) ?? .kmh
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient
                    .ignoresSafeArea()
                
                if tripStore.trips.isEmpty {
                    emptyState
                } else {
                    tripList
                }
            }
            .navigationDestination(item: $selectedTrip) { trip in
                TripDetailView(trip: trip)
                    .environmentObject(theme)
            }
        }
    }
    
    // MARK: - Empty State
    var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(theme.textTertiary)
            
            Text("No Trips Yet")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)
            
            Text("Start tracking your speed to see\nyour trip history here")
                .font(.system(size: 15))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Trip List
    var tripList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppConstants.Design.paddingL) {
                // Header
                HStack {
                    Text("HISTORY")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, AppConstants.Design.paddingL)
                .padding(.top, AppConstants.Design.paddingXL)
                
                // Summary Card
                summaryCard
                
                // Trips
                LazyVStack(spacing: AppConstants.Design.paddingM) {
                    ForEach(tripStore.trips) { trip in
                        TripCard(trip: trip, speedUnit: speedUnit, theme: theme)
                            .onTapGesture {
                                selectedTrip = trip
                                HapticManager.shared.selection()
                            }
                    }
                    .onDelete(perform: tripStore.deleteTrips)
                }
                .padding(.horizontal, AppConstants.Design.paddingL)
                .padding(.bottom, 100)
            }
        }
    }
    
    var summaryCard: some View {
        GlassMorphismCard {
            HStack(spacing: AppConstants.Design.paddingL) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOTAL TRIPS")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                    
                    Text("\(tripStore.totalTrips)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(theme.primaryColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("TOTAL DISTANCE")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                    
                    Text(formatTotalDistance(tripStore.totalDistance))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(AppConstants.Colors.limeGreen)
                }
            }
        }
        .padding(.horizontal, AppConstants.Design.paddingL)
    }
    
    func formatTotalDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        }
        return String(format: "%.0f m", meters)
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
                // Header with date
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.date, style: .date)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.textPrimary)
                        
                        Text(trip.date, style: .time)
                            .font(.system(size: 13))
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Duration
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text(trip.durationFormatted)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(theme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(theme.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                    )
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textTertiary)
                }
                
                Divider()
                    .background(theme.textSecondary.opacity(0.2))
                
                // Stats row
                HStack(spacing: AppConstants.Design.paddingL) {
                    TripStatView(
                        icon: "speedometer",
                        value: "\(Int(trip.maxSpeedConverted(speedUnit)))",
                        unit: speedUnit.rawValue,
                        label: "MAX",
                        color: AppConstants.Colors.neonOrange,
                        theme: theme
                    )
                    
                    TripStatView(
                        icon: "chart.line.uptrend.xyaxis",
                        value: "\(Int(trip.avgSpeedConverted(speedUnit)))",
                        unit: speedUnit.rawValue,
                        label: "AVG",
                        color: theme.primaryColor,
                        theme: theme
                    )
                    
                    TripStatView(
                        icon: "location.fill",
                        value: trip.distanceFormatted,
                        unit: "",
                        label: "DIST",
                        color: AppConstants.Colors.limeGreen,
                        theme: theme
                    )
                }
            }
        }
    }
}

struct TripStatView: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    let color: Color
    let theme: ThemeManager
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 10))
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HistoryView()
        .environmentObject(ThemeManager.shared)
}
