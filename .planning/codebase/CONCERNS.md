# Concerns

## Overview
SpeedTracker is a young codebase (~28 Swift files) with solid architecture but several notable tech debt items, known bugs, and missing production-readiness features.

---

## Tech Debt

### 1. Hardcoded GPS Jump Filter
- **File:** `SpeedTracker/Services/Location/LocationManager.swift`
- **Issue:** GPS spike filter threshold is hardcoded at 500m — not configurable, not speed-aware
- **Impact:** Medium — may incorrectly filter legitimate fast movements (highway, aircraft)
- **Fix:** Make threshold dynamic based on current speed or expose as settings parameter

### 2. Speed-Unaware Movement Threshold
- **File:** `SpeedTracker/Services/Location/LocationManager.swift`
- **Issue:** 0.8 m/s movement threshold treats all speeds equally, causing false start/stop transitions
- **Impact:** Medium — trip recordings may fragment at low speeds or in traffic
- **Fix:** Scale threshold proportionally to current speed

### 3. Custom Font Without Fallback
- **Files:** `SpeedTracker/Extensions/Font+Extensions.swift`, all main views
- **Issue:** `Orbitron-Bold`, `Rajdhani-Medium`, `Rajdhani-Regular` used without fallback font
- **Impact:** Low — silently falls back to system font if font fails to load, but no explicit fallback defined
- **Fix:** Add explicit fallback in Font extension

### 4. Plaintext JSON Persistence
- **File:** `SpeedTracker/Services/Storage/TripStore.swift`
- **Issue:** Trip data (GPS coordinates, timestamps) stored as unencrypted JSON in Documents directory
- **Impact:** Medium — PII accessible without device encryption bypass
- **Fix:** Use `NSFileProtection.complete` or encrypt sensitive fields

### 5. Silent Error Handling
- **Files:** `LocationManager.swift`, `NotificationManager.swift`, `TripStore.swift`
- **Issue:** Errors caught and printed via `print()` only — no user feedback, no crash reporting
- **Impact:** Medium — bugs in production are invisible
- **Fix:** Add error propagation to views and integrate crash reporting (Sentry/Firebase)

### 6. Min/Max Speed Limit Validation Gap
- **File:** `SpeedTracker/Views/Settings/SettingsView.swift`
- **Issue:** Sliders for min/max speed limits have no cross-validation (user can set min > max)
- **Impact:** Low — undefined behavior in notification logic
- **Fix:** Add `.onChange` validation to clamp min below max

---

## Known Bugs

### 1. Force Unwrap in Settings Reset
- **File:** `SpeedTracker/Views/Settings/SettingsView.swift` (approx. line 298)
- **Issue:** `Bundle.main.bundleIdentifier!` force-unwrap — will crash if bundle identifier is nil
- **Severity:** Low (bundleIdentifier is reliably set in production, but bad practice)
- **Fix:** Use `guard let` or nil coalescing

### 2. Notification Spam at Sustained Speed
- **File:** `SpeedTracker/Services/NotificationManager.swift`
- **Issue:** Notifications fire with only 5 km/h hysteresis and no cooldown timer — sustained speed above limit sends repeated notifications
- **Severity:** Medium — poor UX, users may disable notifications entirely
- **Fix:** Add a cooldown period (e.g., 30s) before re-triggering speed alert

### 3. HUD Mode Screen Lock Race Condition
- **File:** `SpeedTracker/Views/Main/HUDModeView.swift`
- **Issue:** `UIApplication.shared.isIdleTimerDisabled` toggled without synchronization — may race with system idle timer
- **Severity:** Low — intermittent screen sleep during HUD mode
- **Fix:** Toggle on main thread with `DispatchQueue.main.async`

---

## Security Issues

### 1. Unencrypted Location Data
- **File:** `SpeedTracker/Services/Storage/TripStore.swift`
- **Concern:** GPS coordinates and timestamps are PII; stored as plaintext JSON
- **Recommendation:** Apply `NSFileProtectionComplete` to the storage directory

### 2. No Secure Deletion
- **Concern:** Trip data not securely wiped on app delete or account reset
- **Recommendation:** Offer explicit data deletion in settings with confirmation

### 3. Location Permission Without In-App Justification
- **File:** `SpeedTracker/Views/Onboarding/PermissionsView.swift`
- **Concern:** Permission request shown without clear explanation of why "Always" location is needed
- **Recommendation:** Add explicit rationale screen before permission prompt per Apple guidelines

---

## Performance Bottlenecks

### 1. Unbounded speedHistory Array
- **File:** `SpeedTracker/Services/Location/LocationManager.swift`
- **Issue:** `speedHistory` array grows unbounded during a tracking session (~1 entry/sec)
- **Impact:** Long sessions (hours) will consume significant memory
- **Fix:** Cap array to last N readings (e.g., 3600 for 1 hour) or use a circular buffer

### 2. TripStore Loads All Trips Into Memory
- **File:** `SpeedTracker/Services/Storage/TripStore.swift`
- **Issue:** All trips deserialized on app launch — no pagination or lazy loading
- **Impact:** Degrades with many trips; 100+ trips noticeable on older devices
- **Fix:** Load trip list (metadata only) eagerly, load full trip data lazily on detail view

### 3. Frequent View Redraws
- **File:** `SpeedTracker/Views/Main/SpeedTrackerView.swift`
- **Issue:** Speed display updates on every GPS reading (~1/sec), triggering full view tree re-evaluation
- **Impact:** Low on modern devices, noticeable on older hardware
- **Fix:** Throttle display updates or use `Equatable` conformance to skip redundant redraws

---

## Fragile Areas

### 1. LocationManager Singleton State
- **File:** `SpeedTracker/Services/Location/LocationManager.swift`
- **Issue:** Singleton with persistent global state — no automatic reset on background/foreground transitions
- **Risk:** Stale state after long background periods
- **Recommendation:** Add `scenePhase` observer to reset/resume cleanly

### 2. Tab Navigation Doesn't Pause Tracking
- **File:** `SpeedTracker/Views/Main/MainTabView.swift`
- **Issue:** Switching away from Speed tab does not pause tracking or HUD — tracking silently continues
- **Risk:** User confusion about battery/data usage
- **Recommendation:** Show persistent "tracking active" indicator on all tabs

### 3. Oversized View Files
- **Files:** `SettingsView.swift` (459 lines), `SpeedTrackerView.swift` (386 lines)
- **Issue:** Large monolithic views — deeply nested SwiftUI body closures
- **Risk:** High cognitive complexity; hard to extend or test
- **Recommendation:** Extract subviews into dedicated files

### 4. Paywall Multiple Exit Paths
- **File:** `SpeedTracker/Views/Onboarding/PaywallView.swift`
- **Issue:** Multiple dismiss buttons with overlapping state — easy to introduce dismiss logic bugs
- **Risk:** Onboarding flow may skip or double-trigger
- **Recommendation:** Centralize dismiss action into single binding

---

## Scaling Limits

| Limit | Detail |
|-------|--------|
| Trip storage | JSON files degrade beyond ~50-100MB (100s of long trips) |
| speedHistory | Grows ~3.6KB/hour; unbounded in memory |
| Localization | 14 languages managed manually — no automation |

---

## Missing Production Features

| Feature | Status |
|---------|--------|
| StoreKit / IAP | UI exists, zero implementation |
| Analytics | None |
| Crash reporting | None |
| Trip export (GPX/CSV) | None |
| iCloud backup | Not configured |
| Widget / Live Activity | Not implemented |
| Unit tests | None present |

---

## Test Coverage Gaps
- No unit tests for `LocationManager` state machine transitions
- No round-trip serialization tests for `TripStore`
- No validation tests for speed limit logic
- No onboarding flow or navigation tests
- No UI tests
