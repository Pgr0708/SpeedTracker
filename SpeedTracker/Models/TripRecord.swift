//
//  TripRecord.swift
//  SpeedTracker
//
//  Trip data model with route, speed history, and CloudKit sync support
//

import Foundation
import CoreLocation

struct TripRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let distance: Double            // meters
    let maxSpeed: Double            // m/s
    let avgSpeed: Double            // m/s
    let startLatitude: Double
    let startLongitude: Double
    let endLatitude: Double
    let endLongitude: Double
    let routeCoordinates: [RoutePoint]
    let speedHistory: [SpeedPoint]
    var cloudKitRecordID: String?
    var activityType: String        // "driving" (default)

    init(
        id: UUID = UUID(),
        date: Date,
        duration: TimeInterval,
        distance: Double,
        maxSpeed: Double,
        avgSpeed: Double,
        startLatitude: Double,
        startLongitude: Double,
        endLatitude: Double,
        endLongitude: Double,
        routeCoordinates: [RoutePoint],
        speedHistory: [SpeedPoint],
        cloudKitRecordID: String? = nil,
        activityType: String = "driving"
    ) {
        self.id = id
        self.date = date
        self.duration = duration
        self.distance = distance
        self.maxSpeed = maxSpeed
        self.avgSpeed = avgSpeed
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.endLatitude = endLatitude
        self.endLongitude = endLongitude
        self.routeCoordinates = routeCoordinates
        self.speedHistory = speedHistory
        self.cloudKitRecordID = cloudKitRecordID
        self.activityType = activityType
    }

    var startCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: startLatitude, longitude: startLongitude)
    }

    var endCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: endLatitude, longitude: endLongitude)
    }

    var distanceFormatted: String {
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        }
        return String(format: "%.0f m", distance)
    }

    var durationFormatted: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return String(format: "%dh %02dm", hours, mins)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    func maxSpeedConverted(_ unit: AppConstants.SpeedUnit) -> Double {
        maxSpeed * unit.conversionFromMPS
    }

    func avgSpeedConverted(_ unit: AppConstants.SpeedUnit) -> Double {
        avgSpeed * unit.conversionFromMPS
    }
}

struct RoutePoint: Codable, Hashable {
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct SpeedPoint: Codable, Hashable {
    let timestamp: Date
    let speed: Double // m/s
}
