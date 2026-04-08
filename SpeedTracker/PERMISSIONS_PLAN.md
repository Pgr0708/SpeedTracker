# Permissions Plan

Complete guide for requesting and handling iOS permissions in Speed Tracker.

## Required Permissions

Speed Tracker requires 3 main permissions for full functionality:

1. **Location** (Required)
2. **Motion & Fitness** (Optional, for pedometer)
3. **Notifications** (Optional)

## Permission Strategy

### Philosophy

- **Request when needed**: Show permission dialogs at appropriate times, not all at once
- **Explain first**: Always show custom pre-permission dialog explaining why
- **Graceful degradation**: App remains functional even if permissions denied
- **Easy to fix**: Provide clear path to enable denied permissions

### Timing

**First Launch Flow**:
1. Complete onboarding
2. Complete paywall (or skip)
3. Sign in with Apple
4. Request Location → Request Motion → Request Notifications

**Subsequent Launches**:
- Only request missing permissions
- Don't re-prompt if previously denied (except via settings)

---

## 1. Location Permission

### Why Needed

**Purpose**: Calculate speed, altitude, coordinates, and record trip routes

**Features Requiring Location**:
- Current speed display (core feature)
- Altitude
- Coordinates (lat/long)
- Trip recording
- Route visualization
- Distance tracking

### Permission Type

**Request**: "When In Use" authorization

**Don't Request**: "Always" authorization (not needed, battery drain)

### Info.plist Keys

Add these keys to `Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Speed Tracker uses your location to calculate your current speed and track your trips. Your location is only used while the app is active and is never shared.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Speed Tracker uses your location to calculate speed and record trips. Location is only accessed when you're using the app.</string>
```

### Request Flow

#### Custom Pre-Permission Dialog

Before showing iOS system dialog:

**Title**: "Enable Location Access"

**Icon**: 📍 (location pin)

**Message**: 
```
Speed Tracker needs your location to:

• Calculate your current speed accurately
• Track your trips and routes
• Show altitude and coordinates

Your location is only used while the app is open and is never shared with third parties.
```

**Buttons**:
- Primary: "Enable Location" (blue)
- Secondary: "Not Now" (gray text)

#### Implementation

```swift
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // meters
    }
    
    func requestPermission() {
        // Show custom dialog first
        showCustomLocationDialog { granted in
            if granted {
                // Then show system dialog
                self.locationManager.requestWhenInUseAuthorization()
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            handleLocationDenied()
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}
```

### Handling Denial

If user denies location permission:

**Alert Title**: "Location Access Required"

**Message**: 
```
Speed Tracker needs location access to calculate speed. Without location access, the app cannot function.

Please enable location in Settings.
```

**Buttons**:
- "Open Settings" (opens app settings)
- "Cancel"

**Implementation**:

```swift
func handleLocationDenied() {
    let alert = UIAlertController(
        title: "Location Access Required",
        message: "Speed Tracker needs location access to calculate speed. Please enable location in Settings.",
        preferredStyle: .alert
    )
    
    alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    })
    
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    
    // Present alert
}
```

### Location Accuracy

Request best accuracy for speed calculation:

```swift
locationManager.desiredAccuracy = kCLLocationAccuracyBest
```

**Battery Impact**: Moderate. Acceptable for speed tracking app.

**Optimization**: Reduce accuracy when app is in background or user is stationary.

### Background Location

**Decision**: Do NOT request background location initially

**Reason**: 
- Not needed for core functionality
- Significant battery drain
- Stricter App Review
- Privacy concerns

**Future**: Consider for background trip recording (if requested by users)

---

## 2. Motion & Fitness Permission

### Why Needed

**Purpose**: Count steps, track walking/running activity

**Features Requiring Motion**:
- Pedometer (step counting)
- Distance (walking)
- Calories burned
- Activity type detection

### Permission Type

**Request**: Motion & Fitness access

### Info.plist Keys

```xml
<key>NSMotionUsageDescription</key>
<string>Speed Tracker uses motion data to track your steps, distance, and calories burned during walking and running activities.</string>
```

### Request Flow

#### Custom Pre-Permission Dialog

**Title**: "Enable Motion & Fitness"

**Icon**: 🏃 (runner)

**Message**:
```
Enable motion tracking to:

• Count your steps
• Track walking and running distance
• Calculate calories burned
• Set and achieve fitness goals

This permission is optional. You can still track driving speed without it.
```

**Buttons**:
- Primary: "Enable Motion" (blue)
- Secondary: "Skip" (gray text)

#### Implementation

```swift
import CoreMotion

class PedometerManager: ObservableObject {
    private let pedometer = CMPedometer()
    
    @Published var isAuthorized = false
    
    func requestPermission() {
        showCustomMotionDialog { granted in
            if granted {
                self.checkAuthorization()
            }
        }
    }
    
    func checkAuthorization() {
        // Motion authorization is determined by first use
        // No explicit authorization method like location
        
        if CMPedometer.isStepCountingAvailable() {
            // Start pedometer to trigger permission
            let now = Date()
            pedometer.queryPedometerData(from: now, to: now) { data, error in
                DispatchQueue.main.async {
                    if error == nil {
                        self.isAuthorized = true
                    } else {
                        self.handleMotionDenied()
                    }
                }
            }
        } else {
            showAlert("Pedometer not available on this device")
        }
    }
}
```

### Handling Denial

If user denies motion permission:

**Alert Title**: "Motion Access Denied"

**Message**:
```
The pedometer feature requires motion access. You can still use speed tracking features.

To enable pedometer, go to Settings > Privacy > Motion & Fitness > Speed Tracker
```

**Buttons**:
- "Open Settings"
- "OK"

### Graceful Degradation

**If Motion Denied**:
- Pedometer tab shows lock icon
- Tapping pedometer shows upgrade prompt OR permission request
- All driving features work normally

**Note**: Motion permission is NOT required for speed tracking (uses GPS, not accelerometer)

---

## 3. Notification Permission

### Why Needed

**Purpose**: Notify user of trip completion and speed alerts

**Features Requiring Notifications**:
- Trip saved notification
- Speed limit exceeded alerts (optional)
- Subscription renewal reminders

### Permission Type

**Request**: User Notifications

### Info.plist Keys

No Info.plist entry required for notifications (as of iOS 10+)

### Request Flow

#### Custom Pre-Permission Dialog

**Title**: "Enable Notifications"

**Icon**: 🔔 (bell)

**Message**:
```
Get notified when:

• Your trips are automatically saved
• You exceed your speed limits
• Important app updates

You can customize notification preferences anytime in Settings.
```

**Buttons**:
- Primary: "Enable Notifications" (blue)
- Secondary: "Skip" (gray text)

#### Implementation

```swift
import UserNotifications

class NotificationManager: ObservableObject {
    @Published var isAuthorized = false
    
    func requestPermission() {
        showCustomNotificationDialog { granted in
            if granted {
                self.requestSystemPermission()
            }
        }
    }
    
    func requestSystemPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                
                if !granted {
                    self.handleNotificationDenied()
                }
            }
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
}
```

### Handling Denial

**If User Denies**:
- App works normally
- No notifications sent
- In-app alerts still work (speed limit warnings)
- Show subtle prompt in settings to enable

**No Blocking Alert**: Notifications are truly optional

### Graceful Degradation

**If Notifications Denied**:
- Show in-app trip summaries instead
- Use visual speed alerts only (no notification)
- Settings shows "Notifications: Off" with enable button

---

## Permission Request Order

### Sequential Request Flow

After Apple Sign-In, request permissions in this order:

```
1. Location (most important, blocking)
   ↓
2. Motion (optional, for pedometer)
   ↓
3. Notifications (optional, for alerts)
```

**Timing Between Requests**: 
- Show custom dialog
- Wait for user decision
- Show system dialog (if user agreed)
- Wait for system dialog result
- Move to next permission

**Don't**: Show all custom dialogs at once (overwhelming)

**Do**: Show one at a time with clear explanations

---

## Permission Status Monitoring

### Check Permission Status

On app launch:

```swift
class PermissionManager: ObservableObject {
    @Published var locationAuthorized = false
    @Published var motionAuthorized = false
    @Published var notificationsAuthorized = false
    
    func checkAllPermissions() {
        checkLocationPermission()
        checkMotionPermission()
        checkNotificationPermission()
    }
    
    func checkLocationPermission() {
        let status = CLLocationManager.authorizationStatus()
        locationAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
    }
    
    func checkMotionPermission() {
        motionAuthorized = CMPedometer.isStepCountingAvailable()
    }
    
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsAuthorized = (settings.authorizationStatus == .authorized)
            }
        }
    }
}
```

### Re-Request Strategy

**Location**: 
- If denied: Don't re-request automatically
- Show permanent banner in app with "Enable Location" button
- Button opens Settings

**Motion**:
- If denied: Show lock icon on Pedometer tab
- Tapping opens Settings

**Notifications**:
- If denied: Show toggle in Settings (disabled)
- Tapping shows alert to open Settings

**Never**: Spam user with repeated permission requests

---

## Settings Screen Integration

### Permission Status Display

In Settings screen, show:

```
Permissions
├─ Location: Enabled ✅
├─ Motion & Fitness: Disabled ❌ (Tap to enable)
└─ Notifications: Enabled ✅
```

Tapping disabled permission:
1. Show alert explaining why needed
2. Offer to open Settings
3. User enables in Settings
4. App detects change on next launch/foreground

---

## App Review Considerations

### Apple's Guidelines

1. **Explain before requesting**: ✅ Custom dialogs before system prompts
2. **Request when needed**: ✅ After onboarding, before main usage
3. **Function without**: ✅ Graceful degradation for optional permissions
4. **Don't trick users**: ✅ Clear, honest explanations

### Info.plist Descriptions

Make sure descriptions:
- Are clear and concise
- Explain exact purpose
- Mention privacy (data not shared)
- Are user-friendly (not technical)

---

## Privacy Best Practices

### Data Handling

1. **Location Data**:
   - Only collect when app is in use
   - Store locally (and iCloud for Premium)
   - Never share with third parties
   - Never send to custom servers

2. **Motion Data**:
   - Only collect when pedometer is active
   - Store locally/iCloud
   - Never share

3. **Notifications**:
   - Only local notifications
   - No push notification server

### Privacy Policy

Update privacy policy to clearly state:

```
Location Data:
- Used only to calculate speed and track trips
- Stored locally on your device and in your private iCloud
- Never shared with third parties
- You can disable location access anytime (app won't function without it)

Motion Data:
- Used only for pedometer feature
- Stored locally and in your iCloud
- Never shared with third parties
- Completely optional

Notifications:
- Only local notifications
- No data sent to external servers
- Completely optional
```

---

## Testing Checklist

- [ ] Test location permission grant
- [ ] Test location permission deny
- [ ] Test motion permission grant
- [ ] Test motion permission deny
- [ ] Test notification permission grant
- [ ] Test notification permission deny
- [ ] Test re-enabling denied permissions via Settings
- [ ] Test app functionality with all permissions denied
- [ ] Test app functionality with all permissions granted
- [ ] Test permission status detection on app launch
- [ ] Test permission status changes while app is backgrounded
- [ ] Verify Info.plist descriptions are clear
- [ ] Verify custom dialogs display correctly
- [ ] Verify Settings deep link works
- [ ] Test on multiple iOS versions (15, 16, 17)

---

## Implementation Checklist

- [ ] Add Info.plist keys for Location
- [ ] Add Info.plist key for Motion
- [ ] Create custom permission dialog UI components
- [ ] Implement LocationManager class
- [ ] Implement PedometerManager class
- [ ] Implement NotificationManager class
- [ ] Create PermissionManager to coordinate all permissions
- [ ] Implement sequential permission request flow
- [ ] Implement permission status checking on launch
- [ ] Handle permission denial gracefully
- [ ] Add permission status to Settings screen
- [ ] Implement deep link to iOS Settings
- [ ] Test all permission scenarios
- [ ] Update privacy policy
- [ ] Prepare for App Review with clear permission justifications

---

## Future Enhancements

### Background Location (If Needed)

If users request background trip recording:

**Info.plist Addition**:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>
```

**Justification for App Review**:
"Background location is used to automatically record trips even when the app is not actively open, providing users with complete trip history without manual intervention."

**Battery Impact**: Significant. Offer as opt-in only.

### Activity Tracking (HealthKit)

If adding HealthKit integration for fitness:

**Info.plist Addition**:
```xml
<key>NSHealthShareUsageDescription</key>
<string>Speed Tracker can integrate with Apple Health to share your walking and running data.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>Speed Tracker can save your walking and running activities to Apple Health.</string>
```

**Implementation**: Request after Motion permission, only for pedometer users
