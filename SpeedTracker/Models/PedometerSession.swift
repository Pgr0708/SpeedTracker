//
//  PedometerSession.swift
//  SpeedTracker
//
//  Pedometer workout session data model
//

import Foundation
import CoreLocation

struct PedometerSession: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let duration: TimeInterval      // seconds
    let steps: Int
    let distance: Double            // meters
    let calories: Double            // kcal
    let avgPace: Double             // min/km
    let avgSpeed: Double            // m/s
    let goalSteps: Int
    let goalAchieved: Bool
    let activityType: String        // "walking", "running"
    var routeCoordinates: [RoutePoint]
    var cloudKitRecordID: String?

    init(id: UUID, date: Date, duration: TimeInterval, steps: Int, distance: Double,
         calories: Double, avgPace: Double, avgSpeed: Double, goalSteps: Int,
         goalAchieved: Bool, activityType: String, routeCoordinates: [RoutePoint] = [],
         cloudKitRecordID: String? = nil) {
        self.id = id; self.date = date; self.duration = duration
        self.steps = steps; self.distance = distance; self.calories = calories
        self.avgPace = avgPace; self.avgSpeed = avgSpeed; self.goalSteps = goalSteps
        self.goalAchieved = goalAchieved; self.activityType = activityType
        self.routeCoordinates = routeCoordinates; self.cloudKitRecordID = cloudKitRecordID
    }

    var startCoordinate: CLLocationCoordinate2D? { routeCoordinates.first?.coordinate }
    var endCoordinate: CLLocationCoordinate2D? { routeCoordinates.last?.coordinate }

    // MARK: - Computed
    var durationFormatted: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes >= 60 {
            return String(format: "%dh %02dm", minutes / 60, minutes % 60)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    var distanceFormatted: String {
        if distance >= 1000 {
            return String(format: "%.2f km", distance / 1000)
        }
        return String(format: "%.0f m", distance)
    }

    var paceFormatted: String {
        if avgPace <= 0 { return "--" }
        let minutes = Int(avgPace)
        let seconds = Int((avgPace - Double(minutes)) * 60)
        return String(format: "%d'%02d\"", minutes, seconds)
    }

    var caloriesFormatted: String {
        return String(format: "%.0f kcal", calories)
    }
}

extension PedometerSession: Codable {
    enum CodingKeys: String, CodingKey {
        case id, date, duration, steps, distance, calories, avgPace, avgSpeed
        case goalSteps, goalAchieved, activityType, routeCoordinates, cloudKitRecordID
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)
        duration = try c.decode(TimeInterval.self, forKey: .duration)
        steps = try c.decode(Int.self, forKey: .steps)
        distance = try c.decode(Double.self, forKey: .distance)
        calories = try c.decode(Double.self, forKey: .calories)
        avgPace = try c.decode(Double.self, forKey: .avgPace)
        avgSpeed = try c.decode(Double.self, forKey: .avgSpeed)
        goalSteps = try c.decode(Int.self, forKey: .goalSteps)
        goalAchieved = try c.decode(Bool.self, forKey: .goalAchieved)
        activityType = try c.decode(String.self, forKey: .activityType)
        routeCoordinates = (try c.decodeIfPresent([RoutePoint].self, forKey: .routeCoordinates)) ?? []
        cloudKitRecordID = try c.decodeIfPresent(String.self, forKey: .cloudKitRecordID)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(date, forKey: .date)
        try c.encode(duration, forKey: .duration)
        try c.encode(steps, forKey: .steps)
        try c.encode(distance, forKey: .distance)
        try c.encode(calories, forKey: .calories)
        try c.encode(avgPace, forKey: .avgPace)
        try c.encode(avgSpeed, forKey: .avgSpeed)
        try c.encode(goalSteps, forKey: .goalSteps)
        try c.encode(goalAchieved, forKey: .goalAchieved)
        try c.encode(activityType, forKey: .activityType)
        try c.encode(routeCoordinates, forKey: .routeCoordinates)
        try c.encodeIfPresent(cloudKitRecordID, forKey: .cloudKitRecordID)
    }
}
