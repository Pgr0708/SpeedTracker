# SpeedTracker iOS — Project Context
_Last updated: 2026-04-16_

---

## Vision
Production-ready iOS speed tracking app. No backend — 100% frontend + iCloud.
Auth: Apple Sign In (silent, no UI unless logged out). Payment: RevenueCat.

---

## App Flow
```
SplashView (2.5s)
  → [didLogOut==true] SignInView (Apple only)
  → [first time] LanguageSelectionView
                → OnboardingContainerView (3 screens, shown once)
                → PaywallView (4 plans + skip X)
                → PermissionsView (Location + Motion + Health + Notifications)
                → PreferencesSetupView (theme, max/min speed limit)
  → MainTabView (5 tabs)
```

## Tab Bar (5 tabs)
| # | Tab | Premium? |
|---|-----|----------|
| 0 | Speed (SpeedTrackerView) | Free |
| 1 | History (HistoryView) | Free (last 5 trips only) |
| HUD | HUDModeView (fullScreenCover) | 🔒 Premium |
| 2 | Pedometer (PedometerView) | 🔒 Premium |
| 3 | Settings (SettingsView) | Free |

---

## Premium vs Free
| Feature | Free | Premium |
|---------|------|---------|
| Current speed | ✅ | ✅ |
| Start/stop trip | ✅ | ✅ |
| Last 5 trips | ✅ | ✅ |
| Altitude, heading, coords | ❌ | ✅ |
| Full history + maps + graph | ❌ | ✅ |
| HUD mode | ❌ | ✅ |
| Mirror mode | ❌ | ✅ |
| Pedometer | ❌ | ✅ |
| Color themes | ❌ | ✅ |
| Speed limit alerts + beep | ❌ | ✅ |
| iCloud sync | ❌ | ✅ |
| Compass + Weather | ❌ | ✅ |

## Subscription Plans (RevenueCat)
| Plan | Price | Trial | Product ID |
|------|-------|-------|-----------|
| Weekly | $1.99/wk | — | speedtracker_weekly |
| Monthly | $4.99/mo | — | speedtracker_monthly |
| Yearly | $19.99/yr | — | speedtracker_yearly |
| Lifetime | $99.99 | — | speedtracker_lifetime |

RevenueCat entitlement: `"premium"`
**API Key placeholder:** `appl_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX` in `Constants.swift → AppConstants.Purchase.revenueCatAPIKey`

---

## Architecture
- **Pattern:** MVVM + Service Layer
- **State:** `@Published` + `@AppStorage` + `@EnvironmentObject`
- **Auth:** Apple Sign In (AuthenticationServices), userID in Keychain
- **Storage:** JSON files in Documents (TripStore), UserDefaults (prefs), iCloud via CloudKit (premium sync)
- **Payments:** RevenueCat SDK (SPM, must be added manually — see below)
- **Fonts:** Orbitron-Bold (headings/speed), Rajdhani-Medium/Regular (UI) — **must be downloaded and added to Resources/Fonts/**
- **Languages:** 14 locales (en, ko, ja, el, fr, de, es, pt, zh-Hans, vi, pt-BR, tr, it, ar)

---

## ✅ COMPLETED WORK

### Phase 1 — Project Config
- [x] iOS deployment target: 26.2 → **17.0** (`project.pbxproj`)
- [x] `SpeedTracker.entitlements` created (CloudKit + iCloud KV)

### Phase 3 — Models + Constants
- [x] `Constants.swift` — added `Purchase`, `URLs`, `CloudKit`, new `UserDefaultsKeys`
- [x] `TripRecord.swift` — added `cloudKitRecordID`, `activityType`, default init params
- [x] `PedometerSession.swift` — new model (steps, distance, calories, pace, goal)
- [x] `UserProfile.swift` — new model (Apple ID backed, Keychain, UserDefaults persistence)

### Phase 2 — New Services
- [x] `Services/Auth/AuthService.swift` — Sign in with Apple, silent credential check, Keychain, signOut sets `didLogOut`
- [x] `Services/Purchase/PurchaseService.swift` — RevenueCat wrapper (4 plans, purchase, restore). **Needs SDK added via SPM.**
- [x] `Services/Audio/AudioService.swift` — beep alerts (AVFoundation), mute toggle, 10s cooldown
- [x] `Services/Pedometer/PedometerService.swift` — CMPedometer, calories, goal, session save/load
- [x] `Services/Weather/WeatherService.swift` — WeatherKit stub (ready to enable, needs capability)
- [x] `Services/CloudKit/CloudKitService.swift` — full iCloud sync (trips, prefs, pedometer)

### Phase 4 — Modified Services
- [x] `LocationManager.swift` — added `altitude`, `heading`, `latitude`, `longitude`; speed-aware GPS filter; heading delegate
- [x] `NotificationManager.swift` — 30s cooldown, separate max/min alert methods, unit-aware text
- [x] `TripStore.swift` — added public `persist()` method, CloudKit trigger on save

### Phase 5 — New Views
- [x] `Views/Onboarding/SplashView.swift` — animated 2.5s splash with Orbitron branding
- [x] `Views/Auth/SignInView.swift` — Apple Sign In button, shown only when `didLogOut==true`

### Phase 6 — Rewritten Views
- [x] `SpeedTrackerApp.swift` — full auth flow: Splash → SignIn/Language/Onboard/Paywall/Perms/Prefs → Main; RevenueCat configure on init
- [x] `MainTabView.swift` — 5 tabs (Speed, History, HUD🔒, Steps🔒, Settings); premium lock icons
- [x] `PaywallView.swift` — 4 plans ($2.99/$7.99/$49.99/$99.99), RevenueCat wired, skip X, restore
- [x] `PermissionsView.swift` — Location + CoreMotion + HealthKit (optional) + Notifications
- [x] `SpeedTrackerView.swift` — Orbitron font, speed alert popup overlay, min+max alerts, AudioService, mute button, premium stat cards with lock
- [x] `HUDModeView.swift` — mirror toggle (`isMirrorModeEnabled`), heading + altitude, Orbitron font, color-coded speed

---

## ⏳ REMAINING WORK

### Phase 6 (continued) — Views still needed
- [ ] `SettingsView.swift` — needs: profile section, logout, restore purchase, sound toggle, mirror toggle, contact/terms/privacy URLs, language restart prompt, iCloud sync status, fix force-unwrap crash
- [ ] `HistoryView.swift` — needs: free tier limit (last 5 trips), premium upgrade banner, Pedometer Sessions segment
- [ ] `PedometerView.swift` — new full view (step counter, goal ring, calories, start/stop/save)
- [ ] `PedometerDetailView.swift` — new (pace chart, calorie breakdown)
- [ ] `CompassView.swift` — canvas compass rose widget

### Phase 7 — Localization
- [ ] All 14 `Localizable.strings` files need ~50 new keys added (auth, pedometer, alerts, plans, compass, HUD, premium gate)
- New keys include: `sign_in_apple`, `logout`, `pedometer`, `steps`, `calories`, `speed_alert_max_title`, `plan_weekly`, `upgrade_now`, etc.

### Phase 8 — Project Registration
- [ ] `project.pbxproj` — register all new Swift files (15+ new files) so Xcode compiles them
- [ ] New files that MUST be added to Xcode project navigator:
  ```
  Services/Auth/AuthService.swift
  Services/Purchase/PurchaseService.swift
  Services/Audio/AudioService.swift
  Services/Pedometer/PedometerService.swift
  Services/Weather/WeatherService.swift
  Services/CloudKit/CloudKitService.swift
  Models/PedometerSession.swift
  Models/UserProfile.swift
  Views/Auth/SignInView.swift
  Views/Onboarding/SplashView.swift
  Views/Pedometer/PedometerView.swift       ← not yet written
  Views/Pedometer/PedometerDetailView.swift  ← not yet written
  Views/Components/CompassView.swift         ← not yet written
  ```

### Phase 1 (remaining) — Info.plist
- [ ] `Info.plist` — add permission strings:
  - `NSLocationWhenInUseUsageDescription`
  - `NSLocationAlwaysAndWhenInUseUsageDescription`
  - `NSMotionUsageDescription`
  - `NSHealthShareUsageDescription`
  - `NSHealthUpdateUsageDescription`
  - `UIBackgroundModes: [location]`
  - `UIAppFonts: [Orbitron-Bold.ttf, Rajdhani-Medium.ttf, Rajdhani-Regular.ttf]`

---

## Manual Steps Required (Cannot be automated)

1. **Add RevenueCat SDK via SPM in Xcode:**
   - URL: `https://github.com/RevenueCat/purchases-ios`
   - Version: `~> 5.0`, Product: `RevenueCat`
   - Then uncomment `import RevenueCat` lines in `PurchaseService.swift`
   - Replace placeholder API key in `Constants.swift → AppConstants.Purchase.revenueCatAPIKey`

2. **Add font files to `Resources/Fonts/`:**
   - Download from Google Fonts: Orbitron-Bold.ttf, Rajdhani-Medium.ttf, Rajdhani-Regular.ttf
   - Drag into Xcode project (check "Add to target: SpeedTracker")

3. **Enable Capabilities in Xcode (Signing & Capabilities):**
   - iCloud → CloudKit (container: `iCloud.com.centillion.SpeedTracker`)
   - Sign in with Apple
   - WeatherKit (optional, for weather feature)
   - Push Notifications (for speed alerts)
   - Background Modes → Location updates

4. **Set up CloudKit schema** in developer.apple.com/cloudkit dashboard:
   - Record types: `TripRecord`, `PedometerSession`, `UserPreferences`

5. **Set up RevenueCat dashboard:**
   - Create 4 products in App Store Connect: weekly/monthly/yearly/lifetime
   - Link to RevenueCat with entitlement ID `"premium"`

6. **Replace placeholders before submission:**
   - `AppConstants.Purchase.revenueCatAPIKey`
   - `AppConstants.URLs.contactUs`
   - `AppConstants.URLs.privacyPolicy`
   - `AppConstants.URLs.termsOfService`
   - `AppConstants.URLs.rateApp` (App Store ID)

---

## Key File Map
| Concern | File |
|---------|------|
| App entry + flow | `SpeedTrackerApp.swift` |
| Tab navigation | `Views/Main/MainTabView.swift` |
| Speed tracking | `Views/Main/SpeedTrackerView.swift` |
| HUD display | `Views/Main/HUDModeView.swift` |
| Pedometer | `Views/Pedometer/PedometerView.swift` (TODO) |
| History | `Views/History/HistoryView.swift` (TODO: gating) |
| Settings | `Views/Settings/SettingsView.swift` (TODO: account) |
| Paywall | `Views/Onboarding/PaywallView.swift` |
| Splash | `Views/Onboarding/SplashView.swift` |
| Sign In | `Views/Auth/SignInView.swift` |
| GPS service | `Services/Location/LocationManager.swift` |
| Auth service | `Services/Auth/AuthService.swift` |
| Purchase service | `Services/Purchase/PurchaseService.swift` |
| Audio alerts | `Services/Audio/AudioService.swift` |
| Pedometer logic | `Services/Pedometer/PedometerService.swift` |
| iCloud sync | `Services/CloudKit/CloudKitService.swift` |
| Weather | `Services/Weather/WeatherService.swift` |
| Trip persistence | `Services/Storage/TripStore.swift` |
| Notifications | `Services/NotificationManager.swift` |
| Design system | `Utilities/Constants.swift` |
| Theme | `Utilities/ThemeManager.swift` |
| Localization | `Localization/{lang}.lproj/Localizable.strings` |
| Entitlements | `SpeedTracker.entitlements` |
