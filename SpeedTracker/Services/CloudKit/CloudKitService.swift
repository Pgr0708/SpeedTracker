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
import UIKit

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
        guard AuthService.shared.isAuthenticated else {
            syncError = nil
            return
        }
        guard !isSyncing else { return }
        Task {
            await performSync(tripStore: tripStore, pedometerService: pedometerService)
        }
    }

    func syncAllInBackground(tripStore: TripStore, pedometerService: PedometerService) {
        guard AuthService.shared.isAuthenticated else {
            syncError = nil
            return
        }
        guard !isSyncing else { return }

        var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "CloudKitSync") {
            if backgroundTaskID != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                backgroundTaskID = .invalid
            }
        }

        Task {
            await performSync(tripStore: tripStore, pedometerService: pedometerService)
            if backgroundTaskID != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                backgroundTaskID = .invalid
            }
        }
    }

    private func performSync(tripStore: TripStore, pedometerService: PedometerService) async {
        isSyncing = true
        syncError = nil
        defer { isSyncing = false }

        do {
            try await ensureICloudAccountAvailable()
        } catch {
            syncError = error.localizedDescription
            return
        }

        // Preferences sync is non-critical: never let it block trip/pedometer history sync.
        // A schema mismatch on UserPreferences was previously aborting history restore on reinstall.
        do {
            try await syncPreferences()
        } catch {
            #if DEBUG
            print("CloudKit: syncPreferences failed (non-fatal): \(error.localizedDescription)")
            #endif
        }

        if PurchaseService.shared.isPremium && AuthService.shared.isAuthenticated {
            do {
                try await uploadPendingTrips(tripStore: tripStore)
                guard AuthService.shared.isAuthenticated else { return }
                try await fetchRemoteTrips(tripStore: tripStore)
                guard AuthService.shared.isAuthenticated else { return }
                try await uploadPendingPedometerSessions(pedometerService: pedometerService)
                guard AuthService.shared.isAuthenticated else { return }
                try await fetchRemotePedometerSessions(pedometerService: pedometerService)
            } catch {
                syncError = error.localizedDescription
                return
            }
        }

        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate?.timeIntervalSince1970 ?? 0, forKey: AppConstants.UserDefaultsKeys.lastCloudKitSync)
    }

    private func ensureICloudAccountAvailable() async throws {
        let status: CKAccountStatus = try await withCheckedThrowingContinuation { continuation in
            container.accountStatus { status, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: status)
                }
            }
        }

        switch status {
        case .available:
            return
        case .noAccount:
            throw NSError(domain: "CloudKitService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "No iCloud account is available for CloudKit sync."
            ])
        case .couldNotDetermine:
            throw NSError(domain: "CloudKitService", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "CloudKit could not determine the iCloud account status."
            ])
        case .restricted:
            throw NSError(domain: "CloudKitService", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "CloudKit access is restricted on this device."
            ])
        case .temporarilyUnavailable:
            throw NSError(domain: "CloudKitService", code: 4, userInfo: [
                NSLocalizedDescriptionKey: "iCloud is temporarily unavailable."
            ])
        @unknown default:
            throw NSError(domain: "CloudKitService", code: 5, userInfo: [
                NSLocalizedDescriptionKey: "CloudKit is unavailable."
            ])
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
        // Use a date-based predicate (not NSPredicate(value:true)) so CloudKit uses the
        // queryable "date" index instead of requiring recordName to be marked Queryable.
        let query = CKQuery(recordType: AppConstants.CloudKit.tripRecordType,
                           predicate: NSPredicate(format: "date >= %@", Date.distantPast as NSDate))
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
                record["sessionID"] = session.id.uuidString as CKRecordValue
                let saved = try await privateDB.save(record)

                if let idx = pedometerService.sessions.firstIndex(where: { $0.id == session.id }) {
                    var updated = pedometerService.sessions[idx]
                    updated.cloudKitRecordID = saved.recordID.recordName
                    pedometerService.sessions[idx] = updated
                }
            }
        }

        if !unsynced.isEmpty {
            pedometerService.persistSessions()
        }
    }

    private func fetchRemotePedometerSessions(pedometerService: PedometerService) async throws {
        let query = CKQuery(
            recordType: AppConstants.CloudKit.pedometerSessionType,
            predicate: NSPredicate(format: "date >= %@", Date.distantPast as NSDate)
        )
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        let (results, _) = try await privateDB.records(matching: query, resultsLimit: 200)
        let decoder = JSONDecoder()
        let localIDs = Set(pedometerService.sessions.map { $0.id.uuidString })

        for (_, result) in results {
            if case .success(let record) = result,
               let data = record["sessionData"] as? Data,
               let sessionID = record["sessionID"] as? String,
               !localIDs.contains(sessionID),
               var session = try? decoder.decode(PedometerSession.self, from: data) {
                session.cloudKitRecordID = record.recordID.recordName
                pedometerService.sessions.append(session)
            }
        }

        pedometerService.sessions.sort { $0.date > $1.date }
        pedometerService.persistSessions()
    }
}
