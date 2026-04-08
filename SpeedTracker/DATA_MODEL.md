# Data Model

Comprehensive data structures for Speed Tracker's local storage and iCloud sync.

## Storage Strategy

**Local Storage**: Core Data (SQLite)
**Cloud Storage**: CloudKit
**Caching**: UserDefaults (preferences only)
**Sensitive Data**: Keychain (Apple User ID)

## Core Data Entities

### 1. User Entity

**Purpose**: Store user profile information from Apple ID

**Attributes**:
- `id`: String (UUID, primary key)
- `appleUserID`: String (unique, from Sign in with Apple)
- `email`: String (optional, from Apple)
- `name`: String (optional, from Apple)
- `createdAt`: Date
- `lastLoginAt`: Date

**Relationships**: 
- One-to-many with Trip
- One-to-many with PedometerSession
- One-to-one with UserPreferences

**CloudKit Sync**: No (user profile managed by Apple)

---

### 2. UserPreferences Entity

**Purpose**: Store user settings and customization

**Attributes**:
- `id`: String (UUID, primary key)
- `userID`: String (foreign key to User)
- `language`: String (ISO 639-1 code, e.g., "en", "es")
- `speedUnit`: String ("mph" or "kmh")
- `distanceUnit`: String ("miles" or "km")
- `temperatureUnit`: String ("fahrenheit" or "celsius")
- `maxSpeedLimit`: Double (in m/s, convert for display)
- `minSpeedLimit`: Double (in m/s)
- `speedAlertsEnabled`: Bool
- `soundAlertsEnabled`: Bool
- `vibrationAlertsEnabled`: Bool
- `notificationsEnabled`: Bool
- `mirrorMode`: Bool
- `colorTheme`: String ("default", "blue", "green", "red", "purple")
- `lastModified`: Date
- `syncedToCloud`: Bool
- `needsSync`: Bool

**Relationships**:
- One-to-one with User

**CloudKit Sync**: Yes (all attributes)

**Default Values**:
```swift
language: Locale.current.languageCode ?? "en"
speedUnit: Locale.current.usesMetricSystem ? "kmh" : "mph"
distanceUnit: Locale.current.usesMetricSystem ? "km" : "miles"
temperatureUnit: Locale.current.usesMetricSystem ? "celsius" : "fahrenheit"
maxSpeedLimit: 120.0 km/h (33.33 m/s)
minSpeedLimit: 0.0
speedAlertsEnabled: true
soundAlertsEnabled: true
vibrationAlertsEnabled: true
notificationsEnabled: false
mirrorMode: false
colorTheme: "default"
```

---

### 3. Trip Entity (Premium)

**Purpose**: Store driving session data

**Attributes**:
- `id`: String (UUID, primary key)
- `userID`: String (foreign key to User)
- `startDate`: Date
- `endDate`: Date
- `duration`: Double (seconds)
- `distance`: Double (meters)
- `averageSpeed`: Double (m/s)
- `maxSpeed`: Double (m/s)
- `minSpeed`: Double (m/s)
- `startLatitude`: Double
- `startLongitude`: Double
- `endLatitude`: Double
- `endLongitude`: Double
- `startAddress`: String (geocoded)
- `endAddress`: String (geocoded)
- `routeData`: Data (compressed coordinate array)
- `speedData`: Data (compressed speed points with timestamps)
- `altitudeData`: Data (compressed altitude points)
- `createdAt`: Date
- `modifiedAt`: Date
- `syncedToCloud`: Bool
- `needsSync`: Bool

**Relationships**:
- Many-to-one with User

**CloudKit Sync**: Yes (Premium only)

**Session Rules**:
- Session starts when: speed > 3 mph (1.34 m/s)
- Session ends when: stopped for 5+ minutes OR app closed
- Minimum duration: 2 minutes
- Auto-save on session end

**Data Compression**:
Route and speed data compressed using zlib to save space.

---

### 4. SpeedPoint (Embedded in Trip)

**Purpose**: Individual speed measurement during trip

**Structure** (not Core Data entity, encoded in Trip.speedData):
```swift
struct SpeedPoint: Codable {
    let timestamp: Date
    let speed: Double // m/s
    let latitude: Double
    let longitude: Double
    let altitude: Double // meters
    let accuracy: Double // meters
    let heading: Double // degrees
}
```

**Sampling Rate**: 1 point per second (or 1 per 10 meters, whichever is less frequent)

**Storage**: Array encoded as Data, compressed

---

### 5. PedometerSession Entity (Premium)

**Purpose**: Store walking/running session data

**Attributes**:
- `id`: String (UUID, primary key)
- `userID`: String (foreign key to User)
- `startDate`: Date
- `endDate`: Date
- `duration`: Double (seconds)
- `steps`: Int64
- `distance`: Double (meters)
- `averageSpeed`: Double (m/s)
- `calories`: Double (estimated)
- `pace`: Double (seconds per km or mile)
- `stepGoal`: Int64
- `goalAchieved`: Bool
- `activityType`: String ("walking", "running", "hiking")
- `createdAt`: Date
- `modifiedAt`: Date
- `syncedToCloud`: Bool
- `needsSync`: Bool

**Relationships**:
- Many-to-one with User

**CloudKit Sync**: Yes (Premium only)

**Calorie Calculation**:
```
Calories = (MET × weight_kg × duration_hours)

Walking MET: 3.5
Running MET: 7.0-12.0 (speed dependent)

User weight: Ask on first pedometer use, store in UserPreferences
```

---

### 6. AppState (UserDefaults)

**Purpose**: Store transient app state

**Keys**:
- `hasCompletedOnboarding`: Bool
- `hasSeenPaywall`: Bool
- `isPremium`: Bool (cached from RevenueCat)
- `lastAppVersion`: String
- `totalTripsRecorded`: Int
- `totalDistanceTraveled`: Double
- `totalStepsCounted`: Int64

**Storage**: UserDefaults (not Core Data)

**CloudKit Sync**: No (device-specific)

---

## Data Relationships

```
User (1) ──┬── (∞) Trip
           │
           ├── (∞) PedometerSession
           │
           └── (1) UserPreferences
```

---

## Core Data Schema (Swift)

### User

```swift
@Model
class User {
    @Attribute(.unique) var id: String
    @Attribute(.unique) var appleUserID: String
    var email: String?
    var name: String?
    var createdAt: Date
    var lastLoginAt: Date
    
    @Relationship(deleteRule: .cascade) var trips: [Trip]
    @Relationship(deleteRule: .cascade) var pedometerSessions: [PedometerSession]
    @Relationship(deleteRule: .cascade) var preferences: UserPreferences?
    
    init(appleUserID: String, email: String?, name: String?) {
        self.id = UUID().uuidString
        self.appleUserID = appleUserID
        self.email = email
        self.name = name
        self.createdAt = Date()
        self.lastLoginAt = Date()
    }
}
```

### UserPreferences

```swift
@Model
class UserPreferences {
    @Attribute(.unique) var id: String
    var userID: String
    
    var language: String
    var speedUnit: String
    var distanceUnit: String
    var temperatureUnit: String
    
    var maxSpeedLimit: Double
    var minSpeedLimit: Double
    var speedAlertsEnabled: Bool
    var soundAlertsEnabled: Bool
    var vibrationAlertsEnabled: Bool
    var notificationsEnabled: Bool
    var mirrorMode: Bool
    var colorTheme: String
    
    var lastModified: Date
    var syncedToCloud: Bool
    var needsSync: Bool
    
    @Relationship(inverse: \User.preferences) var user: User?
    
    init(userID: String) {
        self.id = UUID().uuidString
        self.userID = userID
        
        // Set defaults based on locale
        let locale = Locale.current
        let isMetric = locale.usesMetricSystem
        
        self.language = locale.languageCode ?? "en"
        self.speedUnit = isMetric ? "kmh" : "mph"
        self.distanceUnit = isMetric ? "km" : "miles"
        self.temperatureUnit = isMetric ? "celsius" : "fahrenheit"
        
        self.maxSpeedLimit = 33.33 // 120 km/h
        self.minSpeedLimit = 0.0
        self.speedAlertsEnabled = true
        self.soundAlertsEnabled = true
        self.vibrationAlertsEnabled = true
        self.notificationsEnabled = false
        self.mirrorMode = false
        self.colorTheme = "default"
        
        self.lastModified = Date()
        self.syncedToCloud = false
        self.needsSync = true
    }
}
```

### Trip

```swift
@Model
class Trip {
    @Attribute(.unique) var id: String
    var userID: String
    
    var startDate: Date
    var endDate: Date
    var duration: Double
    
    var distance: Double
    var averageSpeed: Double
    var maxSpeed: Double
    var minSpeed: Double
    
    var startLatitude: Double
    var startLongitude: Double
    var endLatitude: Double
    var endLongitude: Double
    
    var startAddress: String
    var endAddress: String
    
    @Attribute(.externalStorage) var routeData: Data
    @Attribute(.externalStorage) var speedData: Data
    @Attribute(.externalStorage) var altitudeData: Data
    
    var createdAt: Date
    var modifiedAt: Date
    var syncedToCloud: Bool
    var needsSync: Bool
    
    @Relationship(inverse: \User.trips) var user: User?
    
    // Computed properties
    var routeCoordinates: [CLLocationCoordinate2D] {
        get { decompressCoordinates(routeData) }
        set { routeData = compressCoordinates(newValue) }
    }
    
    var speedPoints: [SpeedPoint] {
        get { decodeSpeedPoints(speedData) }
        set { speedData = encodeSpeedPoints(newValue) }
    }
    
    init(userID: String, startDate: Date) {
        self.id = UUID().uuidString
        self.userID = userID
        self.startDate = startDate
        self.endDate = startDate
        self.duration = 0
        self.distance = 0
        self.averageSpeed = 0
        self.maxSpeed = 0
        self.minSpeed = 0
        self.startLatitude = 0
        self.startLongitude = 0
        self.endLatitude = 0
        self.endLongitude = 0
        self.startAddress = ""
        self.endAddress = ""
        self.routeData = Data()
        self.speedData = Data()
        self.altitudeData = Data()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.syncedToCloud = false
        self.needsSync = true
    }
}
```

### PedometerSession

```swift
@Model
class PedometerSession {
    @Attribute(.unique) var id: String
    var userID: String
    
    var startDate: Date
    var endDate: Date
    var duration: Double
    
    var steps: Int64
    var distance: Double
    var averageSpeed: Double
    var calories: Double
    var pace: Double
    
    var stepGoal: Int64
    var goalAchieved: Bool
    var activityType: String
    
    var createdAt: Date
    var modifiedAt: Date
    var syncedToCloud: Bool
    var needsSync: Bool
    
    @Relationship(inverse: \User.pedometerSessions) var user: User?
    
    init(userID: String, startDate: Date, stepGoal: Int64) {
        self.id = UUID().uuidString
        self.userID = userID
        self.startDate = startDate
        self.endDate = startDate
        self.duration = 0
        self.steps = 0
        self.distance = 0
        self.averageSpeed = 0
        self.calories = 0
        self.pace = 0
        self.stepGoal = stepGoal
        self.goalAchieved = false
        self.activityType = "walking"
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.syncedToCloud = false
        self.needsSync = true
    }
}
```

---

## Data Conversion Utilities

### Speed Conversion

```swift
enum SpeedUnit: String {
    case mph = "mph"
    case kmh = "kmh"
    
    func convert(speedInMetersPerSecond: Double) -> Double {
        switch self {
        case .mph:
            return speedInMetersPerSecond * 2.23694 // m/s to mph
        case .kmh:
            return speedInMetersPerSecond * 3.6 // m/s to km/h
        }
    }
    
    func toMetersPerSecond(speed: Double) -> Double {
        switch self {
        case .mph:
            return speed / 2.23694
        case .kmh:
            return speed / 3.6
        }
    }
}
```

### Distance Conversion

```swift
enum DistanceUnit: String {
    case miles = "miles"
    case km = "km"
    
    func convert(distanceInMeters: Double) -> Double {
        switch self {
        case .miles:
            return distanceInMeters * 0.000621371 // m to miles
        case .km:
            return distanceInMeters / 1000.0 // m to km
        }
    }
    
    func toMeters(distance: Double) -> Double {
        switch self {
        case .miles:
            return distance / 0.000621371
        case .km:
            return distance * 1000.0
        }
    }
}
```

### Temperature Conversion

```swift
enum TemperatureUnit: String {
    case fahrenheit = "fahrenheit"
    case celsius = "celsius"
    
    func convert(celsius: Double) -> Double {
        switch self {
        case .fahrenheit:
            return (celsius * 9/5) + 32
        case .celsius:
            return celsius
        }
    }
}
```

---

## Data Validation

### Trip Validation

```swift
extension Trip {
    var isValid: Bool {
        guard duration >= 120 else { return false } // min 2 minutes
        guard distance > 0 else { return false }
        guard endDate > startDate else { return false }
        guard averageSpeed > 0 else { return false }
        return true
    }
}
```

### Pedometer Session Validation

```swift
extension PedometerSession {
    var isValid: Bool {
        guard duration >= 60 else { return false } // min 1 minute
        guard steps > 0 else { return false }
        guard endDate > startDate else { return false }
        return true
    }
}
```

---

## Data Migration

### Version 1.0 → 1.1 (Example)

If adding new field to UserPreferences:

```swift
// Migration policy
static func migrateV1toV1_1() {
    // Add new field with default value
    // Core Data handles this automatically with lightweight migration
}
```

**Migration Strategy**: Use Core Data lightweight migration when possible

---

## Data Retention Policy

### Free Users

- **Trips**: Store last 5 locally, delete older
- **Preferences**: Keep all
- **Pedometer**: Not available

### Premium Users

- **Trips**: Store all locally + iCloud
- **Preferences**: Keep all, sync to iCloud
- **Pedometer**: Store all locally + iCloud

### After Subscription Expires

- **Keep** all historical data (read-only)
- **New trips**: Limited to last 5 (old premium trips preserved)
- **iCloud sync**: Paused (local data remains)

### User Deletion

On logout or account deletion:
- Sync all data to iCloud
- Delete local data (except cached preferences)
- iCloud data persists (user's Apple ID)

---

## Data Size Estimates

### Single Trip (1 hour drive at 60 mph)

- Metadata: ~500 bytes
- Route coordinates (3600 points): ~60 KB compressed
- Speed data: ~50 KB compressed
- **Total per trip**: ~110 KB

**100 trips**: ~11 MB
**1000 trips**: ~110 MB

### Single Pedometer Session (30 min walk)

- Metadata: ~300 bytes
- **Total per session**: ~500 bytes

**100 sessions**: ~50 KB
**1000 sessions**: ~500 KB

### Total Storage (Heavy User)

- 1000 trips: 110 MB
- 500 pedometer sessions: 250 KB
- Preferences: 10 KB
- **Total**: ~110 MB (well under 1GB iCloud limit)

---

## Database Indexes

For optimal query performance:

**Trip Entity**:
- Index on `startDate` (for sorting)
- Index on `userID` (for filtering)
- Compound index on `userID + startDate`

**PedometerSession Entity**:
- Index on `startDate`
- Index on `userID`

**UserPreferences Entity**:
- Index on `userID`

---

## Testing Data

### Sample Data for Development

```swift
static func createSampleData() {
    let user = User(appleUserID: "test123", email: "test@example.com", name: "Test User")
    
    let prefs = UserPreferences(userID: user.id)
    
    let trip1 = Trip(userID: user.id, startDate: Date().addingTimeInterval(-3600))
    trip1.endDate = Date()
    trip1.duration = 3600
    trip1.distance = 80000 // 80 km
    trip1.averageSpeed = 22.22 // 80 km/h
    trip1.maxSpeed = 30.56 // 110 km/h
    trip1.startAddress = "123 Main St"
    trip1.endAddress = "456 Elm St"
    
    // Add to context and save
}
```

---

## Implementation Checklist

- [ ] Set up Core Data model in Xcode
- [ ] Create User entity
- [ ] Create UserPreferences entity
- [ ] Create Trip entity
- [ ] Create PedometerSession entity
- [ ] Implement data conversion utilities
- [ ] Set up database indexes
- [ ] Implement data validation
- [ ] Set up CloudKit schema (mirrors Core Data)
- [ ] Implement sync logic
- [ ] Test data compression/decompression
- [ ] Test migration (add test field)
- [ ] Create sample data for development
- [ ] Implement data retention policies
- [ ] Add data export capability (Premium)
