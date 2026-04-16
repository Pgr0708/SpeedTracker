//
//  NotificationManager.swift
//  SpeedTracker
//
import Foundation
import UserNotifications
import SwiftUI
import Combine

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private var lastMaxAlertDate: Date?
    private var lastMinAlertDate: Date?
    private let cooldown: TimeInterval = 30

    private init() { Task { await checkStatus() } }

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            await checkStatus()
        } catch { print("Notification permission error: \(error)") }
    }

    func checkStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func scheduleMaxSpeedAlert(speed: Double, limit: Double, unit: AppConstants.SpeedUnit) {
        guard isAuthorized else { return }
        if let last = lastMaxAlertDate, Date().timeIntervalSince(last) < cooldown { return }
        lastMaxAlertDate = Date()
        let speedStr = String(format: "%.0f %@", speed, unit.rawValue)
        let limitStr = String(format: "%.0f %@", limit, unit.rawValue)
        schedule(id: "maxSpeed", title: "⚠️ Speed Alert", body: "You exceeded \(limitStr). Current: \(speedStr)")
    }

    func scheduleMinSpeedAlert(speed: Double, limit: Double, unit: AppConstants.SpeedUnit) {
        guard isAuthorized else { return }
        if let last = lastMinAlertDate, Date().timeIntervalSince(last) < cooldown { return }
        lastMinAlertDate = Date()
        let speedStr = String(format: "%.0f %@", speed, unit.rawValue)
        schedule(id: "minSpeed", title: "🐢 Speed Alert", body: "Speed dropped below \(speedStr)")
    }

    private func schedule(id: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title; content.body = body; content.sound = .default
        let request = UNNotificationRequest(identifier: id + UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
