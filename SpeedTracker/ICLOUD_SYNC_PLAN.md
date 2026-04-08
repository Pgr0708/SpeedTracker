# iCloud Sync Plan

Comprehensive strategy for syncing Speed Tracker data across devices using iCloud without a custom backend.

## Why iCloud?

**Advantages**:
- No custom server required
- No backend costs
- Automatic sync across user's devices
- Tied to Apple ID (already authenticated)
- Built-in conflict resolution
- Encrypted by default
- No database management

**Limitations**:
- Only works within Apple ecosystem
- Limited to 1GB per app (plenty for this use case)
- Requires iCloud account with storage
- Sync delays (not instant, typically seconds to minutes)
- No cross-platform support (iOS/macOS only)

## Data to Sync

### Always Sync (Free + Premium)
1. **User Preferences**
   - Language selection
   - Speed units (mph/km/h)
   - Distance units (miles/km)
   - Temperature units (°F/°C)
   - Speed limit alert settings (max/min values)
   - Sound alert toggle
   - Vibration alert toggle
   - Notification preferences
   - Mirror mode preference

### Premium Only Sync
2. **Trip History**
   - All recorded driving sessions
   - Route coordinates
   - Speed data points
   - Trip metadata

3. **Pedometer Sessions**
   - Walking/running session data
   - Step counts and goals
   - Pedometer preferences

4. **Customizations**
   - Color theme selections
   - Custom theme configurations

## iCloud Technology Choice: CloudKit

Use **CloudKit** (not iCloud Key-Value Storage or iCloud Drive).

**Why CloudKit**:
- Structured data storage (like a database)
- Supports complex queries
- Better for large datasets
- Handles relationships between entities
- Built-in conflict resolution
- More storage capacity

**Not Using**:
- ❌ iCloud Key-Value Storage: Limited to 1MB total, only for small preferences
- ❌ iCloud Drive: File-based, overkill for structured data
- ✅ CloudKit: Perfect for structured app data

## CloudKit Container Setup

### 1. Enable iCloud in Xcode

1. Select project target
2. Go to "Signing & Capabilities"
3. Add "iCloud" capability
4. Enable "CloudKit"
5. Create container: `iCloud.com.speedtracker.app`

### 2. Configure CloudKit Dashboard

1. Open CloudKit Dashboard: https://icloud.developer.apple.com/dashboard
2. Select container: `iCloud.com.speedtracker.app`
3. Create record types (schemas)
4. Set up indexes for queries
5. Configure security roles

## Data Model (CloudKit Schema)

### Record Type: `UserPreferences`

**Fields**:
- `userID` (String, indexed) - Apple User ID
- `language` (String) - Selected language code
- `speedUnit` (String) - "mph" or "kmh"
- `distanceUnit` (String) - "miles" or "km"
- `temperatureUnit` (String) - "fahrenheit" or "celsius"
- `maxSpeedLimit` (Double) - Maximum speed alert value
- `minSpeedLimit` (Double) - Minimum speed alert value
- `soundAlertsEnabled` (Int64) - 0 or 1
- `vibrationAlertsEnabled` (Int64) - 0 or 1
- `notificationsEnabled` (Int64) - 0 or 1
- `mirrorMode` (Int64) - 0 or 1
- `colorTheme` (String) - Theme identifier
- `lastModified` (Date) - For conflict resolution

**Indexes**: `userID`
**Security**: Private database (user-specific)

### Record Type: `Trip` (Premium)

**Fields**:
- `userID` (String, indexed)
- `tripID` (String, indexed) - UUID
- `startDate` (Date, indexed)
- `endDate` (Date)
- `duration` (Double) - seconds
- `distance` (Double) - meters
- `averageSpeed` (Double) - m/s
- `maxSpeed` (Double) - m/s
- `startAddress` (String)
- `endAddress` (String)
- `startLatitude` (Double)
- `startLongitude` (Double)
- `endLatitude` (Double)
- `endLongitude` (Double)
- `routeData` (Bytes) - Compressed coordinate array
- `speedData` (Bytes) - Compressed speed points
- `createdAt` (Date)
- `modifiedAt` (Date)

**Indexes**: `userID`, `tripID`, `startDate`
**Security**: Private database

### Record Type: `PedometerSession` (Premium)

**Fields**:
- `userID` (String, indexed)
- `sessionID` (String, indexed) - UUID
- `startDate` (Date, indexed)
- `endDate` (Date)
- `steps` (Int64)
- `distance` (Double) - meters
- `calories` (Double)
- `duration` (Double) - seconds
- `averageSpeed` (Double) - m/s
- `stepGoal` (Int64)
- `createdAt` (Date)
- `modifiedAt` (Date)

**Indexes**: `userID`, `sessionID`, `startDate`
**Security**: Private database

## Sync Strategy

### Initial Sync (First Launch After Sign-In)

```swift
func performInitialSync() async {
    // 1. Check if user has data in iCloud
    let hasCloudData = await checkForCloudData()
    
    if hasCloudData {
        // 2. Pull all data from iCloud
        await pullUserPreferences()
        
        if isPremium {
            await pullTripHistory()
            await pullPedometerSessions()
        }
    } else {
        // 3. Push local data to iCloud (if any)
        await pushUserPreferences()
        
        if isPremium {
            await pushTripHistory()
            await pushPedometerSessions()
        }
    }
}
```

### Continuous Sync

**Strategy**: Push changes immediately, pull periodically

**Push Triggers**:
- User changes preference → immediate push
- Trip completes → immediate push
- Pedometer session ends → immediate push
- App enters background → push pending changes

**Pull Triggers**:
- App launches → pull updates
- App enters foreground → pull updates
- Every 5 minutes while app is active → pull updates
- User taps "Sync Now" in settings → pull updates

### Conflict Resolution

**Strategy**: Last-Write-Wins with timestamp

```swift
func resolveConflict(localRecord: CKRecord, cloudRecord: CKRecord) -> CKRecord {
    let localModified = localRecord["lastModified"] as? Date ?? Date.distantPast
    let cloudModified = cloudRecord["lastModified"] as? Date ?? Date.distantPast
    
    // Keep most recent
    return localModified > cloudModified ? localRecord : cloudRecord
}
```

**Edge Case**: If timestamps are equal (very rare), prefer cloud version.

## Implementation

### 1. CloudKit Manager Class

```swift
import CloudKit

class CloudKitManager {
    static let shared = CloudKitManager()
    
    private let container = CKContainer(identifier: "iCloud.com.speedtracker.app")
    private var privateDatabase: CKDatabase {
        container.privateCloudDatabase
    }
    
    // MARK: - User Preferences
    
    func savePreferences(_ prefs: UserPreferences) async throws {
        let record = CKRecord(recordType: "UserPreferences")
        record["userID"] = prefs.userID
        record["language"] = prefs.language
        record["speedUnit"] = prefs.speedUnit
        record["maxSpeedLimit"] = prefs.maxSpeedLimit
        record["minSpeedLimit"] = prefs.minSpeedLimit
        record["soundAlertsEnabled"] = prefs.soundAlertsEnabled ? 1 : 0
        record["vibrationAlertsEnabled"] = prefs.vibrationAlertsEnabled ? 1 : 0
        record["notificationsEnabled"] = prefs.notificationsEnabled ? 1 : 0
        record["mirrorMode"] = prefs.mirrorMode ? 1 : 0
        record["colorTheme"] = prefs.colorTheme
        record["lastModified"] = Date()
        
        try await privateDatabase.save(record)
    }
    
    func fetchPreferences(for userID: String) async throws -> UserPreferences? {
        let predicate = NSPredicate(format: "userID == %@", userID)
        let query = CKQuery(recordType: "UserPreferences", predicate: predicate)
        
        let results = try await privateDatabase.records(matching: query)
        
        guard let (_, result) = results.matchResults.first,
              let record = try? result.get() else {
            return nil
        }
        
        return UserPreferences(from: record)
    }
    
    // MARK: - Trips
    
    func saveTrip(_ trip: Trip) async throws {
        let record = CKRecord(recordType: "Trip", recordID: CKRecord.ID(recordName: trip.id))
        record["userID"] = trip.userID
        record["tripID"] = trip.id
        record["startDate"] = trip.startDate
        record["endDate"] = trip.endDate
        record["duration"] = trip.duration
        record["distance"] = trip.distance
        record["averageSpeed"] = trip.averageSpeed
        record["maxSpeed"] = trip.maxSpeed
        record["startAddress"] = trip.startAddress
        record["endAddress"] = trip.endAddress
        record["startLatitude"] = trip.startLatitude
        record["startLongitude"] = trip.startLongitude
        record["endLatitude"] = trip.endLatitude
        record["endLongitude"] = trip.endLongitude
        record["routeData"] = compressCoordinates(trip.routeCoordinates)
        record["speedData"] = compressSpeedData(trip.speedPoints)
        record["createdAt"] = trip.createdAt
        record["modifiedAt"] = Date()
        
        try await privateDatabase.save(record)
    }
    
    func fetchTrips(for userID: String, limit: Int = 100) async throws -> [Trip] {
        let predicate = NSPredicate(format: "userID == %@", userID)
        let query = CKQuery(recordType: "Trip", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        
        let results = try await privateDatabase.records(matching: query, desiredKeys: nil, resultsLimit: limit)
        
        var trips: [Trip] = []
        for (_, result) in results.matchResults {
            if let record = try? result.get() {
                trips.append(Trip(from: record))
            }
        }
        
        return trips
    }
    
    func deleteTrip(tripID: String) async throws {
        let recordID = CKRecord.ID(recordName: tripID)
        try await privateDatabase.deleteRecord(withID: recordID)
    }
    
    // MARK: - Pedometer Sessions
    
    func savePedometerSession(_ session: PedometerSession) async throws {
        // Similar to saveTrip
    }
    
    func fetchPedometerSessions(for userID: String) async throws -> [PedometerSession] {
        // Similar to fetchTrips
    }
}
```

### 2. Data Compression

To save storage and bandwidth, compress coordinate arrays:

```swift
func compressCoordinates(_ coordinates: [CLLocationCoordinate2D]) -> Data {
    // Convert to Data and compress using zlib
    var data = Data()
    for coord in coordinates {
        var lat = coord.latitude
        var lon = coord.longitude
        data.append(Data(bytes: &lat, count: MemoryLayout<Double>.size))
        data.append(Data(bytes: &lon, count: MemoryLayout<Double>.size))
    }
    
    return data.compress(using: .zlib) // Custom extension
}

func decompressCoordinates(_ data: Data) -> [CLLocationCoordinate2D] {
    let decompressed = data.decompress(using: .zlib)
    var coordinates: [CLLocationCoordinate2D] = []
    
    let stride = MemoryLayout<Double>.size * 2
    for i in stride(from: 0, to: decompressed.count, by: stride) {
        let lat = decompressed[i..<i+8].withUnsafeBytes { $0.load(as: Double.self) }
        let lon = decompressed[i+8..<i+16].withUnsafeBytes { $0.load(as: Double.self) }
        coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
    }
    
    return coordinates
}
```

### 3. Sync State Management

Track sync status in UI:

```swift
class SyncManager: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?
    
    func sync() async {
        await MainActor.run { isSyncing = true }
        
        do {
            try await CloudKitManager.shared.syncAll()
            await MainActor.run {
                lastSyncDate = Date()
                syncError = nil
            }
        } catch {
            await MainActor.run {
                syncError = error
            }
        }
        
        await MainActor.run { isSyncing = false }
    }
}
```

## Handling Edge Cases

### 1. No Internet Connection

```swift
func saveTrip(_ trip: Trip) async throws {
    do {
        try await CloudKitManager.shared.saveTrip(trip)
    } catch {
        // Check if network error
        if (error as NSError).domain == CKErrorDomain {
            // Queue for later sync
            queueForLaterSync(trip)
        } else {
            throw error
        }
    }
}

func syncQueuedItems() async {
    guard isConnectedToInternet() else { return }
    
    let queuedTrips = getQueuedTrips()
    for trip in queuedTrips {
        try? await CloudKitManager.shared.saveTrip(trip)
    }
    
    clearSyncQueue()
}
```

### 2. iCloud Not Available

```swift
func checkiCloudStatus() async -> Bool {
    let status = try? await CKContainer(identifier: "iCloud.com.speedtracker.app").accountStatus()
    
    switch status {
    case .available:
        return true
    case .noAccount:
        showAlert("Please sign in to iCloud in Settings to sync your data.")
        return false
    case .restricted:
        showAlert("iCloud is restricted on this device.")
        return false
    case .couldNotDetermine:
        showAlert("Unable to determine iCloud status.")
        return false
    default:
        return false
    }
}
```

### 3. Storage Quota Exceeded

```swift
func handleQuotaExceeded() {
    // Delete oldest trips if quota exceeded
    // Keep most recent 100 trips in cloud
    // Keep all trips locally
    
    showAlert("iCloud storage full. Oldest trips will remain on this device only.")
}
```

### 4. User Changes Devices

When user signs in on new device:

1. Pull all data from iCloud
2. Merge with any local data
3. Resolve conflicts
4. Save merged data locally
5. Push any unique local data to iCloud

### 5. User Logs Out

```swift
func handleLogout() {
    // Sync all pending changes
    await CloudKitManager.shared.syncAll()
    
    // Clear local cache (preferences remain)
    clearLocalData()
    
    // Sign out
    signOut()
}
```

## Data Migration

If changing CloudKit schema:

1. **Add new field**: Use default value for old records
2. **Rename field**: Migrate data with CloudKit batch operations
3. **Delete field**: Remove from code, keep in CloudKit (ignored)
4. **Change type**: Create new field, migrate data, deprecate old field

**Migration Strategy**:
```swift
func migrateToV2() async {
    // Fetch all records
    // Update with new fields
    // Save back to CloudKit
}
```

## Testing iCloud Sync

### 1. Development Testing

- Use different Apple IDs on simulator and device
- Sign out and sign in to test initial sync
- Enable/disable internet to test offline queue
- Delete app and reinstall to test data restoration

### 2. CloudKit Dashboard

- View all records in production/development environments
- Manually query data
- Delete test data
- Monitor quota usage

### 3. Automated Tests

```swift
func testPreferenceSync() async throws {
    let prefs = UserPreferences(...)
    
    // Save to CloudKit
    try await CloudKitManager.shared.savePreferences(prefs)
    
    // Fetch from CloudKit
    let fetched = try await CloudKitManager.shared.fetchPreferences(for: prefs.userID)
    
    // Verify
    XCTAssertEqual(prefs.language, fetched?.language)
    XCTAssertEqual(prefs.speedUnit, fetched?.speedUnit)
}
```

## Performance Optimization

### 1. Batch Operations

Instead of saving one record at a time:

```swift
func saveTrips(_ trips: [Trip]) async throws {
    let records = trips.map { trip in
        // Convert trip to CKRecord
    }
    
    try await privateDatabase.modifyRecords(saving: records, deleting: [])
}
```

### 2. Lazy Loading

Don't fetch all trips on launch:

```swift
func fetchRecentTrips(limit: Int = 20) async throws -> [Trip] {
    // Only fetch recent trips
}

func fetchMoreTrips(lastDate: Date) async throws -> [Trip] {
    // Pagination for older trips
}
```

### 3. Background Sync

Use background tasks to sync periodically:

```swift
func scheduleBackgroundSync() {
    let request = BGAppRefreshTaskRequest(identifier: "com.speedtracker.sync")
    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
    
    try? BGTaskScheduler.shared.submit(request)
}
```

## Privacy & Security

### 1. Data Encryption

CloudKit encrypts data at rest and in transit automatically.

**Additional Encryption** (optional):
- Encrypt sensitive fields before saving
- Use CryptoKit for client-side encryption

### 2. Privacy Policy

Update privacy policy to mention:
- iCloud sync is optional (user can disable)
- Data stored in user's private iCloud
- Apple has access (per iCloud terms)
- No sharing with third parties

### 3. User Control

Provide toggle in settings:

```swift
Toggle("Enable iCloud Sync", isOn: $iCloudSyncEnabled)
    .onChange(of: iCloudSyncEnabled) { enabled in
        if enabled {
            enableiCloudSync()
        } else {
            disableiCloudSync()
        }
    }
```

## Monitoring & Analytics

Track sync metrics:

- Sync success rate
- Sync duration
- Conflict resolution frequency
- Network errors
- Quota usage

Use CloudKit Dashboard and custom analytics (RevenueCat, Firebase Analytics, or TelemetryDeck).

## Implementation Checklist

- [ ] Enable iCloud capability in Xcode
- [ ] Create CloudKit container
- [ ] Define record types in CloudKit Dashboard
- [ ] Create indexes for queries
- [ ] Implement CloudKitManager class
- [ ] Implement sync logic for preferences
- [ ] Implement sync logic for trips (Premium)
- [ ] Implement sync logic for pedometer (Premium)
- [ ] Handle offline queue
- [ ] Handle conflicts
- [ ] Test on multiple devices
- [ ] Test offline/online transitions
- [ ] Update privacy policy
- [ ] Add sync status UI
- [ ] Test quota limits
- [ ] Implement background sync
- [ ] Test account status changes
- [ ] Handle migration if needed

## Future Enhancements

- **CloudKit Shared Database**: For future social features
- **CKSubscriptions**: Real-time notifications when data changes
- **CloudKit JS**: If adding web dashboard later
- **Family Sharing**: Share trips with family members
