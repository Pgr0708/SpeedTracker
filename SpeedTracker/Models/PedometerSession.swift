//
//  PedometerSession.swift
//  SpeedTracker
//
//  Pedometer workout session data model
//

import Foundation

struct PedometerSession: Codable, Identifiable, Hashable {
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
    var cloudKitRecordID: String?

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
