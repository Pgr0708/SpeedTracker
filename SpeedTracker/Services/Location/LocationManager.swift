//
//  LocationManager.swift
//  SpeedTracker
//
//  Core location service for real GPS speed tracking
//

import Foundation
import CoreLocation
import Combine

@MainActor
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    
    // Published properties
    @Published var currentSpeed: Double = 0 // meters per second
    @Published var maxSpeed: Double = 0
    @Published var avgSpeed: Double = 0
    @Published var totalDistance: Double = 0 // meters
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
    
    // Tracking internals
    private var previousLocation: CLLocation?
    private var speedReadings: [Double] = []
    private var trackingStartTime: Date?
    private var elapsedTimer: Timer?
    
    // Movement threshold (m/s) - ~3 km/h to filter noise
    private let movementThreshold: Double = 0.8
    
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
    
    // MARK: - Permission
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    var hasLocationPermission: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    // MARK: - Tracking Control
    func startTracking() {
        guard hasLocationPermission else {
            requestPermission()
            return
        }
        
        resetSession()
        isTracking = true
        trackingStartTime = Date()
        manager.startUpdatingLocation()
        
        // Elapsed time timer
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let start = self.trackingStartTime else { return }
                self.elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }
    
    func stopTracking() -> TripRecord? {
        isTracking = false
        isMoving = false
        manager.stopUpdatingLocation()
        elapsedTimer?.invalidate()
        elapsedTimer = nil
        
        guard let startTime = trackingStartTime,
              !routeCoordinates.isEmpty else { return nil }
        
        endLocation = currentLocation
        
        let trip = TripRecord(
            id: UUID(),
            date: startTime,
            duration: elapsedTime,
            distance: totalDistance,
            maxSpeed: maxSpeed,
            avgSpeed: avgSpeed,
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
        currentSpeed = 0
        maxSpeed = 0
        avgSpeed = 0
        totalDistance = 0
        routeCoordinates = []
        speedHistory = []
        speedReadings = []
        previousLocation = nil
        startLocation = nil
        endLocation = nil
        elapsedTime = 0
        trackingStartTime = nil
    }
    
    // MARK: - Speed Conversion
    func convertedSpeed(_ metersPerSecond: Double, unit: AppConstants.SpeedUnit) -> Double {
        return max(0, metersPerSecond * unit.conversionFromMPS)
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last, isTracking else { return }
            
            // Filter out inaccurate readings
            guard location.horizontalAccuracy >= 0, location.horizontalAccuracy < 50 else { return }
            
            gpsAccuracy = location.horizontalAccuracy
            currentLocation = location
            
            // Set start location
            if startLocation == nil {
                startLocation = location
            }
            
            // Speed from GPS
            let speed = location.speed >= 0 ? location.speed : 0
            
            // Check if actually moving
            isMoving = speed > movementThreshold
            
            if isMoving {
                currentSpeed = speed
                
                // Track max
                if speed > maxSpeed {
                    maxSpeed = speed
                }
                
                // Track average
                speedReadings.append(speed)
                avgSpeed = speedReadings.reduce(0, +) / Double(speedReadings.count)
                
                // Record speed history point
                speedHistory.append((time: Date(), speed: speed))
            } else {
                currentSpeed = 0
            }
            
            // Distance from previous
            if let prev = previousLocation {
                let dist = location.distance(from: prev)
                if dist < 500 { // filter GPS jumps
                    totalDistance += dist
                }
            }
            
            // Route
            routeCoordinates.append(location.coordinate)
            previousLocation = location
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
