# Architecture

**Analysis Date:** 2026-04-14

## Pattern Overview

**Overall:** MVVM (Model-View-ViewModel) + Service Layer

The SpeedTracker codebase follows Apple's recommended SwiftUI architecture with clear separation of concerns. The app uses ObservableObject view models for state management, singleton services for core functionality, and a layered approach to organize business logic, presentation, and data persistence.

**Key Characteristics:**
- Model-View-ViewModel (MVVM) pattern with @StateObject and @EnvironmentObject
- Singleton services for LocationManager, TripStore, ThemeManager, NotificationManager
- Environment-based state propagation (@EnvironmentObject for ThemeManager)
- UserDefaults for persistent settings and flags
- File-based JSON storage for trip records

## Layers

**Presentation Layer (Views):**
- Purpose: SwiftUI view components that display data and capture user interactions
- Location: `SpeedTracker/Views/`
- Contains: SwiftUI View structs organized by feature (Main, History, Onboarding, Settings, Components)
- Depends on: ViewModels, Services, ThemeManager, Constants
- Used by: App entry point (SpeedTrackerApp)

**ViewModel Layer:**
- Purpose: Manages view state, coordinates between views and services, handles business logic
- Location: `SpeedTracker/ViewModels/`
- Contains: ObservableObject classes (OnboardingViewModel)
- Depends on: Models, Services, Constants
- Used by: Views through @StateObject injection

**Service Layer:**
- Purpose: Core business logic for location tracking, data persistence, notifications, and theming
- Location: `SpeedTracker/Services/`
- Contains: LocationManager, TripStore, NotificationManager, Analytics (placeholder)
- Depends on: Models, Constants, CoreLocation, UserNotifications frameworks
- Used by: Views, ViewModels through singleton access or dependency injection

**Model Layer:**
- Purpose: Data structures representing domain entities
- Location: `SpeedTracker/Models/`
- Contains: TripRecord, RoutePoint, SpeedPoint, OnboardingPage
- Depends on: Foundation, CoreLocation
- Used by: Services, ViewModels, Views

**Utilities & Extensions:**
- Purpose: Cross-cutting utilities, theming, localization, haptics
- Location: `SpeedTracker/Utilities/`, `SpeedTracker/Extensions/`
- Contains: Constants, ThemeManager, LocalizationManager, Haptics, View+Extensions
- Depends on: Foundation, SwiftUI, Combine
- Used by: All layers

## Data Flow

**Speed Tracking Session:**

1. User taps "Start" in SpeedTrackerView
2. SpeedTrackerView calls LocationManager.startTracking()
3. LocationManager initializes tracking state and calls manager.startUpdatingLocation()
4. CLLocationManager delegate method locationManager(_:didUpdateLocations:) fires periodically
5. LocationManager processes GPS data, calculates speed/distance, updates @Published properties
6. SpeedTrackerView observes LocationManager changes via @StateObject and updates UI
7. User taps "Stop"
8. LocationManager.stopTracking() creates TripRecord from accumulated data
9. SpeedTrackerView calls TripStore.saveTrip()
10. TripStore inserts trip and persists to JSON file

**Onboarding Flow:**

1. SpeedTrackerApp checks UserDefaults flags in sequential order
2. If hasSelectedLanguage = false → LanguageSelectionView
3. If hasCompletedOnboarding = false → OnboardingContainerView
4. If hasCompletedPaywall = false → PaywallView
5. If hasCompletedPreferences = false → PreferencesSetupView
6. If !hasGrantedPermissions → PermissionsView
7. Otherwise → MainTabView (home screen)
8. Each screen updates UserDefaults to mark completion
9. App re-evaluates on next render, progresses to next screen

**State Management:**

- **App-level state**: SpeedTrackerApp uses @AppStorage for language/onboarding flags, manages MainActor transitions
- **View-level state**: Views use @State for local UI state (tab selection, animations, modals)
- **Service state**: LocationManager maintains @Published properties for real-time tracking data
- **Persistent storage**: UserDefaults for simple flags/settings, JSON file for trip history
- **Theme state**: ThemeManager (singleton ObservableObject) manages dark/light mode and color theme, injected via @EnvironmentObject

## Key Abstractions

**LocationManager:**
- Purpose: Encapsulates all GPS tracking, speed calculation, distance measurement
- Examples: `SpeedTracker/Services/Location/LocationManager.swift`
- Pattern: Singleton (@MainActor ObservableObject) wrapping CLLocationManager
- Responsibilities: Request permissions, start/stop tracking, filter noisy GPS data, calculate statistics, create TripRecord on completion

**TripStore:**
- Purpose: Single source of truth for trip history data
- Examples: `SpeedTracker/Services/Storage/TripStore.swift`
- Pattern: Singleton (@MainActor ObservableObject) with JSON file backend
- Responsibilities: Load trips from disk on init, add/delete trips, trigger persistence, compute aggregate stats

**ThemeManager:**
- Purpose: Manage theme colors and dark/light mode preferences
- Examples: `SpeedTracker/Utilities/ThemeManager.swift`
- Pattern: Singleton (@MainActor ObservableObject) reading from @AppStorage
- Responsibilities: Provide adaptive colors, manage theme color selection, compute gradient/shader values

**TripRecord:**
- Purpose: Immutable data structure representing a completed trip
- Examples: `SpeedTracker/Models/TripRecord.swift`
- Pattern: Struct with nested RoutePoint and SpeedPoint value types, Identifiable + Codable for persistence
- Responsibilities: Store trip metadata (date, duration, distance, speed stats), route coordinates, speed history; provide formatted display strings

## Entry Points

**SpeedTrackerApp:**
- Location: `SpeedTracker/SpeedTrackerApp.swift`
- Triggers: App launch
- Responsibilities: Initialize app state, set up UserDefaults defaults, manage onboarding/permission flow, provide ThemeManager via environment, render correct screen based on onboarding status

**MainTabView:**
- Location: `SpeedTracker/Views/Main/MainTabView.swift`
- Triggers: Accessed after onboarding/permissions complete
- Responsibilities: Root container for main app experience, tab bar navigation, modal presentation for HUD and paywall

**SpeedTrackerView:**
- Location: `SpeedTracker/Views/Main/SpeedTrackerView.swift`
- Triggers: Tab index 0 selected
- Responsibilities: Real-time speed display, start/stop tracking, show current session stats, manage alerts for over-limit speeds

**HistoryView:**
- Location: `SpeedTracker/Views/History/HistoryView.swift`
- Triggers: Tab index 1 selected
- Responsibilities: Display list of past trips, show aggregate statistics, navigate to trip details

**SettingsView:**
- Location: `SpeedTracker/Views/Settings/SettingsView.swift`
- Triggers: Tab index 2 selected
- Responsibilities: Manage user preferences (speed unit, speed limits, theme, haptics)

## Error Handling

**Strategy:** Silent failure with logging to console

**Patterns:**
- LocationManager filters inaccurate GPS readings (accuracy < 0 or > 50 meters) without alerting user
- TripStore catches JSON encoding/decoding errors, prints to console but doesn't propagate exceptions
- NotificationManager catches permission request errors, prints but continues gracefully
- Missing or invalid settings fall back to sensible defaults (e.g., dark mode enabled, 120 km/h speed limit)

**No error UI:** The app does not surface errors to users via alerts or messages. Failures are logged only.

## Cross-Cutting Concerns

**Logging:** Console-based via print() statements. LocationManager logs GPS errors, TripStore logs persistence errors, NotificationManager logs permission errors.

**Validation:** 
- GPS accuracy filtering in LocationManager (rejects readings > 50m error)
- Distance jump filtering (ignores distances > 500m between updates to filter GPS jumps)
- Speed threshold (0.8 m/s minimum to filter stationary noise)
- UserDefaults validation (checks object existence before reading to avoid nil crashes)

**Authentication/Permissions:**
- Location: Managed by LocationManager.requestPermission() → CLLocationManager.requestWhenInUseAuthorization()
- Notifications: Managed by NotificationManager.requestPermission() → UNUserNotificationCenter.requestAuthorization()
- PermissionsView is dedicated flow screen during onboarding

**Performance Optimizations:**
- LocationManager uses distanceFilter = 5 (meters) to reduce update frequency
- LocationManager uses kCLLocationAccuracyBestForNavigation for best balance of accuracy/battery
- SpeedTrackerView uses @StateObject for singleton services to prevent re-initialization
- TripStore loads trips once on init, not on every property access

---

*Architecture analysis: 2026-04-14*
