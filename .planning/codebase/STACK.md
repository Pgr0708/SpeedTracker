# Technology Stack

**Analysis Date:** 2026-04-14

## Languages

**Primary:**
- Swift 5.0 - All application code including views, models, services, and utilities

**Secondary:**
- None - Pure Swift iOS application

## Runtime

**Environment:**
- iOS 26.2 (deployment target)
- Compatible with iPhone and iPad (device families 1,2)

**Package Manager:**
- Xcode 26.3 - Native Swift Package Manager ecosystem
- Lockfile: Not applicable (Xcode manages dependencies)

## Frameworks

**Core UI:**
- SwiftUI - Primary framework for all UI rendering and views
- UIKit - Limited use for haptic feedback generation (`UIImpactFeedbackGenerator`, `UINotificationFeedbackGenerator`, `UISelectionFeedbackGenerator`)

**System Frameworks:**
- CoreLocation - GPS-based speed tracking and location services
- MapKit - Route mapping and geographic visualization
- Charts - Speed-time graph visualization in trip details
- UserNotifications - Push notification and local alerts
- Combine - Reactive data flow and publisher-subscriber pattern

**Architecture Support:**
- @MainActor - Swift concurrency for main thread UI updates
- SWIFT_APPROACHABLE_CONCURRENCY - Modern concurrency patterns
- SWIFT_DEFAULT_ACTOR_ISOLATION - Actor isolation by default

## Key Dependencies

**Critical:**
- CoreLocation - Enables real-time GPS speed tracking, mandatory for app function (`SpeedTracker/Services/Location/LocationManager.swift`)
- SwiftUI - Complete UI framework, no third-party UI libraries
- MapKit - Route visualization and mapping features (`SpeedTracker/Views/History/TripDetailView.swift`)
- Charts - Speed analytics visualization (`SpeedTracker/Views/History/TripDetailView.swift`)

**Infrastructure:**
- Foundation - Standard library for data handling, dates, UUID generation
- Combine - Reactive programming for state management (@Published properties)

## Configuration

**Environment:**
- UserDefaults-based local configuration
- No environment variables or .env files required
- Configuration stored in:
  - `SpeedTracker/Utilities/Constants.swift` - Design system, colors, typography, animation constants
  - AppStorage keys defined in `AppConstants.UserDefaultsKeys` enum

**Key Configs Required:**
- `maxSpeedLimit`: Default 120.0 km/h - user-configurable speed threshold
- `minSpeedLimit`: Default 0.0 - lower speed bound
- `preferredSpeedUnit`: Speed unit preference (km/h, mph, m/s, knots)
- `preferredLanguage`: Language selection from 14 supported languages
- `themeColor`: Accent color theme (blue, green, orange, purple, red, cyan)
- `isDarkModeEnabled`: Light/dark mode preference (default: dark)
- `isHapticEnabled`: Haptic feedback toggle (default: enabled)

**Build:**
- `project.pbxproj` - Xcode project configuration
- Swift compilation settings:
  - SWIFT_VERSION = 5.0
  - SWIFT_COMPILATION_MODE = wholemodule (Release)
  - SWIFT_OPTIMIZATION_LEVEL = -Onone (Debug)

## Localization

**Supported Languages:** 14 locales
- English (en)
- Korean (ko)
- Japanese (ja)
- Greek (el)
- French (fr)
- German (de)
- Spanish (es)
- Portuguese (pt)
- Portuguese Brazil (pt-BR)
- Chinese Simplified (zh-Hans)
- Vietnamese (vi)
- Turkish (tr)
- Italian (it)
- Arabic (ar) - RTL support

**Localization Files:**
- `SpeedTracker/Localization/` contains 14 `.lproj` directories
- String catalogs enabled: LOCALIZATION_PREFERS_STRING_CATALOGS = YES
- System language auto-detection in `LocalizationManager.swift`

## Platform Requirements

**Development:**
- Xcode 26.3 or later
- Swift 5.0
- macOS with Xcode command-line tools

**Production:**
- iOS 26.2 or later
- App Store distribution
- In-app purchase integration (planned - not yet implemented)

## Design System

**Colors:**
- 6 theme color options (blue, green, orange, purple, red, cyan)
- Dark mode: Deep navy (#0A1128) base, dark blue (#1E2749) surface, bright text
- Light mode: Light gray (#F5F7FA) base, white (#FFFFFF) surface, dark text
- Constants defined in `AppConstants.Colors` and `AppConstants.ThemeColor` enums

**Typography:**
- Orbitron-Bold - Display typeface
- Rajdhani-Medium/Regular - Body typeface
- Font sizes from 12pt (caption) to 72pt (display-large)

**Animation:**
- Swift animation utilities with configurable timing (0.2s to 0.5s)
- Spring animations with response=0.5, dampingFraction=0.7
- Glass morphism effects with 15% opacity, 20px blur

---

*Stack analysis: 2026-04-14*
