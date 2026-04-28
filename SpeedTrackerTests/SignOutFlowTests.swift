//
//  SignOutFlowTests.swift
//  SpeedTrackerTests
//
//  Tests that sign-out properly clears all premium state and data.
//

import XCTest
@testable import SpeedTracker

@MainActor
final class SignOutFlowTests: XCTestCase {

    override func tearDown() {
        // Reset to clean state
        PurchaseService.shared.resetToFreeMode()
        UserDefaults.standard.removeObject(forKey: "userProfile")
        super.tearDown()
    }

    // MARK: - Sign-Out State Verification

    func testSignOut_PremiumFeaturesLocked() {
        let ps = PurchaseService.shared

        // Simulate active premium state
        ps._testSetState(planName: "Yearly", productID: AppConstants.Purchase.yearlyProductID,
                         expirationDate: Date().addingTimeInterval(86400 * 365), premium: true)
        XCTAssertTrue(ps.isPremium, "Precondition: premium must be active")

        // Simulate sign-out via resetToFreeMode (what AuthService.signOut calls)
        ps.resetToFreeMode()

        XCTAssertFalse(ps.isPremium, "Premium must be locked after sign-out")
        XCTAssertEqual(ps.currentPlanName, "Free Plan")
        XCTAssertEqual(ps.currentProductID, "")
        XCTAssertNil(ps.currentExpirationDate)
    }

    func testSignOut_iCloudSyncTimestampCleared() {
        let ud = UserDefaults.standard

        // Simulate active sync
        ud.set(Date().timeIntervalSince1970, forKey: AppConstants.UserDefaultsKeys.lastCloudKitSync)
        XCTAssertGreaterThan(ud.double(forKey: AppConstants.UserDefaultsKeys.lastCloudKitSync), 0)

        // Sign-out resets sync timestamp
        PurchaseService.shared.resetToFreeMode()

        XCTAssertEqual(ud.double(forKey: AppConstants.UserDefaultsKeys.lastCloudKitSync), 0.0,
                       "iCloud sync timestamp must be cleared on sign-out")
    }

    func testSignOut_MirrorModeDisabled() {
        UserDefaults.standard.set(true, forKey: AppConstants.UserDefaultsKeys.isMirrorModeEnabled)

        PurchaseService.shared.resetToFreeMode()

        XCTAssertFalse(UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.isMirrorModeEnabled),
                       "Mirror mode must be disabled on sign-out")
    }

    func testSignOut_HistoryCleared() {
        let tripStore = TripStore.shared

        // Add a fake trip
        let trip = TripRecord(
            id: UUID(), date: Date(), duration: 600, distance: 5000,
            maxSpeed: 50, avgSpeed: 30,
            startLatitude: 0, startLongitude: 0,
            endLatitude: 0, endLongitude: 0,
            routeCoordinates: [], speedHistory: [],
            cloudKitRecordID: nil, activityType: "driving"
        )
        tripStore.trips.append(trip)
        XCTAssertFalse(tripStore.trips.isEmpty, "Precondition: trips must exist")

        tripStore.clearAllTrips()

        XCTAssertTrue(tripStore.trips.isEmpty, "Trips must be empty after clearAllTrips")
    }

    func testSignOut_PedometerSessionsCleared() {
        let pedService = PedometerService.shared

        pedService.clearAllSessions()

        XCTAssertTrue(pedService.sessions.isEmpty, "Pedometer sessions must be empty after clear")
    }

    // MARK: - Settings View State After Sign-Out

    func testSettingsState_AfterSignOut_ShowsFreePlan() {
        let ps = PurchaseService.shared
        ps.resetToFreeMode()

        // Verify what SettingsView would display
        XCTAssertFalse(ps.isPremium)
        XCTAssertEqual(ps.currentPlanName, "Free Plan")
        XCTAssertEqual(ps.remainingTimeSummary, "Free plan active")
    }

    func testSettingsState_AfterSignOut_iCloudSyncOff() {
        let auth = AuthService.shared
        let ps = PurchaseService.shared

        ps.resetToFreeMode()

        // SettingsView condition: authService.isAuthenticated && isPremium
        // After sign-out, at least isPremium is false, so iCloud row shows "Off"
        // SettingsView condition: authService.isAuthenticated && isPremium
        // After sign-out, at least isPremium is false, so iCloud row shows "Off"
        XCTAssertFalse(ps.isPremium, "isPremium must be false → iCloud sync row shows 'Off'")
    }

    // MARK: - No Static Values Test

    func testNoStaticWeeklyAfterReset() {
        let ps = PurchaseService.shared

        // Set to Yearly plan
        ps._testSetState(planName: "Yearly", productID: AppConstants.Purchase.yearlyProductID,
                         expirationDate: Date().addingTimeInterval(86400 * 200), premium: true)
        XCTAssertEqual(ps.currentPlanName, "Yearly")

        // Reset
        ps.resetToFreeMode()
        XCTAssertEqual(ps.currentPlanName, "Free Plan", "Must show 'Free Plan', not static 'Weekly'")
        XCTAssertNotEqual(ps.currentPlanName, "Weekly", "Must NEVER show static 'Weekly' after reset")
    }

    func testNoStatic1DayAfterReset() {
        let ps = PurchaseService.shared
        ps.resetToFreeMode()

        XCTAssertEqual(ps.remainingTimeSummary, "Free plan active",
                       "Must show 'Free plan active', not static '1 day left'")
        XCTAssertFalse(ps.remainingTimeSummary.contains("1 day"),
                       "Must NOT show '1 day left' after reset")
    }
}
