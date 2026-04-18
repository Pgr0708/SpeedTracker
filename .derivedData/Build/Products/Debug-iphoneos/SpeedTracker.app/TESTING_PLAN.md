# Testing Plan

Comprehensive testing strategy for Speed Tracker covering all features, edge cases, and platforms.

## Testing Philosophy

**Goals**:
1. Ensure core features work reliably
2. Catch edge cases before users do
3. Verify subscription flows work correctly
4. Ensure data integrity (no data loss)
5. Validate cross-device sync
6. Confirm app passes App Review

**Test Pyramid**:
- **Unit Tests** (60%): Individual functions and utilities
- **Integration Tests** (30%): Feature workflows
- **UI Tests** (10%): Critical user journeys
- **Manual Testing**: Real-world scenarios

---

## 1. Unit Testing

### Location & Speed Utilities

**Test: Speed Conversion**
```swift
func testSpeedConversion() {
    let metersPerSecond = 30.0 // ~67 mph
    
    let mph = SpeedUnit.mph.convert(speedInMetersPerSecond: metersPerSecond)
    XCTAssertEqual(mph, 67.1, accuracy: 0.1)
    
    let kmh = SpeedUnit.kmh.convert(speedInMetersPerSecond: metersPerSecond)
    XCTAssertEqual(kmh, 108.0, accuracy: 0.1)
}
```

**Test: Distance Conversion**
```swift
func testDistanceConversion() {
    let meters = 10000.0 // 10 km
    
    let miles = DistanceUnit.miles.convert(distanceInMeters: meters)
    XCTAssertEqual(miles, 6.214, accuracy: 0.01)
    
    let km = DistanceUnit.km.convert(distanceInMeters: meters)
    XCTAssertEqual(km, 10.0, accuracy: 0.01)
}
```

**Test: GPS Accuracy Filtering**
```swift
func testLocationFiltering() {
    let goodLocation = CLLocation(
        latitude: 37.7749,
        longitude: -122.4194,
        altitude: 0,
        horizontalAccuracy: 10,
        verticalAccuracy: 10,
        timestamp: Date()
    )
    
    let badLocation = CLLocation(
        latitude: 37.7749,
        longitude: -122.4194,
        altitude: 0,
        horizontalAccuracy: 100, // Too inaccurate
        verticalAccuracy: 10,
        timestamp: Date()
    )
    
    XCTAssertTrue(shouldUseLocation(goodLocation))
    XCTAssertFalse(shouldUseLocation(badLocation))
}
```

### Data Model Validation

**Test: Trip Validation**
```swift
func testTripValidation() {
    let validTrip = Trip(userID: "test", startDate: Date())
    validTrip.endDate = Date().addingTimeInterval(300) // 5 minutes
    validTrip.duration = 300
    validTrip.distance = 5000 // 5 km
    validTrip.averageSpeed = 16.67 // ~60 km/h
    
    XCTAssertTrue(validTrip.isValid)
    
    let invalidTrip = Trip(userID: "test", startDate: Date())
    invalidTrip.duration = 60 // Only 1 minute (min is 2 minutes)
    
    XCTAssertFalse(invalidTrip.isValid)
}
```

**Test: Data Compression**
```swift
func testCoordinateCompression() {
    let coordinates = [
        CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4195),
        // ... 100 more coordinates
    ]
    
    let compressed = compressCoordinates(coordinates)
    let decompressed = decompressCoordinates(compressed)
    
    XCTAssertEqual(decompressed.count, coordinates.count)
    XCTAssertEqual(decompressed[0].latitude, coordinates[0].latitude, accuracy: 0.0001)
}
```

### User Preferences

**Test: Default Preferences**
```swift
func testDefaultPreferences() {
    let prefs = UserPreferences(userID: "test")
    
    // Should use system locale
    if Locale.current.usesMetricSystem {
        XCTAssertEqual(prefs.speedUnit, "kmh")
        XCTAssertEqual(prefs.distanceUnit, "km")
    } else {
        XCTAssertEqual(prefs.speedUnit, "mph")
        XCTAssertEqual(prefs.distanceUnit, "miles")
    }
    
    XCTAssertTrue(prefs.speedAlertsEnabled)
    XCTAssertFalse(prefs.mirrorMode)
}
```

---

## 2. Integration Testing

### Trip Recording Flow

**Test: Auto-Start Trip**
```swift
func testTripAutoStart() async {
    let recorder = TripRecorder()
    
    // Simulate location updates
    let location1 = mockLocation(speed: 0) // Stationary
    recorder.locationDidUpdate(location: location1)
    
    XCTAssertFalse(recorder.isRecording)
    
    let location2 = mockLocation(speed: 15) // 15 m/s (33 mph)
    recorder.locationDidUpdate(location: location2)
    
    XCTAssertTrue(recorder.isRecording)
}
```

**Test: Auto-End Trip**
```swift
func testTripAutoEnd() async {
    let recorder = TripRecorder()
    
    // Start trip
    let movingLocation = mockLocation(speed: 15)
    recorder.locationDidUpdate(location: movingLocation)
    
    XCTAssertTrue(recorder.isRecording)
    
    // Stop moving
    let stoppedLocation = mockLocation(speed: 0)
    recorder.locationDidUpdate(location: stoppedLocation)
    
    // Wait 5 minutes
    try await Task.sleep(nanoseconds: 300_000_000_000) // 5 minutes in nanoseconds
    
    recorder.checkForSessionEnd()
    
    XCTAssertFalse(recorder.isRecording)
}
```

### iCloud Sync

**Test: Preference Sync**
```swift
func testPreferenceSync() async throws {
    let prefs = UserPreferences(userID: "test")
    prefs.speedUnit = "kmh"
    prefs.maxSpeedLimit = 120.0
    
    // Save to CloudKit
    try await CloudKitManager.shared.savePreferences(prefs)
    
    // Fetch from CloudKit
    let fetched = try await CloudKitManager.shared.fetchPreferences(for: "test")
    
    XCTAssertNotNil(fetched)
    XCTAssertEqual(fetched?.speedUnit, "kmh")
    XCTAssertEqual(fetched?.maxSpeedLimit, 120.0)
}
```

**Test: Conflict Resolution**
```swift
func testConflictResolution() {
    let client = mockRecord(modifiedAt: Date())
    let server = mockRecord(modifiedAt: Date().addingTimeInterval(-60)) // 1 min older
    
    let winner = resolveConflict(client: client, server: server)
    
    XCTAssertEqual(winner, client) // Newer wins
}
```

### RevenueCat Integration

**Test: Subscription Status Check**
```swift
func testSubscriptionStatus() async throws {
    // Mock RevenueCat response
    let mockCustomerInfo = mockCustomerInfo(premium: true)
    
    let isPremium = checkPremiumStatus(customerInfo: mockCustomerInfo)
    
    XCTAssertTrue(isPremium)
}
```

**Test: Restore Purchases**
```swift
func testRestorePurchases() async throws {
    // Mock restore flow
    let restored = try await mockRestorePurchases()
    
    XCTAssertTrue(restored.isPremium)
    XCTAssertNotNil(restored.expirationDate)
}
```

---

## 3. UI Testing

### Onboarding Flow

**Test: Complete Onboarding**
```swift
func testOnboardingFlow() throws {
    let app = XCUIApplication()
    app.launch()
    
    // Splash screen
    XCTAssertTrue(app.staticTexts["Track Your Journey"].waitForExistence(timeout: 5))
    
    // Language selection
    XCTAssertTrue(app.buttons["English"].waitForExistence(timeout: 2))
    app.buttons["English"].tap()
    app.buttons["Continue"].tap()
    
    // Onboarding screens
    XCTAssertTrue(app.staticTexts["Real-Time Speed Tracking"].exists)
    app.buttons["Next"].tap()
    
    XCTAssertTrue(app.staticTexts["Review Your Trips"].exists)
    app.buttons["Next"].tap()
    
    XCTAssertTrue(app.staticTexts["HUD Mode for Safe Driving"].exists)
    app.buttons["Next"].tap()
    
    XCTAssertTrue(app.staticTexts["Track Walking & Running"].exists)
    app.buttons["Get Started"].tap()
    
    // Paywall
    XCTAssertTrue(app.staticTexts["Unlock Premium Features"].waitForExistence(timeout: 2))
    app.buttons["Close"].tap()
    
    // Sign in
    XCTAssertTrue(app.buttons["Sign in with Apple"].waitForExistence(timeout: 2))
}
```

### Speed Tracking

**Test: Speed Display Updates**
```swift
func testSpeedDisplayUpdate() throws {
    let app = XCUIApplication()
    app.launch()
    
    // Navigate to home screen (after onboarding)
    navigateToHome(app)
    
    // Check speed display exists
    XCTAssertTrue(app.staticTexts["0"].exists) // Initial speed
    XCTAssertTrue(app.staticTexts["mph"].exists) // Unit label
    
    // Simulate movement (in simulator, use mock data)
    // Speed should update
}
```

### History Screen

**Test: View Trip History**
```swift
func testViewTripHistory() throws {
    let app = XCUIApplication()
    app.launch()
    
    navigateToHome(app)
    
    // Tap History tab
    app.tabBars.buttons["History"].tap()
    
    // Check for trips or empty state
    if app.staticTexts["No Trips Yet"].exists {
        XCTAssertTrue(true) // Empty state shown correctly
    } else {
        // Tap first trip
        app.tables.cells.element(boundBy: 0).tap()
        
        // Verify trip detail shown
        XCTAssertTrue(app.staticTexts["Duration"].exists)
        XCTAssertTrue(app.staticTexts["Distance"].exists)
    }
}
```

### Settings

**Test: Change Language**
```swift
func testChangeLanguage() throws {
    let app = XCUIApplication()
    app.launch()
    
    navigateToHome(app)
    
    app.tabBars.buttons["Settings"].tap()
    
    app.cells["Language"].tap()
    
    app.buttons["Español"].tap()
    
    // Confirm change
    app.alerts.buttons["Change Language"].tap()
    
    // App should restart in Spanish
    XCTAssertTrue(app.staticTexts["Configuración"].waitForExistence(timeout: 5))
}
```

**Test: Set Speed Limit Alert**
```swift
func testSetSpeedAlert() throws {
    let app = XCUIApplication()
    app.launch()
    
    navigateToHome(app)
    
    app.tabBars.buttons["Settings"].tap()
    app.cells["Speed Alerts"].tap()
    
    // Enable alerts
    app.switches["Enable Speed Alerts"].tap()
    
    // Set max speed
    let maxSpeedField = app.textFields["Maximum Speed"]
    maxSpeedField.tap()
    maxSpeedField.typeText("70")
    
    // Go back
    app.navigationBars.buttons.element(boundBy: 0).tap()
    
    // Verify saved
    XCTAssertTrue(app.cells["Speed Alerts"].staticTexts["70 mph"].exists)
}
```

---

## 4. Manual Testing Scenarios

### Real-World Trip Testing

**Test Drive 1: Short Urban Trip**
- **Route**: 2-3 miles around neighborhood
- **Speed**: Varying 0-40 mph
- **Stops**: Multiple (stop signs, lights)
- **Verify**:
  - Trip auto-starts when moving
  - Speed updates smoothly
  - Trip auto-ends after 5 min stopped
  - Route recorded accurately
  - Starting/ending addresses correct
  - Distance matches odometer

**Test Drive 2: Highway Trip**
- **Route**: 20+ miles highway
- **Speed**: Constant 60-70 mph
- **Stops**: Minimal
- **Verify**:
  - Max speed captured correctly
  - Average speed calculated correctly
  - GPS doesn't drop signal
  - Battery drain acceptable
  - Trip summary accurate

**Test Drive 3: GPS Challenging Route**
- **Route**: Urban canyon, tunnel, parking garage
- **Speed**: Varying
- **Challenges**: GPS signal loss
- **Verify**:
  - App handles GPS loss gracefully
  - Shows "GPS signal lost" indicator
  - Trip resumes after tunnel
  - No app crash
  - Trip data saved correctly

### Pedometer Testing

**Test Walk 1: Casual Walk**
- **Distance**: 1 mile
- **Duration**: 20 minutes
- **Verify**:
  - Step count reasonable (±5%)
  - Distance matches GPS distance
  - Calories calculated
  - Session saved to history

**Test Walk 2: Running**
- **Distance**: 3 miles
- **Duration**: 30 minutes
- **Verify**:
  - Higher step frequency detected
  - Pace calculated correctly
  - Calorie burn higher than walking

### Multi-Device Testing

**Test: Cross-Device Sync**
- **Devices**: iPhone + iPad (same Apple ID)
- **Steps**:
  1. Record trip on iPhone
  2. Wait for sync (or trigger manually)
  3. Open app on iPad
  4. Verify trip appears
  5. Change preference on iPad
  6. Verify change syncs to iPhone

### Subscription Testing

**Test: Purchase Flow (Sandbox)**
- **Account**: Sandbox test account
- **Steps**:
  1. Launch app as free user
  2. Tap premium feature (HUD mode)
  3. Paywall appears
  4. Select yearly plan
  5. Tap "Start Free Trial"
  6. Authenticate with Face ID
  7. Verify purchase completes
  8. Verify premium unlocked immediately
  9. Verify trial duration shown in settings
  10. Close and reopen app → still premium

**Test: Restore Purchases**
- **Scenario**: User deleted app and reinstalled
- **Steps**:
  1. Install app fresh (after previous test)
  2. Complete onboarding
  3. Sign in with same Apple ID
  4. App should show as free
  5. Tap "Restore Purchases" in settings
  6. Verify premium restored
  7. Verify all premium features unlocked

**Test: Subscription Expiration**
- **Sandbox**: Subscriptions renew rapidly
- **Steps**:
  1. Subscribe to weekly (expires in 3 minutes)
  2. Wait for expiration
  3. Verify app downgrades to free
  4. Verify premium features locked
  5. Verify gentle upgrade prompt shown
  6. Verify historical premium data preserved

### Permission Testing

**Test: Location Permission Denied**
- **Steps**:
  1. Fresh install
  2. Complete onboarding
  3. Deny location permission
  4. Verify alert shown explaining need
  5. Verify "Open Settings" button works
  6. Enable in Settings
  7. Return to app
  8. Verify location starts working

**Test: Motion Permission Denied**
- **Steps**:
  1. Deny motion permission
  2. Verify pedometer tab shows lock icon
  3. Tapping pedometer shows permission request or paywall

**Test: Notification Permission Denied**
- **Steps**:
  1. Deny notifications
  2. Verify app works normally
  3. Verify no crash when trip completes
  4. Verify in-app alerts still work

---

## 5. Edge Case Testing

### Battery & Performance

**Test: Low Battery**
- Set device to low power mode
- Start trip recording
- Verify GPS still works
- Verify no excessive drain

**Test: Low Memory**
- Open many apps in background
- Open Speed Tracker
- Load trip history with many trips
- Verify no crash

**Test: Background/Foreground Cycling**
- Start trip
- Background app
- Return to foreground
- Background again
- Verify trip continues properly

### Network Conditions

**Test: Airplane Mode**
- Enable airplane mode
- Start trip
- Verify GPS still works
- Verify speed tracking works
- Verify weather doesn't update
- Verify no crash

**Test: Poor Cellular Signal**
- Drive in area with weak signal
- Verify trip recording works
- Verify iCloud sync queues for later
- Verify no data loss

**Test: No Internet on Launch**
- Turn off WiFi/cellular
- Launch app
- Verify app loads
- Verify cached data shown
- Verify sync indicator shows offline

### Data Edge Cases

**Test: Very Long Trip**
- Record trip for 4+ hours
- Verify app doesn't crash
- Verify trip saves correctly
- Verify map renders properly
- Verify graph displays correctly

**Test: Many Trips**
- Create 100+ test trips
- Verify list scrolls smoothly
- Verify search works
- Verify filter works
- Verify no memory issues

**Test: Trip in Different Timezone**
- Start trip in one timezone
- Change timezone (travel or manual)
- End trip
- Verify times displayed correctly

---

## 6. Regression Testing

After each major update, test:

**Core Flows**:
- [ ] Onboarding (new user)
- [ ] Apple Sign-In
- [ ] Permission requests
- [ ] Speed tracking
- [ ] Trip recording
- [ ] Trip viewing
- [ ] Pedometer session
- [ ] Settings changes
- [ ] Subscription purchase
- [ ] Restore purchase
- [ ] iCloud sync
- [ ] Logout

**Critical Features**:
- [ ] GPS accuracy
- [ ] Speed conversion
- [ ] Trip auto-start/end
- [ ] Map rendering
- [ ] Speed graphs
- [ ] Data persistence
- [ ] Premium feature gating

---

## 7. App Store Review Preparation

### Pre-Submission Checklist

**Functionality**:
- [ ] App doesn't crash on launch
- [ ] All advertised features work
- [ ] No obvious bugs
- [ ] Performance is acceptable

**Subscriptions**:
- [ ] Restore Purchases button present
- [ ] Pricing clearly displayed
- [ ] Auto-renewal terms disclosed
- [ ] Privacy policy link present
- [ ] Terms of service link present

**Permissions**:
- [ ] Info.plist descriptions accurate
- [ ] Custom permission dialogs shown
- [ ] App works with denied permissions (except location)
- [ ] No excessive permission requests

**Privacy**:
- [ ] Privacy policy accurate
- [ ] Data usage clearly explained
- [ ] No third-party data sharing
- [ ] iCloud usage disclosed

**Content**:
- [ ] No offensive content
- [ ] No copyright violations
- [ ] Accurate app description
- [ ] Screenshots match actual app

### Test Account for Review

Provide Apple with:
- **Email**: reviewer@speedtracker.app (sandbox account)
- **Instructions**: "Sign in with Apple ID when prompted. Grant location permission to test speed tracking. Trip will auto-record when moving."

---

## 8. Beta Testing

### TestFlight Beta

**Audience**: 
- Internal team (5-10 people)
- External beta testers (50-100 people)

**Duration**: 2-4 weeks before App Store submission

**Feedback Collection**:
- In-app feedback form
- Email: beta@speedtracker.app
- TestFlight feedback

**Key Metrics to Track**:
- Crash rate (should be <0.1%)
- Session duration
- Feature usage
- Conversion rate (free → premium)
- Battery drain reports

### Beta Testing Focus Areas

**Week 1-2: Core Functionality**
- Speed tracking accuracy
- Trip recording reliability
- Battery consumption
- GPS performance in various conditions

**Week 3-4: User Experience**
- Onboarding clarity
- Paywall conversion
- Settings usability
- Premium feature value

---

## 9. Automated Testing CI/CD

### GitHub Actions Workflow

```yaml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run unit tests
        run: xcodebuild test -scheme SpeedTracker -destination 'platform=iOS Simulator,name=iPhone 14'
      - name: Run UI tests
        run: xcodebuild test -scheme SpeedTrackerUITests -destination 'platform=iOS Simulator,name=iPhone 14'
```

---

## 10. Test Coverage Goals

**Minimum Coverage**:
- **Unit Tests**: 70%+
- **Integration Tests**: 50%+
- **UI Tests**: 30%+

**Critical Path Coverage**: 100%
- Trip recording
- Subscription purchase
- iCloud sync
- Data persistence

---

## Testing Schedule

**Before Initial Release**:
- 2 weeks unit/integration testing
- 1 week manual testing
- 2-4 weeks beta testing
- 1 week final regression testing

**Before Each Update**:
- Regression test all core flows
- Test new features thoroughly
- 1 week beta testing (for major updates)

---

## Bug Tracking

**Severity Levels**:
- **P0 (Critical)**: Crash, data loss → Fix immediately
- **P1 (High)**: Core feature broken → Fix before release
- **P2 (Medium)**: Minor feature broken → Fix soon
- **P3 (Low)**: UI glitch, typo → Fix when possible

**Tools**: 
- GitHub Issues for tracking
- TestFlight feedback for beta bugs
- Crash analytics (Xcode Organizer)

---

## Post-Launch Monitoring

**Key Metrics**:
- App Store crash rate
- User reviews mentioning bugs
- Support emails
- RevenueCat refund rate

**Response Plan**:
- Monitor daily for first week
- Hot-fix critical bugs within 24 hours
- Regular updates every 2-4 weeks
