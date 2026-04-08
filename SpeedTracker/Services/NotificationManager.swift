//
//  NotificationManager.swift
//  SpeedTracker
//
//  Push notification permission manager
//

import Foundation
import UserNotifications
import Combine

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private init() {
        Task {
            await checkStatus()
        }
    }
    
    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            await checkStatus()
        } catch {
            print("Notification permission error: \(error)")
        }
    }
    
    func checkStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }
    
    func scheduleSpeedAlert(speed: Double, limit: Double) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Speed Alert"
        content.body = "You've exceeded your speed limit of \(Int(limit)). Current: \(Int(speed))"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // immediate
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
