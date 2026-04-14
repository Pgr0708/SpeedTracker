# Integrations

## Overview
SpeedTracker is a fully offline iOS application with no active external API integrations. All functionality is local-device-only.

---

## External Services

### In-App Purchases (Planned — Not Implemented)
- **Provider:** RevenueCat (StoreKit wrapper)
- **Status:** UI/paywall shell exists (`SpeedTracker/Views/Onboarding/PaywallView.swift`) but StoreKit integration is NOT implemented
- **What's missing:** No `StoreKit` import, no `Product.products()` call, no purchase logic, no entitlement validation
- **Paywall triggers:** From onboarding flow and potentially from premium feature gates
- **Notes:** The paywall currently shows static UI and dismisses without any transaction

---

## System Frameworks (Apple Platform)

### CoreLocation
- **Purpose:** GPS speed, heading, altitude, coordinate tracking
- **File:** `SpeedTracker/Services/Location/LocationManager.swift`
- **Auth:** `NSLocationWhenInUseUsageDescription` / `NSLocationAlwaysAndWhenInUseUsageDescription`
- **Notes:** Background location enabled for continuous tracking

### MapKit
- **Purpose:** Trip route visualization on map
- **Files:** `SpeedTracker/Views/History/TripDetailView.swift`
- **Auth:** None required beyond CoreLocation
- **Notes:** Local rendering only, no map tile API key needed

### UserNotifications
- **Purpose:** Speed limit alerts (vibration + notification when speed exceeded)
- **File:** `SpeedTracker/Services/NotificationManager.swift`
- **Auth:** `UNUserNotificationCenter.requestAuthorization`
- **Notes:** Local notifications only, no push notification server

### Charts (SwiftUI Charts)
- **Purpose:** Speed history visualization within trip details
- **Files:** `SpeedTracker/Views/History/TripDetailView.swift`
- **Notes:** Apple-native, iOS 16+

### Combine
- **Purpose:** Reactive data flow from `LocationManager` to views via `@Published` properties
- **Files:** `SpeedTracker/Services/Location/LocationManager.swift`, view models

---

## Data Persistence

### FileManager (JSON)
- **Purpose:** Trip storage and user preferences
- **File:** `SpeedTracker/Services/Storage/TripStore.swift`
- **Location:** App's Documents directory
- **Format:** Plaintext JSON (no encryption)
- **Notes:** No cloud sync, no iCloud backup configured, data is device-local only

### UserDefaults
- **Purpose:** App settings (speed units, speed limit, HUD preferences, onboarding state)
- **File:** `SpeedTracker/Utilities/Constants.swift`, `SpeedTracker/Views/Settings/SettingsView.swift`
- **Notes:** Standard iOS UserDefaults, not shared with extensions

---

## Auth Providers
None. No user accounts, no sign-in, no OAuth.

---

## Analytics / Crash Reporting
None implemented. No Firebase, Sentry, Mixpanel, or equivalent.

---

## Webhooks / Background Sync
None. App is fully offline.

---

## Localization
- **Provider:** Custom `LocalizationManager` wrapping Apple's `Bundle.localizedString`
- **File:** `SpeedTracker/Utilities/LocalizationManager.swift`
- **Languages:** 14 languages supported via `.lproj` bundles
- **Notes:** Runtime language switching without app restart
