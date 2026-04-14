# Testing Patterns

**Analysis Date:** 2026-04-14

## Test Framework

**Runner:**
- XCTest (built into Xcode)
- No test targets configured in project
- No test configuration files detected (no xctest, XCTestConfiguration)

**Assertion Library:**
- Not applicable; no tests present

**Run Commands:**
```bash
# Tests would be run via Xcode
# No command-line test runner configuration in place
xcodebuild test  # Standard Xcode test command (not configured)
```

**Current State:** Zero test coverage. No tests exist in repository.

## Test File Organization

**Location:**
- No test target or test bundle exists
- No `Tests/` directory found
- No `*Tests` or `*Test` files present

**Naming:**
- Convention would follow: `[ClassName]Tests.swift` (not implemented)

**Structure:**
```
# Expected structure (not currently implemented):
SpeedTrackerTests/
├── UnitTests/
│   ├── LocationManagerTests.swift
│   ├── ThemeManagerTests.swift
│   └── TripStoreTests.swift
└── UITests/
    └── MainTabViewUITests.swift
```

## Test Structure

**Suite Organization:**
```swift
// Expected pattern (not in use):
final class LocationManagerTests: XCTestCase {
    var sut: LocationManager!
    
    override func setUp() {
        super.setUp()
        sut = LocationManager()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testStartTracking_SetsTrackingTrue() {
        sut.startTracking()
        XCTAssertTrue(sut.isTracking)
    }
}
```

**Patterns:**
- Would use XCTestCase subclass for each testable component
- Setup/teardown would initialize SystemUnderTest (sut)
- One test per behavior
- Test naming: `test[WhatIsBeing Tested]_[Given Condition]_[Expected Result]`

## Mocking

**Framework:** None configured

**Patterns:**
```swift
// Mocking would be done manually or with custom protocols
// Example pattern (not in code):
protocol LocationManagerProtocol {
    func startTracking()
    func stopTracking() -> TripRecord?
}

class MockLocationManager: LocationManagerProtocol {
    var startTrackingCalled = false
    
    func startTracking() {
        startTrackingCalled = true
    }
    
    func stopTracking() -> TripRecord? {
        return nil
    }
}
```

**What to Mock:**
- Would mock `CLLocationManager` to avoid real GPS requests
- Would mock `UserDefaults` to isolate preferences testing
- Would mock timer operations to test elapsed time without waiting

**What NOT to Mock:**
- Would test real model objects like `TripRecord` and `RoutePoint`
- Would test real utility functions like `convertedSpeed(_:unit:)`
- Would use real theme colors and constants

## Fixtures and Factories

**Test Data:**
```swift
// Factory pattern would look like:
struct TripRecordFactory {
    static func makeTripRecord(
        distance: Double = 1000,
        maxSpeed: Double = 25.0,
        avgSpeed: Double = 15.0
    ) -> TripRecord {
        TripRecord(
            id: UUID(),
            date: Date(),
            duration: 60,
            distance: distance,
            maxSpeed: maxSpeed,
            avgSpeed: avgSpeed,
            startLatitude: 37.7749,
            startLongitude: -122.4194,
            endLatitude: 37.7749,
            endLongitude: -122.4194,
            routeCoordinates: [],
            speedHistory: []
        )
    }
}
```

**Location:**
- Would be stored in `Tests/Fixtures/` or `Tests/Helpers/`
- Not currently implemented

## Coverage

**Requirements:** No coverage targets or thresholds configured

**View Coverage:**
```bash
# Would generate coverage report
xcodebuild test -scheme SpeedTracker -enableCodeCoverage YES
```

**Current State:** Not applicable — no tests exist

## Test Types

**Unit Tests:**
- Would test isolated components:
  - `LocationManager`: Speed calculations, tracking state changes, coordinate filtering
  - `ThemeManager`: Color selection, theme persistence, dark/light mode toggling
  - `TripStore`: Trip storage/retrieval, data persistence
  - `Constants`: Enum conversions, color hex parsing
  
**Integration Tests:**
- Would test interactions:
  - `LocationManager` + `TripStore`: Recording a complete trip
  - `ThemeManager` + `AppStorage`: Persisting theme preferences across sessions
  - `SpeedTrackerView` + `LocationManager`: UI updates when speed changes

**E2E Tests:**
- Framework: Xcode UI Testing
- Not configured; would test:
  - Full onboarding flow (language selection → paywall → permissions)
  - Recording a trip start to finish
  - Switching between tabs and viewing history

## Common Patterns

**Async Testing:**
```swift
// Pattern for testing async code (not in use):
func testAsyncLocationUpdate() async throws {
    let expectation = expectation(description: "Location updated")
    
    locationManager.currentLocation.sink { location in
        if location != nil {
            expectation.fulfill()
        }
    }.store(in: &cancellables)
    
    locationManager.startTracking()
    
    await fulfillment(of: [expectation], timeout: 5.0)
    XCTAssertNotNil(locationManager.currentLocation)
}
```

**Error Testing:**
```swift
// Pattern for testing error handling (not in use):
func testLocationManager_OnDeniedPermission_RequestsPermission() {
    // Mock denied permissions
    mockLocationManager.authorizationStatus = .denied
    
    sut.startTracking()
    
    XCTAssertTrue(mockLocationManager.requestPermissionCalled)
}
```

## Testing Considerations for Future Implementation

**High Priority Tests Needed:**
1. `LocationManager` unit tests:
   - Speed calculations and unit conversions
   - Movement threshold filtering (0.8 m/s)
   - GPS accuracy filtering (< 50m)
   - Distance calculation from coordinate pairs

2. `TripStore` persistence tests:
   - Save and retrieve trips
   - Codable serialization of TripRecord
   - RoutePoint and SpeedPoint encoding

3. `ThemeManager` preference tests:
   - Theme color selection and persistence
   - Dark/light mode toggling
   - AppStorage synchronization

**Medium Priority Tests:**
1. View integration tests:
   - SpeedTrackerView displays speed updates
   - MainTabView tab switching
   - HistoryView renders saved trips

2. Utility function tests:
   - `Color(hex:)` parsing for all color formats
   - Speed unit conversions (kmh, mph, m/s, knots)
   - Duration and distance formatting

**Low Priority Tests:**
1. UI snapshot tests for visual regressions
2. Performance tests for large trip histories (1000+ records)
3. Localization tests for all 14 supported languages

---

*Testing analysis: 2026-04-14*
