# Directory Structure

## Overview
SwiftUI iOS app organized by feature layer: Services → Models → ViewModels → Views → Utilities/Extensions.

---

## Directory Tree

```
SpeedTracker/
├── SpeedTrackerApp.swift          # App entry point, @main, root scene
├── ContentView.swift              # Root view, routes to onboarding or main tab
│
├── Models/
│   ├── TripRecord.swift           # Codable struct for persisted trip data
│   └── OnboardingPage.swift       # Data model for onboarding slides
│
├── Services/
│   ├── Location/
│   │   └── LocationManager.swift  # ObservableObject, CLLocationManagerDelegate, GPS state machine
│   ├── Storage/
│   │   └── TripStore.swift        # ObservableObject, JSON persistence via FileManager
│   └── NotificationManager.swift  # UNUserNotificationCenter wrapper, speed alerts
│
├── ViewModels/
│   └── OnboardingViewModel.swift  # Onboarding flow state, page navigation
│
├── Views/
│   ├── Main/
│   │   ├── MainTabView.swift      # TabView root (Speed, History, Settings tabs)
│   │   ├── SpeedTrackerView.swift # Primary speed display UI (386 lines)
│   │   └── HUDModeView.swift      # Heads-up display overlay mode
│   ├── History/
│   │   ├── HistoryView.swift      # Trip list view
│   │   └── TripDetailView.swift   # Individual trip detail + map + charts
│   ├── Settings/
│   │   └── SettingsView.swift     # User preferences (459 lines)
│   ├── Onboarding/
│   │   ├── OnboardingContainerView.swift  # Onboarding flow shell
│   │   ├── OnboardingPageView.swift       # Individual onboarding slide
│   │   ├── LanguageSelectionView.swift    # Language picker
│   │   ├── PreferencesSetupView.swift     # Initial speed unit / limit setup
│   │   ├── PermissionsView.swift          # Location permission request screen
│   │   └── PaywallView.swift              # IAP paywall (UI only, no StoreKit)
│   └── Components/
│       ├── GlassMorphismCard.swift        # Reusable glassmorphism card modifier
│       └── AnimatedButton.swift           # Reusable animated press button
│
├── Utilities/
│   ├── Constants.swift            # App-wide constants, UserDefaults keys
│   ├── LocalizationManager.swift  # Runtime language switching wrapper
│   ├── ThemeManager.swift         # App color theme management
│   └── Haptics.swift              # UIImpactFeedbackGenerator wrapper
│
├── Extensions/
│   ├── Font+Extensions.swift      # Custom font registration (Orbitron, Rajdhani)
│   └── View+Extensions.swift      # SwiftUI View modifier convenience extensions
│
└── Resources/
    ├── Assets.xcassets            # App icon, colors, image assets
    ├── Localizable.strings        # (per .lproj folder, 14 languages)
    └── Fonts/                     # Orbitron-Bold.ttf, Rajdhani-Medium.ttf, Rajdhani-Regular.ttf

SpeedTracker.xcodeproj/
└── project.pbxproj                # Xcode project file
```

---

## Key File Locations by Category

| Category | Files |
|----------|-------|
| App entry | `SpeedTracker/SpeedTrackerApp.swift`, `SpeedTracker/ContentView.swift` |
| GPS / tracking | `SpeedTracker/Services/Location/LocationManager.swift` |
| Data persistence | `SpeedTracker/Services/Storage/TripStore.swift` |
| Notifications | `SpeedTracker/Services/NotificationManager.swift` |
| Main UI | `SpeedTracker/Views/Main/SpeedTrackerView.swift` |
| Tab navigation | `SpeedTracker/Views/Main/MainTabView.swift` |
| HUD mode | `SpeedTracker/Views/Main/HUDModeView.swift` |
| Trip history | `SpeedTracker/Views/History/HistoryView.swift`, `TripDetailView.swift` |
| Settings | `SpeedTracker/Views/Settings/SettingsView.swift` |
| Onboarding | `SpeedTracker/Views/Onboarding/` (6 files) |
| Paywall (stub) | `SpeedTracker/Views/Onboarding/PaywallView.swift` |
| Constants / keys | `SpeedTracker/Utilities/Constants.swift` |
| Localization | `SpeedTracker/Utilities/LocalizationManager.swift` |
| Theming | `SpeedTracker/Utilities/ThemeManager.swift` |
| Custom fonts | `SpeedTracker/Extensions/Font+Extensions.swift` |

---

## Naming Conventions

### Files
- Views: `<Feature>View.swift` (e.g. `HistoryView.swift`, `SettingsView.swift`)
- Services: `<Domain>Manager.swift` or `<Domain>Store.swift`
- ViewModels: `<Feature>ViewModel.swift`
- Models: `<Entity>.swift` (e.g. `TripRecord.swift`)
- Utilities: descriptive noun (e.g. `Haptics.swift`, `Constants.swift`)
- Extensions: `<Type>+Extensions.swift`

### Code Symbols
- Types: `UpperCamelCase`
- Properties/methods: `lowerCamelCase`
- Constants: `lowerCamelCase` (no ALL_CAPS)
- SwiftUI previews: `#Preview` macro (Swift 5.9+)

### Directories
- Lowercase plural for groups: `Views/`, `Models/`, `Services/`, `Extensions/`
- Feature-based subdirectories: `Views/Main/`, `Views/History/`, `Views/Onboarding/`

---

## Adding New Code

| Task | Where to add |
|------|-------------|
| New screen | `SpeedTracker/Views/<Feature>/<Name>View.swift` |
| New service | `SpeedTracker/Services/<Name>Manager.swift` |
| New model | `SpeedTracker/Models/<Entity>.swift` |
| New ViewModel | `SpeedTracker/ViewModels/<Feature>ViewModel.swift` |
| New reusable component | `SpeedTracker/Views/Components/<Name>.swift` |
| New utility | `SpeedTracker/Utilities/<Name>.swift` |
| New extension | `SpeedTracker/Extensions/<Type>+Extensions.swift` |
| New localization string | Add to all `.lproj/Localizable.strings` files |
| New asset | `SpeedTracker/Resources/Assets.xcassets` |
