//
//  CloudKitService.swift
//  SpeedTracker
//
//  iCloud/CloudKit sync for trips, pedometer sessions, and preferences.
//  Requires iCloud + CloudKit capability (see SpeedTracker.entitlements).
//
import Foundation
import CloudKit
import SwiftUI
import Combine

@MainActor
class CloudKitService: ObservableObject {
    static let shared = CloudKitService()

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?

    private let container = CKContainer(identifier: AppConstants.CloudKit.containerID)
    private var privateDB: CKDatabase { container.privateCloudDatabase }

    private init() {}

    // MARK: - Sync All (call on launch, foreground, after save)
    func syncAll(tripStore: TripStore, pedometerService: PedometerService) {
        guard !isSyncing else { return }
        Task {
            await performSync(tripStore: tripStore, pedometerService: pedometerService)
        }
    }

    private func performSync(tripStore: TripStore, pedometerService: PedometerService) async {
        isSyncing = true
        syncError = nil
        defer { isSyncing = false }

        do {
            try await syncPreferences()
            try await uploadPendingTrips(tripStore: tripStore)
            try await fetchRemoteTrips(tripStore: tripStore)
            try await uploadPendingPedometerSessions(pedometerService: pedometerService)
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: AppConstants.UserDefaultsKeys.lastCloudKitSync)
        } catch {
            syncError = error.localizedDescription
        }
    }

    // MARK: - Preferences Sync
    func syncPreferences() async throws {
        let recordID = CKRecord.ID(recordName: "UserPreferences")
        let record: CKRecord
        do {
            record = try await privateDB.record(for: recordID)
        } catch {
            record = CKRecord(recordType: AppConstants.CloudKit.userPreferencesType, recordID: recordID)
        }

        let unit = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.preferredSpeedUnit) ?? "km/h"
        let theme = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.themeColor) ?? "blue"
        let maxLimit = UserDefaults.standard.double(forKey: AppConstants.UserDefaultsKeys.maxSpeedLimit)
        let minLimit = UserDefaults.standard.double(forKey: AppConstants.UserDefaultsKeys.minSpeedLimit)

        // Compare with remote and take newer
        let remoteModified = record.modificationDate ?? .distantPast
        let localModified = UserDefaults.standard.object(forKey: "prefsLocalModified") as? Date ?? Date()

        if localModified > remoteModified {
            // Push local to cloud
            record["speedUnit"] = unit as CKRecordValue
            record["themeColor"] = theme as CKRecordValue
            record["maxSpeedLimit"] = maxLimit as CKRecordValue
            record["minSpeedLimit"] = minLimit as CKRecordValue
            _ = try await privateDB.save(record)
        } else {
            // Pull remote to local
            if let remoteUnit = record["speedUnit"] as? String {
                UserDefaults.standard.set(remoteUnit, forKey: AppConstants.UserDefaultsKeys.preferredSpeedUnit)
            }
            if let remoteTheme = record["themeColor"] as? String {
                UserDefaults.standard.set(remoteTheme, forKey: AppConstants.UserDefaultsKeys.themeColor)
            }
        }
    }

    // MARK: - Trip Sync
    private func uploadPendingTrips(tripStore: TripStore) async throws {
        let unsynced = tripStore.trips.filter { $0.cloudKitRecordID == nil }
        for trip in unsynced {
            let record = CKRecord(recordType: AppConstants.CloudKit.tripRecordType)
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(trip) {
                record["tripData"] = data as CKRecordValue
                record["date"] = trip.date as CKRecordValue
                record["tripID"] = trip.id.uuidString as CKRecordValue
                let saved = try await privateDB.save(record)
                // Update local trip with cloudKitRecordID
                if let idx = tripStore.trips.firstIndex(where: { $0.id == trip.id }) {
                    var updated = tripStore.trips[idx]
                    updated = TripRecord(
                        id: updated.id, date: updated.date, duration: updated.duration,
                        distance: updated.distance, maxSpeed: updated.maxSpeed, avgSpeed: updated.avgSpeed,
                        startLatitude: updated.startLatitude, startLongitude: updated.startLongitude,
                        endLatitude: updated.endLatitude, endLongitude: updated.endLongitude,
                        routeCoordinates: updated.routeCoordinates, speedHistory: updated.speedHistory,
                        cloudKitRecordID: saved.recordID.recordName, activityType: updated.activityType
                    )
                    tripStore.trips[idx] = updated
                }
            }
        }
        if !unsynced.isEmpty { tripStore.persist() }
    }

    private func fetchRemoteTrips(tripStore: TripStore) async throws {
        let query = CKQuery(recordType: AppConstants.CloudKit.tripRecordType,
                           predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let (results, _) = try await privateDB.records(matching: query, resultsLimit: 200)
        let decoder = JSONDecoder()
        let localIDs = Set(tripStore.trips.map { $0.id.uuidString })
        for (_, result) in results {
            if case .success(let record) = result,
               let data = record["tripData"] as? Data,
               let tripID = record["tripID"] as? String,
               !localIDs.contains(tripID),
               var trip = try? decoder.decode(TripRecord.self, from: data) {
                trip = TripRecord(
                    id: trip.id, date: trip.date, duration: trip.duration,
                    distance: trip.distance, maxSpeed: trip.maxSpeed, avgSpeed: trip.avgSpeed,
                    startLatitude: trip.startLatitude, startLongitude: trip.startLongitude,
                    endLatitude: trip.endLatitude, endLongitude: trip.endLongitude,
                    routeCoordinates: trip.routeCoordinates, speedHistory: trip.speedHistory,
                    cloudKitRecordID: record.recordID.recordName, activityType: trip.activityType
                )
                tripStore.trips.append(trip)
            }
        }
        tripStore.trips.sort { $0.date > $1.date }
        tripStore.persist()
    }

    private func uploadPendingPedometerSessions(pedometerService: PedometerService) async throws {
        let unsynced = pedometerService.sessions.filter { $0.cloudKitRecordID == nil }
        for session in unsynced {
            let record = CKRecord(recordType: AppConstants.CloudKit.pedometerSessionType)
            if let data = try? JSONEncoder().encode(session) {
                record["sessionData"] = data as CKRecordValue
                record["date"] = session.date as CKRecordValue
                _ = try await privateDB.save(record)
            }
        }
    }
}
