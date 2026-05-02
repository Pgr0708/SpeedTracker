//
//  PedometerDetailView.swift
//  SpeedTracker
//
import SwiftUI
import MapKit

struct PedometerDetailView: View {
    @EnvironmentObject var theme: ThemeManager
    let session: PedometerSession

    private var hasRoute: Bool { session.routeCoordinates.count > 1 }

    private var mapCenter: CLLocationCoordinate2D {
        guard let first = session.startCoordinate else {
            return CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        }
        return first
    }

    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    mapSection
                    statsGrid
                    Spacer().frame(height: 80)
                }
            }
        }
        .navigationTitle(session.activityType.capitalized)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Map
    var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route")
                .font(.label)
                .foregroundColor(theme.textSecondary)
                .padding(.horizontal, 24)

            if hasRoute {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: mapCenter,
                    latitudinalMeters: max(session.distance * 1.5, 300),
                    longitudinalMeters: max(session.distance * 1.5, 300)
                ))) {
                    MapPolyline(coordinates: session.routeCoordinates.map(\.coordinate))
                        .stroke(theme.primaryColor, lineWidth: 4)

                    if let start = session.startCoordinate {
                        Annotation("Start", coordinate: start) {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(AppConstants.Colors.limeGreen))
                                .shadow(radius: 4)
                        }
                    }
                    if let end = session.endCoordinate {
                        Annotation("Finish", coordinate: end) {
                            Image(systemName: "flag.checkered")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(Color(hex: "FF3B5C")))
                                .shadow(radius: 4)
                        }
                    }
                }
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 20)
            } else {
                GlassMorphismCard(padding: AppConstants.Design.paddingL) {
                    VStack(spacing: 8) {
                        Image(systemName: "map.slash")
                            .font(.system(size: 40))
                            .foregroundColor(theme.textTertiary)
                        Text("No route recorded")
                            .font(.bodySmall)
                            .foregroundColor(theme.textSecondary)
                        Text("Route tracking requires location permission and starts with new sessions.")
                            .font(.system(size: 12))
                            .foregroundColor(theme.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Stats Grid
    var statsGrid: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCard(icon: "figure.walk", label: "Steps", value: "\(session.steps)", color: theme.primaryColor)
                statCard(icon: "flame.fill", label: "Calories", value: session.caloriesFormatted, color: AppConstants.Colors.neonOrange)
                statCard(icon: "ruler", label: "Distance", value: session.distanceFormatted, color: AppConstants.Colors.limeGreen)
                statCard(icon: "clock.fill", label: "Duration", value: session.durationFormatted, color: theme.primaryColor)
                statCard(icon: "speedometer", label: "Avg Pace", value: session.avgPace > 0 ? session.paceFormatted : "--", color: Color(hex: "00D9FF"))
                statCard(icon: "calendar", label: "Date", value: dateFormatted, color: theme.textSecondary)
            }
            .padding(.horizontal, 20)

            if session.goalSteps > 0 {
                GlassMorphismCard(padding: AppConstants.Design.paddingM) {
                    HStack {
                        Image(systemName: session.goalAchieved ? "checkmark.seal.fill" : "target")
                            .font(.system(size: 20))
                            .foregroundColor(session.goalAchieved ? AppConstants.Colors.limeGreen : theme.primaryColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Daily Goal")
                                .font(.label).foregroundColor(theme.textSecondary)
                            Text(session.goalAchieved ? "Goal achieved! \(session.goalSteps) steps" : "\(session.steps) / \(session.goalSteps) steps")
                                .font(.bodyMedium).foregroundColor(theme.textPrimary)
                        }
                        Spacer()
                        if session.goalSteps > 0 {
                            Text(String(format: "%.0f%%", min(Double(session.steps) / Double(session.goalSteps) * 100, 100)))
                                .font(.orbitron(20))
                                .foregroundColor(session.goalAchieved ? AppConstants.Colors.limeGreen : theme.primaryColor)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func statCard(icon: String, label: String, value: String, color: Color) -> some View {
        GlassMorphismCard(padding: AppConstants.Design.paddingM) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: icon).font(.system(size: 13)).foregroundColor(color)
                    Text(label).font(.label).foregroundColor(theme.textSecondary)
                }
                Text(value)
                    .font(.orbitron(18))
                    .foregroundColor(theme.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var dateFormatted: String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: session.date)
    }
}
