//
//  UserProfile.swift
//  SpeedTracker
//
//  Apple ID-backed user profile stored in UserDefaults/iCloud KV
//

import Foundation

struct UserProfile: Codable {
    var displayName: String
    var email: String?
    var userID: String           // Apple credential user identifier
    var weightKg: Double         // for calorie calculation, default 70
    var dailyStepGoal: Int       // default 10000

    var avatarInitials: String {
        let parts = displayName.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1)) + String(parts[1].prefix(1))
        }
        return String(displayName.prefix(2)).uppercased()
    }

    static var `default`: UserProfile {
        UserProfile(
            displayName: "SpeedTracker User",
            email: nil,
            userID: "",
            weightKg: 70,
            dailyStepGoal: 10000
        )
    }

    // MARK: - Persistence (UserDefaults)
    static func load() -> UserProfile {
        guard let data = UserDefaults.standard.data(forKey: "userProfile"),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return .default
        }
        return profile
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "userProfile")
        }
    }
}
