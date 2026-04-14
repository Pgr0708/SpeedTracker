# Coding Conventions

**Analysis Date:** 2026-04-14

## Naming Patterns

**Files:**
- PascalCase for all Swift files (e.g., `SpeedTrackerView.swift`, `LocationManager.swift`)
- File names match the primary class/struct name
- No hyphens or underscores in file names
- Grouped by functional area (Views, Models, Services, Utilities, Extensions, Components)

**Functions:**
- camelCase for all functions and methods
- Descriptive verbs: `startTracking()`, `stopTracking()`, `convertedSpeed(_:unit:)`
- Getter methods without "get" prefix: `var hasLocationPermission: Bool` not `getHasLocationPermission()`
- Action methods use present tense: `nextPage()`, `completeOnboarding()`, `resetSession()`

**Variables:**
- camelCase for all properties and local variables
- Private properties prefixed with underscore: `private var _phase: CGFloat`, `private var previousLocation: CLLocation?`
- Published properties in ObservableObject classes use `@Published` prefix pattern: `@Published var currentSpeed: Double`
- AppStorage keys use snake_case in string constants: `AppConstants.UserDefaultsKeys.isHapticEnabled`

**Types:**
- PascalCase for all struct, class, enum, and protocol names
- Enums use lowercase raw values: `enum ThemeColor: String { case blue = "blue" }`
- Extension names follow source type: `extension Color`, `extension View`, `extension LocationManager`
- Protocol names are PascalCase: `Identifiable`, `Codable`, `ObservableObject`

**Constants:**
- PascalCase for enum cases: `case blue`, `case kmh`, `case english`
- UPPERCASE for static string keys: `static let hasSelectedLanguage = "hasSelectedLanguage"`
- Nested enums organize constants logically (see `AppConstants` structure)

## Code Style

**Formatting:**
- 4-space indentation (Xcode default)
- Brace style: opening brace on same line (Apple Swift style)
- Lines generally kept under 120 characters (soft limit)
- No trailing whitespace
- Spaces around operators: `x > 5`, `y = 10`, not `x>5` or `y=10`

**Linting:**
- No explicit linter configured; relies on Xcode's built-in Swift Analysis
- Code follows Swift 5.x conventions and best practices
- Compiler warnings treated as errors in production code

## Import Organization

**Order:**
1. Swift standard library (Foundation, Combine, UIKit)
2. SwiftUI (SwiftUI)
3. Apple frameworks (CoreLocation, MapKit, CoreData)
4. Internal imports (marked as `internal import _LocationEssentials`)

**Example from codebase:**
```swift
import SwiftUI
internal import _LocationEssentials

import Foundation
import CoreLocation
import Combine
```

**Path Aliases:**
- No path aliases or abbreviations used; full paths preferred for clarity
- No local package imports or SPM dependencies detected

## Error Handling

**Patterns:**
- Silent error handling with optional returns: Functions like `stopTracking()` return `TripRecord?` to indicate success/failure
- Print-based logging for non-critical errors: `print("Location error: \(error.localizedDescription)")`
- Guard statements for validation: `guard hasLocationPermission else { requestPermission(); return }`
- Early returns prevent deep nesting: See `startTracking()` in `LocationManager.swift`
- No try-catch blocks found; uses Optional and guard patterns instead
- GPS accuracy filtering with explicit threshold checks: `guard location.horizontalAccuracy >= 0, location.horizontalAccuracy < 50 else { return }`

**Null safety:**
- Defensive nil coalescing: `startLocation?.coordinate.latitude ?? 0`
- Use of `guard let` for critical unwrapping: `guard let start = self.trackingStartTime else { return }`
- Force unwraps avoided except in previews: `#Preview { }` blocks may use `!`

## Logging

**Framework:** Built-in `print()` only

**Patterns:**
- Minimal logging; only critical errors logged
- Error description included: `print("Location error: \(error.localizedDescription)")`
- No debug logging for user interactions
- No performance or timing logs
- All logging at `print()` level (no structured logging)

## Comments

**When to Comment:**
- File headers with `//  FileName.swift` format and brief purpose
- Section markers using `// MARK: -` for major functional divisions
- Complex algorithms or non-obvious calculations (rare in this codebase)
- GPS thresholds and magic numbers explained: `// Movement threshold (m/s) - ~3 km/h to filter noise`

**JSDoc/TSDoc:**
- No documentation comments used
- Parameter or return value documentation absent
- Comments are structural only (MARK sections) or clarify intent

**Example:**
```swift
// MARK: - Tracking Control
func startTracking() {
    // Movement threshold (m/s) - ~3 km/h to filter noise
    private let movementThreshold: Double = 0.8
}
```

## Function Design

**Size:** 
- Functions typically 10-50 lines
- Single responsibility principle observed
- Long functions (~50+ lines) broken into computed properties or helper functions
- Example: `LocationManager` has 200 lines total, split into clear sections via MARK

**Parameters:**
- Positional parameters used; no named parameter enforcement outside of closures
- Related parameters grouped together
- Closures as trailing parameters: `Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in ... }`
- Weak self captures to prevent memory leaks in escaping closures

**Return Values:**
- Single return values preferred
- Optional returns for fallible operations: `TripRecord?`, `CLLocation?`
- No tuple returns for multi-value results; uses custom structs instead
- Void returns for state mutations: `func nextPage()`, `func startTracking()`

## Module Design

**Exports:**
- All top-level types are public by default (no explicit `public` keyword used in codebase)
- Private types use `private` keyword: `private class`, `private var`
- Internal implementation details marked `private` to hide from consumers
- Extensions on standard types marked `public` implicitly (e.g., `Color(hex:)`)

**Barrel Files:**
- No barrel export pattern used
- Each module imports only what it needs
- No re-export files detected

## Architecture Patterns

**View Models:**
- ObservableObject pattern used: Classes with `@Published` properties
- All ViewModels marked `@MainActor`: Ensures UI updates on main thread
- Combine framework used for reactive state: No SwiftUI @State in ViewModels

**Singletons:**
- Singleton pattern extensively used with `static let shared`
- Examples: `LocationManager.shared`, `ThemeManager.shared`, `TripStore.shared`, `HapticManager.shared`
- Singletons use `private init()` to enforce single instance
- All singletons marked `@MainActor`

**State Management:**
- AppStorage for persistence: `@AppStorage(AppConstants.UserDefaultsKeys.isDarkModeEnabled)`
- EnvironmentObject for theme propagation: `.environmentObject(themeManager)`
- Private @State for local view state: Used in Views only, not ViewModels
- Published properties in ObservableObject for reactive updates

**Composition:**
- Computed properties for derived state: `var displaySpeed`, `var speedColor`
- Small reusable components: `StatCard`, `TabBarButton`, `GlassMorphismCard`
- View hierarchies nested with clear section organization via MARK

---

*Convention analysis: 2026-04-14*
