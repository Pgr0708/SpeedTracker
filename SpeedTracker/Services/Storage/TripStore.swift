//
//  TripStore.swift
//  SpeedTracker
//
//  Persists trip records using JSON/FileManager
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
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }
    
    private init() {
        loadTrips()
    }
    
    func saveTrip(_ trip: TripRecord) {
        trips.insert(trip, at: 0)
        persistTrips()
    }
    
    func deleteTrip(_ trip: TripRecord) {
        trips.removeAll { $0.id == trip.id }
        persistTrips()
    }
    
    func deleteTrips(at offsets: IndexSet) {
        trips.remove(atOffsets: offsets)
        persistTrips()
    }
    
    // MARK: - Computed Stats
    var totalTrips: Int { trips.count }
    
    var totalDistance: Double {
        trips.reduce(0) { $0 + $1.distance }
    }
    
    var totalDuration: TimeInterval {
        trips.reduce(0) { $0 + $1.duration }
    }
    
    var overallMaxSpeed: Double {
        trips.map(\.maxSpeed).max() ?? 0
    }
    
    // MARK: - Persistence
    private func loadTrips() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: fileURL)
            trips = try JSONDecoder().decode([TripRecord].self, from: data)
        } catch {
            print("Failed to load trips: \(error)")
        }
    }
    
    private func persistTrips() {
        do {
            let data = try JSONEncoder().encode(trips)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save trips: \(error)")
        }
    }
}
