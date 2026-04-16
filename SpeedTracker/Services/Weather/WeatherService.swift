//
//  WeatherService.swift
//  SpeedTracker
//
//  WeatherKit integration (iOS 16+). Requires WeatherKit capability in Apple Developer account.
//
import Foundation
import CoreLocation
import SwiftUI
import Combine

@MainActor
class WeatherService: ObservableObject {
    static let shared = WeatherService()

    @Published var temperature: String = "--"
    @Published var condition: String = "--"
    @Published var windSpeed: String = "--"
    @Published var conditionSymbol: String = "cloud.fill"
    @Published var isLoading = false

    private var lastFetchLocation: CLLocationCoordinate2D?
    private var lastFetchTime: Date?
    private let refreshInterval: TimeInterval = 900 // 15 min

    private init() {}

    func fetchWeather(for location: CLLocationCoordinate2D) {
        // Throttle: only fetch if location changed significantly or enough time passed
        if let last = lastFetchTime, Date().timeIntervalSince(last) < refreshInterval,
           let lastLoc = lastFetchLocation,
           abs(lastLoc.latitude - location.latitude) < 0.01 { return }

        isLoading = true
        lastFetchLocation = location
        lastFetchTime = Date()

        Task {
            await fetchWeatherKit(location: location)
            self.isLoading = false
        }
    }

    private func fetchWeatherKit(location: CLLocationCoordinate2D) async {
        // WeatherKit requires:
        // 1. Add WeatherKit capability in Xcode → Signing & Capabilities
        // 2. Enable WeatherKit in Apple Developer portal
        // 3. Import WeatherKit and use Weather.shared.weather(for:)
        //
        // Example (uncomment after enabling capability):
        // import WeatherKit
        // let weather = try await WeatherService().weather(for: CLLocation(latitude: location.latitude, longitude: location.longitude))
        // self.temperature = "\(Int(weather.currentWeather.temperature.converted(to: .celsius).value))°C"
        // self.windSpeed = "\(Int(weather.currentWeather.wind.speed.converted(to: .kilometersPerHour).value)) km/h"
        // self.conditionSymbol = weather.currentWeather.symbolName
        // self.condition = weather.currentWeather.condition.description

        // Placeholder until WeatherKit is enabled:
        self.temperature = "24°C"
        self.condition = "Clear"
        self.conditionSymbol = "sun.max.fill"
        self.windSpeed = "12 km/h"
    }
}
