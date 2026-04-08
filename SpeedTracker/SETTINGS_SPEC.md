# Settings Specification

Complete specification for the Settings screen and all configuration options.

## Settings Screen Structure

```
Settings
├── Account
├── Preferences
├── Speed Alerts
├── Notifications
├── Data & Sync
├── Subscription
├── Support & Info
└── Account Actions
```

---

## 1. Account Section

### Display

**Profile Card** (top of screen):
- Profile photo (from Apple ID, circular)
- Name (from Apple ID)
- Email (from Apple ID, grayed out)
- Subscription badge: "Free" or "Premium ✨"
- Edit Profile button (secondary)

### Edit Profile

Tapping "Edit Profile" opens modal:

**Editable Fields**:
- Name (text field)
- Note: "Email cannot be changed (managed by Apple ID)"

**Actions**:
- Save (updates name in local storage, syncs to iCloud)
- Cancel

**Implementation**:
```swift
struct EditProfileView: View {
    @State private var name: String
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                
                Text(user.email ?? "No email")
                    .foregroundColor(.secondary)
            } header: {
                Text("Profile Information")
            } footer: {
                Text("Email is managed by Apple ID and cannot be changed here.")
            }
        }
        .navigationTitle("Edit Profile")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveProfile() }
            }
        }
    }
}
```

---

## 2. Preferences Section

### Language

**Type**: Navigation link → Language Selection Screen

**Display**: Current language (e.g., "English")

**Options**:
- English
- Español (Spanish)
- Français (French)
- Deutsch (German)
- 日本語 (Japanese)
- 中文 (Chinese Simplified)

**Behavior**:
- Selecting new language shows confirmation alert
- "Changing language will restart the app. Continue?"
- On confirm: Save preference → Restart app
- App relaunches in new language

**Implementation**:
```swift
struct LanguageSelectionView: View {
    @State private var selectedLanguage: String
    
    let languages = [
        Language(code: "en", name: "English", flag: "🇺🇸"),
        Language(code: "es", name: "Español", flag: "🇪🇸"),
        Language(code: "fr", name: "Français", flag: "🇫🇷"),
        Language(code: "de", name: "Deutsch", flag: "🇩🇪"),
        Language(code: "ja", name: "日本語", flag: "🇯🇵"),
        Language(code: "zh", name: "中文", flag: "🇨🇳")
    ]
    
    var body: some View {
        List(languages) { language in
            Button {
                confirmLanguageChange(language)
            } label: {
                HStack {
                    Text(language.flag)
                    Text(language.name)
                    Spacer()
                    if language.code == selectedLanguage {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}
```

### Speed Units

**Type**: Picker

**Options**:
- Miles per hour (mph)
- Kilometers per hour (km/h)

**Default**: Based on device region (US = mph, others = km/h)

**Behavior**: Changes immediately, updates all speed displays

**Implementation**:
```swift
Picker("Speed Units", selection: $preferences.speedUnit) {
    Text("mph").tag("mph")
    Text("km/h").tag("kmh")
}
```

### Distance Units

**Type**: Picker

**Options**:
- Miles
- Kilometers

**Default**: Based on device region

**Behavior**: Updates all distance displays

### Temperature Units

**Type**: Picker (Premium only)

**Options**:
- Fahrenheit (°F)
- Celsius (°C)

**Default**: Based on device region

**Behavior**: Updates weather display

### Color Theme (Premium)

**Type**: Navigation link → Color Theme Screen

**Display**: Current theme (e.g., "Ocean Blue")

**Free Users**: Shows lock icon, tapping shows paywall

**Premium Users**: Opens theme selection

**Themes**:
- Default (White on Black)
- Ocean Blue
- Forest Green
- Sunset Orange
- Royal Purple
- Crimson Red
- Custom (future: color picker)

**Preview**: Real-time preview of speed display with selected theme

### Mirror Mode (Premium)

**Type**: Toggle

**Label**: "Mirror Mode"

**Description**: "Flip display horizontally for mounting phone backward"

**Free Users**: Shows lock icon, disabled

**Premium Users**: Toggle enabled

**Behavior**: 
- When ON: All UI elements flip horizontally
- Useful for dashboard mounting
- Persists across app launches

---

## 3. Speed Alerts Section

Navigation link → Speed Alert Settings Screen

### Speed Alert Settings Screen

**Enable Alerts** (Master Toggle):
- Toggle ON/OFF
- When OFF: All alert fields grayed out
- When ON: Fields enabled

**Maximum Speed Limit**:
- Number input (stepper or text field)
- Unit label (mph or km/h based on preference)
- Slider for quick adjustment (0-150 mph / 0-240 km/h)
- Default: 70 mph / 120 km/h

**Minimum Speed Limit**:
- Number input
- Optional (can be disabled)
- Useful for highway driving (alert if going too slow)
- Default: 15 mph / 25 km/h

**Alert Types**:
- Sound Alert (toggle)
  - Play beep sound when limit exceeded
  - Choose sound: "Beep", "Chime", "Alert"
- Vibration Alert (toggle)
  - Vibrate when limit exceeded
  - Pattern: Single pulse
- Visual Alert (always on)
  - Flash screen red/yellow
  - Cannot be disabled

**Test Alert** (button):
- Triggers alert sounds/vibration for testing
- "Tap to test alert"

**Implementation**:
```swift
struct SpeedAlertSettingsView: View {
    @Binding var preferences: UserPreferences
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Speed Alerts", isOn: $preferences.speedAlertsEnabled)
            }
            
            Section {
                HStack {
                    Text("Maximum Speed")
                    Spacer()
                    TextField("Speed", value: $maxSpeed, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    Text(preferences.speedUnit)
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $maxSpeed, in: 0...150, step: 5)
                
                HStack {
                    Text("Minimum Speed")
                    Spacer()
                    TextField("Speed", value: $minSpeed, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    Text(preferences.speedUnit)
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $minSpeed, in: 0...50, step: 5)
            } header: {
                Text("Speed Limits")
            }
            .disabled(!preferences.speedAlertsEnabled)
            
            Section {
                Toggle("Sound Alert", isOn: $preferences.soundAlertsEnabled)
                Toggle("Vibration Alert", isOn: $preferences.vibrationAlertsEnabled)
            } header: {
                Text("Alert Types")
            } footer: {
                Text("Visual alerts are always enabled for safety.")
            }
            .disabled(!preferences.speedAlertsEnabled)
            
            Section {
                Button("Test Alert") {
                    triggerTestAlert()
                }
            }
        }
        .navigationTitle("Speed Alerts")
    }
}
```

---

## 4. Notifications Section

**Enable Notifications** (toggle):
- Master switch for all notifications
- If system permission denied, show "Enable in Settings" button

**Trip Completed** (toggle):
- Notify when trip is saved
- "Your trip has been saved: 25.3 miles, 45 minutes"

**Speed Alert Notifications** (toggle):
- Push notification when speed limit exceeded
- Only works if app is in background

**Weekly Summary** (toggle, future):
- Weekly trip summary
- "This week: 5 trips, 150 miles"

**Permission Status**:
- If denied: Show "Notifications Disabled" with "Enable in Settings" button
- If enabled: Show all toggle options

**Implementation**:
```swift
Section {
    if notificationPermissionGranted {
        Toggle("Trip Completed", isOn: $preferences.tripNotificationsEnabled)
        Toggle("Speed Alerts", isOn: $preferences.speedAlertNotificationsEnabled)
    } else {
        Button("Enable Notifications in Settings") {
            openAppSettings()
        }
    }
} header: {
    Text("Notifications")
} footer: {
    if !notificationPermissionGranted {
        Text("Notifications are currently disabled. Enable them in iOS Settings to receive alerts.")
    }
}
```

---

## 5. Data & Sync Section (Premium)

**iCloud Sync** (toggle):
- Enable/disable iCloud sync
- When OFF: Data stays local only
- When ON: Syncs preferences, trips, pedometer sessions

**Sync Status**:
- "Last Synced: 2 minutes ago"
- "Syncing..." (if in progress)
- "Sync Failed" (with retry button)

**Sync Now** (button):
- Manual sync trigger
- Shows activity indicator while syncing
- Success message or error

**Storage Used**:
- "Using 45 MB of iCloud storage"
- Progress bar showing usage

**Clear Cache** (button, destructive):
- "Clear Local Cache"
- Confirmation alert: "This will remove cached data but keep your trips and settings."
- Only clears non-essential data (map tiles, weather cache)

**Free Users**: Shows upgrade prompt instead of sync options

**Implementation**:
```swift
Section {
    if isPremium {
        Toggle("iCloud Sync", isOn: $preferences.iCloudSyncEnabled)
        
        if preferences.iCloudSyncEnabled {
            HStack {
                Text("Last Synced")
                Spacer()
                Text(lastSyncTimeString)
                    .foregroundColor(.secondary)
            }
            
            Button("Sync Now") {
                syncNow()
            }
            .disabled(isSyncing)
            
            HStack {
                Text("Storage Used")
                Spacer()
                Text(storageUsedString)
                    .foregroundColor(.secondary)
            }
        }
        
        Button("Clear Cache", role: .destructive) {
            showClearCacheConfirmation = true
        }
    } else {
        Button("Upgrade to Premium for iCloud Sync") {
            showPaywall = true
        }
    }
} header: {
    Text("Data & Sync")
}
```

---

## 6. Subscription Section

### Premium Users

**Current Plan**:
- "Premium - Yearly" (or Weekly, Monthly, Lifetime)
- "Renews on: January 15, 2027" (if auto-renewable)
- "Lifetime Access" (if lifetime)

**Manage Subscription** (button):
- Deep link to iOS Settings → Subscriptions
- Opens: Settings.app → Apple ID → Subscriptions → Speed Tracker

**Restore Purchases** (button):
- Restores purchases from App Store
- Shows loading indicator
- Success or failure message

### Free Users

**Upgrade to Premium** (button, prominent):
- Large button at top of section
- "Unlock all features"
- Opens paywall

**Restore Purchases** (button):
- For users who already purchased but not showing premium

**What You'll Get**:
- List of premium features
- Bullet points with checkmarks

**Implementation**:
```swift
Section {
    if isPremium {
        VStack(alignment: .leading, spacing: 8) {
            Text("Premium - \(subscriptionType)")
                .font(.headline)
            
            if let renewalDate = renewalDate {
                Text("Renews on \(renewalDate, style: .date)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Lifetime Access")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
        }
        
        Button("Manage Subscription") {
            openSubscriptionManagement()
        }
        
        Button("Restore Purchases") {
            restorePurchases()
        }
    } else {
        Button {
            showPaywall = true
        } label: {
            Label("Upgrade to Premium", systemImage: "star.fill")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
        
        Button("Restore Purchases") {
            restorePurchases()
        }
        
        // List premium features
        ForEach(premiumFeatures, id: \.self) { feature in
            Label(feature, systemImage: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
    }
} header: {
    Text("Subscription")
}
```

---

## 7. Support & Info Section

**Terms of Service** (link):
- Opens web view or Safari
- URL: https://speedtracker.app/terms

**Privacy Policy** (link):
- Opens web view or Safari
- URL: https://speedtracker.app/privacy

**Conditions of Use** (link):
- Opens web view or Safari
- URL: https://speedtracker.app/conditions

**Rate Us** (button):
- Deep link to App Store review page
- Uses SKStoreReviewController for in-app rating
- Opens App Store if user chooses to write review

**Contact Us** (link):
- Opens web URL in Safari
- URL: https://speedtracker.app/contact
- Or opens email: support@speedtracker.app

**FAQ / Help** (link, future):
- In-app help center
- Common questions answered

**App Version**:
- Display only
- "Version 1.0.0 (Build 42)"

**Implementation**:
```swift
Section {
    Link("Terms of Service", destination: URL(string: "https://speedtracker.app/terms")!)
    Link("Privacy Policy", destination: URL(string: "https://speedtracker.app/privacy")!)
    Link("Conditions of Use", destination: URL(string: "https://speedtracker.app/conditions")!)
    
    Button("Rate Us") {
        requestAppReview()
    }
    
    Link("Contact Us", destination: URL(string: "https://speedtracker.app/contact")!)
    
    HStack {
        Text("App Version")
        Spacer()
        Text(appVersion)
            .foregroundColor(.secondary)
    }
} header: {
    Text("Support & Info")
}
```

---

## 8. Account Actions Section

**Log Out** (button, destructive):
- Red text
- Confirmation alert
- "Are you sure you want to log out? Your data will be synced to iCloud before signing out."
- Cancel / Log Out buttons

**Log Out Flow**:
1. Show confirmation alert
2. If confirmed, trigger iCloud sync
3. Sign out of Apple ID
4. Clear local session
5. Return to Apple Sign-In screen

**Implementation**:
```swift
Section {
    Button("Log Out", role: .destructive) {
        showLogoutConfirmation = true
    }
} header: {
    Text("Account")
}
.alert("Log Out", isPresented: $showLogoutConfirmation) {
    Button("Cancel", role: .cancel) { }
    Button("Log Out", role: .destructive) {
        performLogout()
    }
} message: {
    Text("Your data will be synced to iCloud before signing out.")
}
```

---

## Settings Persistence

All settings saved to:
1. **UserDefaults** (cache)
2. **Core Data** (UserPreferences entity)
3. **CloudKit** (if iCloud sync enabled)

Settings sync across devices automatically for premium users.

---

## Settings Validation

**Speed Limits**:
- Max speed > Min speed
- Max speed: 1-200 mph / 1-320 km/h
- Min speed: 0-100 mph / 0-160 km/h

**If Invalid**:
- Show error message
- Prevent saving
- Revert to last valid value

---

## Accessibility

- All toggles have VoiceOver labels
- All sections have headers
- Color theme previews have accessibility descriptions
- Settings organized logically for screen readers

---

## Testing Checklist

- [ ] Test language change and app restart
- [ ] Test speed unit conversion
- [ ] Test distance unit conversion
- [ ] Test temperature unit conversion (premium)
- [ ] Test color theme selection (premium)
- [ ] Test mirror mode toggle (premium)
- [ ] Test speed alert configuration
- [ ] Test alert sounds and vibration
- [ ] Test notification toggles
- [ ] Test iCloud sync enable/disable (premium)
- [ ] Test manual sync (premium)
- [ ] Test cache clearing
- [ ] Test subscription management deep link
- [ ] Test restore purchases
- [ ] Test rate us (App Store review)
- [ ] Test all web links (terms, privacy, contact)
- [ ] Test logout flow with sync
- [ ] Test settings persistence across app restarts
- [ ] Test settings sync across devices (premium)
- [ ] Test free user upgrade flow from settings
