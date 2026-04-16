//
//  TripStore.swift
//  SpeedTracker
//
import Foundation
import Combine
import SwiftUI

@MainActor
class TripStore: ObservableObject {
    static let shared = TripStore()
    @Published var trips: [TripRecord] = []
    private let fileName = "trips.json"
    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
    }
    private init() { loadTrips() }

    func saveTrip(_ trip: TripRecord) {
        trips.insert(trip, at: 0)
        persist()
        // Trigger CloudKit sync if premium
        if UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.isPremium) {
            Task { try? await CloudKitService.shared.syncPreferences() }
        }
    }

    func deleteTrip(_ trip: TripRecord) { trips.removeAll { $0.id == trip.id }; persist() }
    func deleteTrips(at offsets: IndexSet) { trips.remove(atOffsets: offsets); persist() }

    var totalTrips: Int { trips.count }
    var totalDistance: Double { trips.reduce(0) { $0 + $1.distance } }
    var totalDuration: TimeInterval { trips.reduce(0) { $0 + $1.duration } }
    var overallMaxSpeed: Double { trips.map(\.maxSpeed).max() ?? 0 }

    private func loadTrips() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([TripRecord].self, from: data) {
            trips = decoded
        }
    }

    func persist() {
        if let data = try? JSONEncoder().encode(trips) {
            try? data.write(to: fileURL)
        }
    }
}
