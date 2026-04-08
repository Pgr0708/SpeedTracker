//
//  HistoryView.swift
//  SpeedTracker
//
//  Trip history with glass morphism cards
//

import SwiftUI

struct HistoryView: View {
    @State private var trips: [MockTrip] = MockTrip.samples
    
    var body: some View {
        ZStack {
            AppConstants.Colors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppConstants.Design.paddingL) {
                    // Header
                    HStack {
                        Text("HISTORY")
                            .font(.headingLarge)
                            .foregroundColor(AppConstants.Colors.textPrimary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, AppConstants.Design.paddingL)
                    .padding(.top, AppConstants.Design.paddingXL)
                    
                    // Stats Summary
                    GlassMorphismCard {
                        HStack(spacing: AppConstants.Design.paddingL) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TOTAL TRIPS")
                                    .font(.caption)
                                    .foregroundColor(AppConstants.Colors.textSecondary)
                                
                                Text("\(trips.count)")
                                    .font(.headingLarge)
                                    .foregroundColor(AppConstants.Colors.electricBlue)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("TOTAL DISTANCE")
                                    .font(.caption)
                                    .foregroundColor(AppConstants.Colors.textSecondary)
                                
                                Text("245.8 km")
                                    .font(.headingMedium)
                                    .foregroundColor(AppConstants.Colors.limeGreen)
                            }
                        }
                    }
                    .padding(.horizontal, AppConstants.Design.paddingL)
                    
                    // Trips List
                    LazyVStack(spacing: AppConstants.Design.paddingM) {
                        ForEach(trips) { trip in
                            TripCard(trip: trip)
                        }
                    }
                    .padding(.horizontal, AppConstants.Design.paddingL)
                    .padding(.bottom, 100) // Space for tab bar
                }
            }
        }
    }
}

struct TripCard: View {
    let trip: MockTrip
    
    var body: some View {
        GlassMorphismCard(padding: AppConstants.Design.paddingM) {
            VStack(spacing: AppConstants.Design.paddingM) {
                // Header with date and badge
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.date)
                            .font(.bodyLarge)
                            .foregroundColor(AppConstants.Colors.textPrimary)
                        
                        Text(trip.time)
                            .font(.caption)
                            .foregroundColor(AppConstants.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    if trip.isRecord {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(AppConstants.Colors.neonOrange)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(AppConstants.Colors.neonOrange.opacity(0.2))
                            )
                    }
                }
                
                Divider()
                    .background(AppConstants.Colors.textSecondary.opacity(0.2))
                
                // Stats
                HStack(spacing: AppConstants.Design.paddingL) {
                    TripStat(icon: "speedometer", value: "\(trip.maxSpeed)", unit: "km/h", label: "MAX")
                    TripStat(icon: "chart.line.uptrend.xyaxis", value: "\(trip.avgSpeed)", unit: "km/h", label: "AVG")
                    TripStat(icon: "location.fill", value: trip.distance, unit: "km", label: "DIST")
                }
            }
        }
    }
}

struct TripStat: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(AppConstants.Colors.electricBlue)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.bodyLarge)
                    .foregroundColor(AppConstants.Colors.textPrimary)
                
                Text(unit)
                    .font(.system(size: 10))
                    .foregroundColor(AppConstants.Colors.textSecondary)
            }
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(AppConstants.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// Mock data
struct MockTrip: Identifiable {
    let id = UUID()
    let date: String
    let time: String
    let maxSpeed: Int
    let avgSpeed: Int
    let distance: String
    let isRecord: Bool
    
    static let samples = [
        MockTrip(date: "Today", time: "14:30", maxSpeed: 125, avgSpeed: 87, distance: "23.5", isRecord: true),
        MockTrip(date: "Yesterday", time: "09:15", maxSpeed: 98, avgSpeed: 72, distance: "18.2", isRecord: false),
        MockTrip(date: "Apr 6", time: "16:45", maxSpeed: 110, avgSpeed: 82, distance: "31.7", isRecord: false),
        MockTrip(date: "Apr 5", time: "11:20", maxSpeed: 95, avgSpeed: 68, distance: "15.8", isRecord: false),
    ]
}

#Preview {
    HistoryView()
}
