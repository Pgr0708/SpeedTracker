//
//  PedometerService.swift
//  SpeedTracker
//
import Foundation
import CoreMotion
import SwiftUI
import Combine

@MainActor
class PedometerService: ObservableObject {
    static let shared = PedometerService()

    @Published var steps: Int = 0
    @Published var distance: Double = 0        // meters
    @Published var calories: Double = 0
    @Published var currentPace: Double = 0     // min/km
    @Published var avgSpeed: Double = 0        // m/s
    @Published var isTracking = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var sessions: [PedometerSession] = []

    @AppStorage("pedometerWeightKg") private var weightKg: Double = 70
    @AppStorage("pedometerDailyGoal") private var dailyGoal: Int = 10000

    private let pedometer = CMPedometer()
    private let activityManager = CMMotionActivityManager()
    private var startDate: Date?
    private var elapsedTimer: Timer?
    private var currentActivity: String = "walking"

    private init() { loadSessions() }

    var goalProgress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(Double(steps) / Double(dailyGoal), 1.0)
    }

    var goalSteps: Int { dailyGoal }

    // MARK: - Tracking
    func startTracking() {
        let authStatus = CMPedometer.authorizationStatus()
        guard authStatus != .denied && authStatus != .restricted else { return }
        steps = 0; distance = 0; calories = 0; currentPace = 0; avgSpeed = 0; elapsedTime = 0
        startDate = Date()
        isTracking = true

        pedometer.startUpdates(from: startDate!) { [weak self] data, error in
            guard let data, error == nil else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.steps = data.numberOfSteps.intValue
                self.distance = data.distance?.doubleValue ?? 0
                self.calories = Double(self.steps) * 0.04 * (self.weightKg / 70.0)
                if let pace = data.currentPace?.doubleValue, pace > 0 {
                    self.currentPace = (1.0 / pace) / 60.0 * 1000.0 // convert to min/km
                }
                if let cadence = data.currentCadence?.doubleValue {
                    self.avgSpeed = cadence * (data.distance?.doubleValue ?? 0) / max(1, Double(data.numberOfSteps.intValue))
                }
            }
        }

        if CMMotionActivityManager.isActivityAvailable() {
            activityManager.startActivityUpdates(to: .main) { [weak self] activity in
                guard let activity else { return }
                Task { @MainActor [weak self] in
                    if activity.running { self?.currentActivity = "running" }
                    else if activity.walking { self?.currentActivity = "walking" }
                }
            }
        }

        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let start = self.startDate else { return }
                self.elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }

    func stopTracking() -> PedometerSession? {
        isTracking = false
        pedometer.stopUpdates()
        activityManager.stopActivityUpdates()
        elapsedTimer?.invalidate()
        elapsedTimer = nil
        guard let start = startDate, elapsedTime > 0 else { return nil }

        let pace: Double
        if distance > 0 && elapsedTime > 0 {
            pace = (elapsedTime / 60.0) / (distance / 1000.0)
        } else { pace = 0 }

        let speed = distance > 0 && elapsedTime > 0 ? distance / elapsedTime : 0

        let session = PedometerSession(
            id: UUID(), date: start, duration: elapsedTime,
            steps: steps, distance: distance, calories: calories,
            avgPace: pace, avgSpeed: speed,
            goalSteps: dailyGoal, goalAchieved: steps >= dailyGoal,
            activityType: currentActivity
        )
        return session
    }

    func saveSession(_ session: PedometerSession) {
        sessions.insert(session, at: 0)
        persistSessions()
        CloudKitService.shared.syncAll(tripStore: TripStore.shared, pedometerService: self)
    }

    // MARK: - Persistence
    private func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.UserDefaultsKeys.pedometerSessions),
              let loaded = try? JSONDecoder().decode([PedometerSession].self, from: data) else { return }
        sessions = loaded
    }

    func persistSessions() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: AppConstants.UserDefaultsKeys.pedometerSessions)
        }
    }

    func deleteSession(_ session: PedometerSession) {
        sessions.removeAll { $0.id == session.id }
        persistSessions()
    }

    func clearAllSessions() {
        sessions.removeAll()
        persistSessions()
    }
}
