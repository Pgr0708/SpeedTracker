# User Flows

## Flow 1: First-Time User Experience

```
1. App Launch
   ↓
2. Splash Screen (2-3 seconds)
   - Show app logo
   - Show tagline: "Track Your Journey"
   ↓
3. Language Selection
   - Display supported languages
   - User selects preferred language
   - Default: Device language
   ↓
4. Onboarding Carousel (4 screens)
   - Screen 1: "Real-Time Speed Tracking"
   - Screen 2: "Review Your Trips"
   - Screen 3: "HUD Mode for Safe Driving"
   - Screen 4: "Track Walking & Running"
   - Swipe to navigate, Skip button on top-right
   ↓
5. Paywall Screen
   - Show subscription options (Weekly, Monthly, Yearly, Lifetime)
   - Highlight "Yearly with 3-day trial" as recommended
   - Close/Skip button (X icon) in top-right
   - "Continue with Free" button at bottom
   ↓
6. Apple ID Sign-In
   - "Sign in with Apple" button
   - Privacy message: "Your email will not be shared"
   - Handle sign-in success/failure
   ↓
7. Permission Requests (Sequential)
   a. Location Permission
      - Show custom dialog explaining why
      - Request "While Using the App" permission
      - Handle allow/deny
   
   b. Motion & Fitness Permission (for pedometer)
      - Show custom dialog
      - Request motion access
      - Handle allow/deny
   
   c. Notification Permission
      - Show custom dialog
      - Request notification access
      - Handle allow/deny
   ↓
8. Home Screen
   - Show speed tracking interface
   - Display tutorial tooltip if first time
   - Ready to track
```

## Flow 2: Returning Free User

```
1. App Launch
   ↓
2. Splash Screen (brief)
   ↓
3. Check Authentication Status
   - If signed in → Home Screen
   - If signed out → Apple ID Sign-In
   ↓
4. Home Screen
   - Load previous preferences
   - Restore last UI state
   - Sync with iCloud in background
```

## Flow 3: Returning Premium User

```
1. App Launch
   ↓
2. Splash Screen (brief)
   ↓
3. Check Authentication Status
   - If signed in → Home Screen
   - If signed out → Apple ID Sign-In
   ↓
4. Sync Subscription Status (RevenueCat)
   - Verify active subscription
   - Sync across devices
   ↓
5. Sync iCloud Data
   - Pull latest trip history
   - Sync user preferences
   - Resolve conflicts if any
   ↓
6. Home Screen (Premium)
   - Full dashboard with all metrics
   - Access to all premium features
```

## Flow 4: Starting a Drive Session

```
1. User opens app
   ↓
2. Home Screen displayed
   ↓
3. GPS acquires location
   - Show "Acquiring GPS..." status
   - Display GPS accuracy indicator
   ↓
4. Start moving (speed > 3 mph/5 km/h)
   - Auto-detect session start
   - Begin recording trip (if Premium)
   - Display current speed
   ↓
5. During Drive
   - Update speed continuously
   - Update other metrics (Premium)
   - Check speed limits
   - Trigger alerts if limits exceeded
   - Record GPS coordinates (Premium)
   ↓
6. Stop (speed = 0 for 5+ minutes)
   - Auto-detect session end
   - Save trip to history (Premium)
   - Show trip summary notification (Premium)
   - Free: Continue showing current speed
```

## Flow 5: Activating HUD Mode

```
1. User is on Home Screen
   ↓
2. User taps HUD button
   ↓
3. Check if Premium
   - If Free → Show paywall
   - If Premium → Continue
   ↓
4. Enter HUD Mode
   - Flip screen horizontally (mirror)
   - Maximize brightness
   - Disable auto-lock
   - Show large speed number
   - Hide other UI elements
   ↓
5. Exit HUD Mode
   - Swipe down from top
   - Return to normal view
   - Restore brightness
   - Re-enable auto-lock
```

## Flow 6: Viewing Trip History

```
1. User taps History tab
   ↓
2. Check if Premium
   - If Free → Show last 5 trips + upgrade prompt
   - If Premium → Show all trips
   ↓
3. Display Trip List
   - Sort by date (newest first)
   - Show trip summaries
   ↓
4. User taps a trip
   ↓
5. Display Trip Detail
   - Show Apple Maps with route
   - Display speed graph
   - Show all trip metrics
   - Option to delete trip
   ↓
6. User can:
   - View map in full screen
   - Export trip data (Premium)
   - Delete trip (swipe or button)
   - Share trip summary (Premium)
```

## Flow 7: Using Pedometer

```
1. User taps Pedometer tab
   ↓
2. Check if Premium
   - If Free → Show paywall
   - If Premium → Continue
   ↓
3. Pedometer Screen
   - Display current step count
   - Show distance, calories, time
   - Show progress toward goal
   ↓
4. User taps "Start Walking"
   - Begin tracking session
   - Update metrics in real-time
   - Save to history
   ↓
5. User taps "Stop"
   - End session
   - Save to history
   - Show session summary
   ↓
6. View Pedometer History
   - List of walking/running sessions
   - Detail view with metrics
```

## Flow 8: Purchasing Subscription

```
1. User encounters paywall
   - From onboarding, OR
   - From premium feature tap, OR
   - From settings upgrade button
   ↓
2. Display Subscription Options
   - Weekly: $2.99/week
   - Monthly: $7.99/month
   - Yearly: $49.99/year (3-day trial)
   - Lifetime: $99.99
   ↓
3. User selects plan
   ↓
4. User taps "Subscribe" or "Start Free Trial"
   ↓
5. Apple Payment Sheet
   - Face ID / Touch ID authentication
   - Confirm purchase
   ↓
6. RevenueCat processes purchase
   - Validate receipt
   - Grant premium access
   - Sync status to all devices
   ↓
7. Success
   - Show confirmation message
   - Unlock premium features immediately
   - Close paywall
   ↓
8. Return to previous screen
   - If from feature tap → Open that feature
   - If from settings → Update settings UI
   - If from onboarding → Continue to home
```

## Flow 9: Restore Purchase

```
1. User taps "Restore Purchase" in settings
   ↓
2. Contact RevenueCat
   - Check Apple receipt
   - Verify subscription status
   ↓
3. If active subscription found
   - Grant premium access
   - Sync to all devices
   - Show success message
   ↓
4. If no subscription found
   - Show "No purchases to restore"
   - Offer to purchase
```

## Flow 10: Logout Flow

```
1. User taps "Log Out" in settings
   ↓
2. Show confirmation dialog
   - "Are you sure you want to log out?"
   - "Your data will be synced to iCloud"
   - Cancel / Log Out buttons
   ↓
3. If user confirms
   - Trigger iCloud sync
   - Clear local session
   - Sign out of Apple ID
   - Clear sensitive data from memory
   ↓
4. Return to Apple Sign-In screen
   ↓
5. On next launch
   - Show Apple Sign-In button
   - Restore data after sign-in
```

## Flow 11: Setting Speed Limit Alerts

```
1. User taps Settings
   ↓
2. User taps "Speed Limit Alerts"
   ↓
3. Alert Settings Screen
   - Toggle: Enable Alerts (On/Off)
   - Input: Maximum Speed Limit
   - Input: Minimum Speed Limit (optional)
   - Toggle: Sound Alert (On/Off)
   - Toggle: Vibration Alert (On/Off)
   ↓
4. User sets values
   - e.g., Max: 70 mph, Min: 15 mph
   ↓
5. Save to iCloud
   ↓
6. Return to Settings
   ↓
7. During Drive
   - If speed > 70 mph → Alert triggered
   - If speed < 15 mph (moving) → Alert triggered
   - Play sound if enabled
   - Vibrate if enabled
   - Show visual indicator
```

## Flow 12: Changing Language

```
1. User taps Settings
   ↓
2. User taps "Language"
   ↓
3. Language Selection Screen
   - List of supported languages
   - Current language highlighted
   ↓
4. User selects new language
   ↓
5. Show confirmation
   - "Change language to Spanish?"
   - This will restart the app
   ↓
6. User confirms
   - Save preference to iCloud
   - Reload app with new language
   - Preserve all other state
```

## Flow 13: Handling Permission Denials

### Location Permission Denied

```
1. User denies location permission
   ↓
2. Show alert
   - "Speed Tracker needs location access"
   - "We use your location only to calculate speed"
   - Open Settings / Cancel buttons
   ↓
3. If user taps "Open Settings"
   - Deep link to app settings in iOS Settings
   ↓
4. If user enables location
   - App detects permission change
   - Refresh UI
   - Start tracking
```

### Motion Permission Denied

```
1. User denies motion permission
   ↓
2. Pedometer feature disabled
   - Show locked icon
   - Explain why permission is needed
   ↓
3. User can still use speed tracking
```

### Notification Permission Denied

```
1. User denies notification permission
   ↓
2. App still works normally
   - No trip summary notifications
   - No speed alert notifications
   - In-app alerts still work
```

## Flow 14: Handling Network Loss

```
1. User is driving (offline)
   ↓
2. Speed tracking works normally
   - GPS doesn't require internet
   - All core features work
   ↓
3. Features that require internet:
   - Weather: Show last cached data
   - Map tiles: Show cached tiles
   - iCloud sync: Queue for later
   ↓
4. When connection restored
   - Sync queued data to iCloud
   - Update weather
   - Download missing map tiles
   - Show subtle sync indicator
```

## Flow 15: Handling Subscription Expiration

```
1. Premium user's subscription expires
   ↓
2. RevenueCat webhook notifies app
   ↓
3. On next app launch
   - Detect expired subscription
   - Downgrade to free tier
   ↓
4. Free tier limitations applied
   - History limited to 5 trips
   - HUD mode locked
   - Pedometer locked
   - Advanced metrics hidden
   ↓
5. Show gentle upgrade prompt
   - "Your premium subscription has expired"
   - "Renew to keep full access"
   - Renew / Continue with Free
   ↓
6. Existing data preserved
   - Trip history still accessible (last 5)
   - Preferences maintained
   - Can re-subscribe anytime to restore access
```
