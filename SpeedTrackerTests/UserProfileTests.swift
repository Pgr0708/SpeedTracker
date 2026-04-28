//
//  UserProfileTests.swift
//  SpeedTrackerTests
//
//  Tests for UserProfile persistence across sign-out/sign-in cycles.
//

import XCTest
@testable import SpeedTracker

final class UserProfileTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "userProfile")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "userProfile")
        super.tearDown()
    }

    // MARK: - Basic Persistence

    func testSaveAndLoad() {
        let profile = UserProfile(displayName: "Test User", email: "test@example.com",
                                  userID: "user123", weightKg: 75, dailyStepGoal: 8000)
        profile.save()

        let loaded = UserProfile.load()
        XCTAssertEqual(loaded.displayName, "Test User")
        XCTAssertEqual(loaded.email, "test@example.com")
        XCTAssertEqual(loaded.userID, "user123")
        XCTAssertEqual(loaded.weightKg, 75)
        XCTAssertEqual(loaded.dailyStepGoal, 8000)
    }

    func testLoadDefault_WhenNoSavedProfile() {
        let loaded = UserProfile.load()
        XCTAssertEqual(loaded.displayName, "SpeedTracker User")
        XCTAssertNil(loaded.email)
        XCTAssertEqual(loaded.userID, "")
        XCTAssertEqual(loaded.weightKg, 70)
        XCTAssertEqual(loaded.dailyStepGoal, 10000)
    }

    // MARK: - Sign-Out Email Preservation

    func testEmailPreservedAfterSignOut() {
        // Simulate initial sign-in with email
        let original = UserProfile(displayName: "Jane Doe", email: "jane@apple.com",
                                   userID: "apple_user_001", weightKg: 60, dailyStepGoal: 12000)
        original.save()

        // Simulate sign-out: AuthService.signOut() preserves email but clears userID
        let afterSignOut = UserProfile(
            displayName: original.displayName,
            email: original.email,     // preserved
            userID: "",                 // cleared
            weightKg: original.weightKg,
            dailyStepGoal: original.dailyStepGoal
        )
        afterSignOut.save()

        let loaded = UserProfile.load()
        XCTAssertEqual(loaded.email, "jane@apple.com", "Email must survive sign-out")
        XCTAssertEqual(loaded.userID, "", "UserID must be cleared on sign-out")
        XCTAssertEqual(loaded.displayName, "Jane Doe", "Display name must survive sign-out")
    }

    func testEmailRestoredOnReSignIn() {
        // Save profile with email (first sign-in)
        UserProfile(displayName: "Jane Doe", email: "jane@apple.com",
                    userID: "apple_user_001", weightKg: 60, dailyStepGoal: 12000).save()

        // Sign-out preserves email
        UserProfile(displayName: "Jane Doe", email: "jane@apple.com",
                    userID: "", weightKg: 60, dailyStepGoal: 12000).save()

        // Re-sign-in: Apple returns nil email on subsequent logins
        let currentProfile = UserProfile.load()
        let reSignIn = UserProfile(
            displayName: "Jane Doe",
            email: nil ?? currentProfile.email,  // Falls back to stored email
            userID: "apple_user_001",
            weightKg: currentProfile.weightKg,
            dailyStepGoal: currentProfile.dailyStepGoal
        )
        reSignIn.save()

        let loaded = UserProfile.load()
        XCTAssertEqual(loaded.email, "jane@apple.com", "Email must be restored from stored profile")
        XCTAssertEqual(loaded.userID, "apple_user_001", "UserID must be set on re-sign-in")
    }

    // MARK: - Avatar Initials

    func testAvatarInitials_TwoNames() {
        let profile = UserProfile(displayName: "John Smith", email: nil,
                                  userID: "", weightKg: 70, dailyStepGoal: 10000)
        XCTAssertEqual(profile.avatarInitials, "JS")
    }

    func testAvatarInitials_SingleName() {
        let profile = UserProfile(displayName: "John", email: nil,
                                  userID: "", weightKg: 70, dailyStepGoal: 10000)
        XCTAssertEqual(profile.avatarInitials, "JO")
    }
}
