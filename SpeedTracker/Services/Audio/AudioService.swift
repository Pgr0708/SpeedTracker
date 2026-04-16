//
//  AudioService.swift
//  SpeedTracker
//
import Foundation
import AVFoundation
import AudioToolbox
import SwiftUI
import Combine

@MainActor
class AudioService: ObservableObject {
    static let shared = AudioService()

    @AppStorage(AppConstants.UserDefaultsKeys.isSoundMuted) var isMuted = false

    private var lastMaxAlertTime: Date?
    private var lastMinAlertTime: Date?
    private let cooldown: TimeInterval = 10

    private init() {}

    func playMaxSpeedAlert() {
        guard !isMuted else { return }
        guard canPlayMaxAlert() else { return }
        lastMaxAlertTime = Date()
        playBeeps(count: 3, interval: 0.15, systemSound: 1052)
    }

    func playMinSpeedAlert() {
        guard !isMuted else { return }
        guard canPlayMinAlert() else { return }
        lastMinAlertTime = Date()
        playBeeps(count: 2, interval: 0.2, systemSound: 1057)
    }

    func toggleMute() {
        isMuted.toggle()
        HapticManager.shared.selection()
    }

    private func canPlayMaxAlert() -> Bool {
        guard let last = lastMaxAlertTime else { return true }
        return Date().timeIntervalSince(last) > cooldown
    }

    private func canPlayMinAlert() -> Bool {
        guard let last = lastMinAlertTime else { return true }
        return Date().timeIntervalSince(last) > cooldown
    }

    private func playBeeps(count: Int, interval: TimeInterval, systemSound: SystemSoundID) {
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                AudioServicesPlaySystemSound(systemSound)
            }
        }
    }
}
