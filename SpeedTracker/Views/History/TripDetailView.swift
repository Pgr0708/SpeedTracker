//
//  TripDetailView.swift
//  SpeedTracker
//
//  Trip detail with Apple Map route and speed-time graph
//

import SwiftUI
import MapKit
import Charts

struct TripDetailView: View {
    @EnvironmentObject var theme: ThemeManager
    @AppStorage(AppConstants.UserDefaultsKeys.preferredSpeedUnit) private var speedUnitRaw: String = AppConstants.SpeedUnit.kmh.rawValue
    let trip: TripRecord
    
    var speedUnit: AppConstants.SpeedUnit {
        AppConstants.SpeedUnit(rawValue: speedUnitRaw) ?? .kmh
    }
    
    var body: some View {
        ZStack {
            theme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Map Section
                    mapSection
                    
                    // Trip Stats
                    tripStats
                    
                    // Speed-Time Graph
                    speedGraph
                    
                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Map
    var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ROUTE")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(theme.textSecondary)
                .padding(.horizontal, 24)
            
            Map(initialPosition: .region(MKCoordinateRegion(
                center: trip.startCoordinate,
                latitudinalMeters: max(trip.distance * 1.5, 500),
                longitudinalMeters: max(trip.distance * 1.5, 500)
            ))) {
                // Route polyline
                if trip.routeCoordinates.count > 1 {
                    MapPolyline(coordinates: trip.routeCoordinates.map(\.coordinate))
                        .stroke(theme.primaryColor, lineWidth: 4)
                }

                // Start pin
                Annotation("Start", coordinate: trip.startCoordinate) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Circle().fill(AppConstants.Colors.limeGreen))
                        .shadow(radius: 4)
                }

                // End pin
                Annotation("End", coordinate: trip.endCoordinate) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Circle().fill(Color(hex: "FF3B5C")))
                        .shadow(radius: 4)
                }
            }
            .frame(height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Trip Stats
    var tripStats: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            DetailStatCard(
                title: "Max Speed",
                value: "\(Int(trip.maxSpeedConverted(speedUnit)))",
                unit: speedUnit.rawValue,
                icon: "arrow.up.circle.fill",
                color: AppConstants.Colors.neonOrange,
                theme: theme
            )
            
            DetailStatCard(
                title: "Avg Speed",
                value: "\(Int(trip.avgSpeedConverted(speedUnit)))",
                unit: speedUnit.rawValue,
                icon: "chart.line.uptrend.xyaxis",
                color: theme.primaryColor,
                theme: theme
            )
            
            DetailStatCard(
                title: "Distance",
                value: trip.distanceFormatted,
                unit: "",
                icon: "location.fill",
                color: AppConstants.Colors.limeGreen,
                theme: theme
            )
            
            DetailStatCard(
                title: "Duration",
                value: trip.durationFormatted,
                unit: "",
                icon: "clock.fill",
                color: Color(hex: "9D4EDD"),
                theme: theme
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Speed Graph
    var speedGraph: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SPEED OVER TIME")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(theme.textSecondary)
            
            if trip.speedHistory.isEmpty {
                Text("No speed data available")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textTertiary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(Array(trip.speedHistory.enumerated()), id: \.offset) { index, point in
                        let convertedSpeed = point.speed * speedUnit.conversionFromMPS
                        
                        LineMark(
                            x: .value("Time", index),
                            y: .value("Speed", convertedSpeed)
                        )
                        .foregroundStyle(theme.primaryColor)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        
                        AreaMark(
                            x: .value("Time", index),
                            y: .value("Speed", convertedSpeed)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.primaryColor.opacity(0.3), theme.primaryColor.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .chartYAxisLabel(speedUnit.rawValue)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel()
                            .foregroundStyle(theme.textSecondary)
                        AxisGridLine()
                            .foregroundStyle(theme.textTertiary.opacity(0.3))
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(theme.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

struct DetailStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let theme: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(theme.textSecondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(theme.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        TripDetailView(trip: TripRecord(
            id: UUID(),
            date: Date(),
            duration: 1800,
            distance: 25000,
            maxSpeed: 33.3,
            avgSpeed: 22.2,
            startLatitude: 37.7749,
            startLongitude: -122.4194,
            endLatitude: 37.7849,
            endLongitude: -122.4094,
            routeCoordinates: [
                RoutePoint(latitude: 37.7749, longitude: -122.4194),
                RoutePoint(latitude: 37.7799, longitude: -122.4144),
                RoutePoint(latitude: 37.7849, longitude: -122.4094)
            ],
            speedHistory: [
                SpeedPoint(timestamp: Date(), speed: 10),
                SpeedPoint(timestamp: Date().addingTimeInterval(10), speed: 20),
                SpeedPoint(timestamp: Date().addingTimeInterval(20), speed: 30),
                SpeedPoint(timestamp: Date().addingTimeInterval(30), speed: 25),
                SpeedPoint(timestamp: Date().addingTimeInterval(40), speed: 15)
            ]
        ))
        .environmentObject(ThemeManager.shared)
    }
}
