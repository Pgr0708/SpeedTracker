//
//  LocationManager.swift
//  SpeedTracker
//
import Foundation
import CoreLocation
import Combine

@MainActor
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    private let manager = CLLocationManager()

    @Published var currentSpeed: Double = 0
    @Published var maxSpeed: Double = 0
    @Published var avgSpeed: Double = 0
    @Published var totalDistance: Double = 0
    @Published var currentLocation: CLLocation?
    @Published var isTracking = false
    @Published var isMoving = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var gpsAccuracy: CLLocationAccuracy = -1
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var speedHistory: [(time: Date, speed: Double)] = []
    @Published var elapsedTime: TimeInterval = 0
    @Published var startLocation: CLLocation?
    @Published var endLocation: CLLocation?
    // New published properties
    @Published var altitude: Double = 0
    @Published var heading: Double = 0
    @Published var latitude: Double = 0
    @Published var longitude: Double = 0

    private var previousLocation: CLLocation?
    private var speedReadings: [Double] = []
    private var trackingStartTime: Date?
    private var elapsedTimer: Timer?
    private let movementThreshold: Double = 0.5

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 5
        manager.activityType = .automotiveNavigation
        manager.allowsBackgroundLocationUpdates = false
        manager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() { manager.requestWhenInUseAuthorization() }

    func startHeading() {
        guard hasLocationPermission else { return }
        manager.startUpdatingHeading()
    }

    func stopHeading() {
        guard !isTracking else { return }
        manager.stopUpdatingHeading()
    }

    var hasLocationPermission: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    func startTracking() {
        guard hasLocationPermission else { requestPermission(); return }
        resetSession()
        isTracking = true
        trackingStartTime = Date()
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let start = self.trackingStartTime else { return }
                self.elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }

    func stopTracking() -> TripRecord? {
        isTracking = false
        isMoving = false
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
        elapsedTimer?.invalidate()
        elapsedTimer = nil
        guard let startTime = trackingStartTime, !routeCoordinates.isEmpty else { return nil }
        endLocation = currentLocation
        let trip = TripRecord(
            id: UUID(), date: startTime, duration: elapsedTime,
            distance: totalDistance, maxSpeed: maxSpeed, avgSpeed: avgSpeed,
            startLatitude: startLocation?.coordinate.latitude ?? 0,
            startLongitude: startLocation?.coordinate.longitude ?? 0,
            endLatitude: endLocation?.coordinate.latitude ?? 0,
            endLongitude: endLocation?.coordinate.longitude ?? 0,
            routeCoordinates: routeCoordinates.map { RoutePoint(latitude: $0.latitude, longitude: $0.longitude) },
            speedHistory: speedHistory.map { SpeedPoint(timestamp: $0.time, speed: $0.speed) }
        )
        currentSpeed = 0
        return trip
    }

    private func resetSession() {
        currentSpeed = 0; maxSpeed = 0; avgSpeed = 0; totalDistance = 0
        routeCoordinates = []; speedHistory = []; speedReadings = []
        previousLocation = nil; startLocation = nil; endLocation = nil
        elapsedTime = 0; trackingStartTime = nil
    }

    func convertedSpeed(_ mps: Double, unit: AppConstants.SpeedUnit) -> Double {
        max(0, mps * unit.conversionFromMPS)
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            guard location.horizontalAccuracy >= 0, location.horizontalAccuracy < 50 else { return }
            gpsAccuracy = location.horizontalAccuracy
            currentLocation = location
            altitude = location.altitude
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
            if startLocation == nil { startLocation = location }
            let speed = location.speed >= 0 ? location.speed : 0
            isMoving = speed > movementThreshold
            if isTracking {
                if isMoving {
                    currentSpeed = speed
                    if speed > maxSpeed { maxSpeed = speed }
                    speedReadings.append(speed)
                    avgSpeed = speedReadings.reduce(0, +) / Double(speedReadings.count)
                    speedHistory.append((time: Date(), speed: speed))
                } else {
                    currentSpeed = 0
                }
                if let prev = previousLocation {
                    let dist = location.distance(from: prev)
                    let speedBased = max(speed * 3, 100.0)
                    if dist < speedBased { totalDistance += dist }
                }
                routeCoordinates.append(location.coordinate)
                previousLocation = location
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in authorizationStatus = manager.authorizationStatus }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
