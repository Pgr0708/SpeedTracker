//
//  CompassView.swift
//  SpeedTracker
//
import SwiftUI

struct CompassView: View {
    @EnvironmentObject var theme: ThemeManager
    @StateObject private var locationManager = LocationManager.shared
    @State private var appeared = false

    var headingFormatted: String { String(format: "%.0f°", locationManager.heading) }
    var cardinalDirection: String {
        let h = locationManager.heading
        switch h {
        case 337.5..<360, 0..<22.5: return "N"
        case 22.5..<67.5:  return "NE"
        case 67.5..<112.5: return "E"
        case 112.5..<157.5: return "SE"
        case 157.5..<202.5: return "S"
        case 202.5..<247.5: return "SW"
        case 247.5..<292.5: return "W"
        case 292.5..<337.5: return "NW"
        default: return "N"
        }
    }
    var altitudeFormatted: String { String(format: "%.1f m", locationManager.altitude) }
    var coordFormatted: String {
        let lat = locationManager.latitude; let lon = locationManager.longitude
        guard lat != 0 || lon != 0 else { return "-- , --" }
        return String(format: "%.5f°, %.5f°", lat, lon)
    }

    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppConstants.Design.paddingL) {
                    headerView
                    compassRoseView
                    coordinateStatsView
                    Spacer().frame(height: 80)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1)) { appeared = true }
        }
    }

    // MARK: - Header
    var headerView: some View {
        HStack {
            Text("COMPASS")
                .font(Font.custom(AppConstants.Typography.orbitronBold, size: 28))
                .foregroundColor(theme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, AppConstants.Design.paddingL)
        .padding(.top, AppConstants.Design.paddingXL)
        .opacity(appeared ? 1 : 0)
    }

    // MARK: - Compass Rose
    var compassRoseView: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .fill(RadialGradient(
                    colors: [theme.primaryColor.opacity(0.12), .clear],
                    center: .center, startRadius: 80, endRadius: 150
                ))
                .frame(width: 280, height: 280)

            // Tick marks ring
            ForEach(0..<72) { i in
                let isMajor = i % 9 == 0
                Rectangle()
                    .fill(isMajor ? theme.textPrimary.opacity(0.6) : theme.textTertiary.opacity(0.3))
                    .frame(width: isMajor ? 2 : 1, height: isMajor ? 12 : 6)
                    .offset(y: -115)
                    .rotationEffect(.degrees(Double(i) * 5))
            }

            // Cardinal labels
            ForEach(["N", "E", "S", "W"].indices, id: \.self) { i in
                let angle = Double(i) * 90
                let isNorth = i == 0
                Text(["N", "E", "S", "W"][i])
                    .font(Font.custom(AppConstants.Typography.orbitronBold, size: isNorth ? 16 : 13))
                    .foregroundColor(isNorth ? Color(hex: "FF3B5C") : theme.textSecondary)
                    .offset(y: -90)
                    .rotationEffect(.degrees(angle - locationManager.heading))
            }

            // Needle
            ZStack {
                // North (red)
                Triangle()
                    .fill(Color(hex: "FF3B5C"))
                    .frame(width: 16, height: 60)
                    .offset(y: -30)
                // South (gray)
                Triangle()
                    .fill(theme.textTertiary.opacity(0.5))
                    .frame(width: 16, height: 60)
                    .rotationEffect(.degrees(180))
                    .offset(y: 30)
                // Center dot
                Circle()
                    .fill(theme.primaryColor)
                    .frame(width: 14, height: 14)
                    .shadow(color: theme.primaryColor.opacity(0.6), radius: 6)
            }
            .rotationEffect(.degrees(-locationManager.heading))
            .animation(.easeInOut(duration: 0.3), value: locationManager.heading)

            // Heading display
            VStack(spacing: 4) {
                Spacer().frame(height: 130)
                Text(headingFormatted)
                    .font(Font.custom(AppConstants.Typography.orbitronBold, size: 22))
                    .foregroundColor(theme.textPrimary)
                Text(cardinalDirection)
                    .font(Font.custom(AppConstants.Typography.rajdhaniMedium, size: 14))
                    .foregroundColor(theme.primaryColor)
            }
        }
        .frame(width: 280, height: 280)
        .scaleEffect(appeared ? 1 : 0.8)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: appeared)
    }

    // MARK: - Coordinate Stats
    var coordinateStatsView: some View {
        VStack(spacing: AppConstants.Design.paddingM) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppConstants.Design.paddingM) {
                CompassStatCard(
                    icon: "arrow.up",
                    title: "Altitude",
                    value: altitudeFormatted,
                    color: theme.primaryColor,
                    theme: theme
                )
                CompassStatCard(
                    icon: "location.fill",
                    title: "Heading",
                    value: headingFormatted + " " + cardinalDirection,
                    color: Color(hex: "FF3B5C"),
                    theme: theme
                )
            }

            GlassMorphismCard(padding: AppConstants.Design.paddingM) {
                HStack(spacing: AppConstants.Design.paddingM) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 20))
                        .foregroundColor(theme.primaryColor)
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("COORDINATES")
                            .font(Font.custom(AppConstants.Typography.rajdhaniMedium, size: 11))
                            .foregroundColor(theme.textSecondary)
                        Text(coordFormatted)
                            .font(Font.custom(AppConstants.Typography.rajdhaniMedium, size: 15))
                            .foregroundColor(theme.textPrimary)
                    }
                    Spacer()
                }
            }
        }
        .padding(.horizontal, AppConstants.Design.paddingL)
        .opacity(appeared ? 1 : 0)
    }
}

// MARK: - Compass Stat Card
struct CompassStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let theme: ThemeManager

    var body: some View {
        GlassMorphismCard(padding: AppConstants.Design.paddingM) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: icon).font(.system(size: 13)).foregroundColor(color)
                    Text(title)
                        .font(Font.custom(AppConstants.Typography.rajdhaniMedium, size: 11))
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

// MARK: - Triangle shape for needle
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

#Preview { CompassView().environmentObject(ThemeManager.shared) }
