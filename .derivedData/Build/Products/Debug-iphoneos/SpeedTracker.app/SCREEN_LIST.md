# Screen List

Complete list of all screens in the Speed Tracker app with descriptions and key UI elements.

## 1. Splash Screen

**Purpose**: Brand introduction and app loading

**UI Elements**:
- App logo (centered)
- Tagline: "Track Your Journey"
- Loading indicator (subtle)
- App version number (bottom)

**Duration**: 2-3 seconds (skip if app launches quickly)

**Navigation**: Auto-transitions to Language Selection (first launch) or Home (returning user)

---

## 2. Language Selection Screen

**Purpose**: Let user choose preferred language

**UI Elements**:
- Title: "Choose Your Language"
- List of languages with flags:
  - 🇺🇸 English
  - 🇪🇸 Español (Spanish)
  - 🇫🇷 Français (French)
  - 🇩🇪 Deutsch (German)
  - 🇯🇵 日本語 (Japanese)
  - 🇨🇳 中文 (Chinese Simplified)
- Continue button
- Auto-select device language by default

**Navigation**: Continue → Onboarding Screen

---

## 3. Onboarding Screen (Carousel)

**Purpose**: Introduce key features to new users

### Screen 3.1: Welcome
- Title: "Real-Time Speed Tracking"
- Illustration: Speedometer graphic
- Description: "Monitor your speed accurately with GPS technology"

### Screen 3.2: History
- Title: "Review Your Trips"
- Illustration: Map with route
- Description: "See where you've been with detailed trip history and maps"

### Screen 3.3: HUD Mode
- Title: "HUD Mode for Safe Driving"
- Illustration: Windshield projection
- Description: "Project your speed on the windshield with mirrored display"

### Screen 3.4: Pedometer
- Title: "Track Walking & Running"
- Illustration: Person walking
- Description: "Monitor steps, distance, and calories burned"

**UI Elements**:
- Page indicators (dots)
- Skip button (top-right)
- Next button (bottom-right)
- Get Started button (on last screen)

**Navigation**: 
- Skip → Paywall Screen
- Get Started → Paywall Screen

---

## 4. Paywall Screen

**Purpose**: Present subscription options

**UI Elements**:
- Close button (X icon, top-right)
- Title: "Unlock Premium Features"
- Feature list with checkmarks:
  - ✓ Full speed dashboard
  - ✓ Unlimited trip history
  - ✓ HUD mode
  - ✓ Pedometer tracking
  - ✓ Route maps and graphs
  - ✓ iCloud sync
  - ✓ Advanced customization

**Subscription Cards**:
1. Weekly - $2.99/week
2. Monthly - $7.99/month (Save 15%)
3. Yearly - $49.99/year (Save 60%) + "3-Day Free Trial" badge
4. Lifetime - $99.99 one-time (Best Value)

**Bottom Elements**:
- Primary CTA: "Start Free Trial" (for yearly) or "Subscribe"
- Secondary: "Continue with Free" (text button)
- Fine print: Terms, Privacy, Restore Purchase
- "Not sure? Try free version first"

**Navigation**:
- Subscribe → Apple Payment → Home Screen
- Continue with Free → Apple Sign-In
- Close (X) → Apple Sign-In

---

## 5. Apple Sign-In Screen

**Purpose**: Authenticate user with Apple ID

**UI Elements**:
- App logo
- Title: "Welcome to Speed Tracker"
- Subtitle: "Sign in to sync your data across devices"
- "Sign in with Apple" button (Apple-styled)
- Privacy note: "We respect your privacy. Your email is secure."
- Terms & Privacy links

**Navigation**: Sign-in success → Permission Requests → Home Screen

---

## 6. Permission Request Screens

### 6.1 Location Permission
**Custom Dialog Before System Prompt**:
- Title: "Enable Location Access"
- Icon: Location pin
- Explanation: "Speed Tracker needs your location to calculate speed and track trips"
- Primary: "Enable Location"
- Secondary: "Not Now"

**Then**: Trigger iOS system permission dialog

### 6.2 Motion Permission
**Custom Dialog**:
- Title: "Enable Motion & Fitness"
- Icon: Running person
- Explanation: "Track your steps and walking distance with the pedometer feature"
- Primary: "Enable Motion"
- Secondary: "Skip"

### 6.3 Notification Permission
**Custom Dialog**:
- Title: "Enable Notifications"
- Icon: Bell
- Explanation: "Get notified when trips are completed and speed limits are exceeded"
- Primary: "Enable Notifications"
- Secondary: "Skip"

**Navigation**: All permissions complete → Home Screen

---

## 7. Home Screen (Main Tracking Interface)

**Purpose**: Live speed tracking and primary app interface

### Free Version UI:

**Top Bar**:
- App title: "Speed Tracker"
- Settings icon (top-right)
- Menu/hamburger (top-left)

**Main Display**:
- Large speed number (centered, bold)
- Unit label below (mph/km/h)
- GPS accuracy indicator (top)
- Unit toggle switch (mph ⇄ km/h)

**Bottom Tab Bar**:
- Home (active)
- History (shows "5" badge for free tier)
- Pedometer (locked icon)
- Settings

### Premium Version UI:

**Additional Elements**:
- HUD Mode button (top-right, next to settings)
- Dashboard card with metrics:
  - Current Speed (large, primary)
  - Altitude
  - Distance Traveled
  - Average Speed
  - Max Speed
  - Coordinates (Lat/Long)
  - GPS Accuracy
  - Heading/Bearing
  - Compass display
  - Weather widget (temp + icon)
- Speed graph (mini, expandable)
- Session timer (if trip active)

**Bottom Tab Bar**:
- Home (active)
- History (no limit badge)
- Pedometer (unlocked)
- Settings

**States**:
- Idle: "Tap to Start" or auto-detect movement
- Acquiring GPS: "Acquiring GPS..." with spinner
- Tracking: Live speed updates
- Speed Alert: Red/yellow background flash

---

## 8. HUD Mode Screen (Premium)

**Purpose**: Windshield projection for safe driving

**UI Elements**:
- Full-screen black background
- Mirrored (flipped) speed number (huge, white)
- Unit label (mirrored)
- Minimal UI
- Swipe-down gesture area to exit

**Behavior**:
- Brightness: Max
- Auto-lock: Disabled
- Orientation: Locked
- Text: Mirrored horizontally

**Navigation**: Swipe down → Exit to Home Screen

---

## 9. History Screen

**Purpose**: View past trip recordings

### Free Version:

**UI Elements**:
- Title: "Trip History"
- Filter/sort button
- List of last 5 trips:
  - Date & time
  - Starting address (geocoded)
  - Duration
  - Distance
  - Tap to view details
- Upgrade banner: "Unlock unlimited history"

### Premium Version:

**UI Elements**:
- Title: "Trip History"
- Search bar
- Filter/sort options:
  - Date range picker
  - Sort: Newest, Oldest, Longest, Shortest
- List of all trips (infinite scroll)
- Swipe to delete
- Export all trips button

**Empty State**:
- Illustration: Empty road
- Message: "No trips yet. Start driving to record your first trip!"

**Navigation**: Tap trip → Trip Detail Screen

---

## 10. Trip Detail Screen (Premium)

**Purpose**: View detailed information about a specific trip

**UI Elements**:

**Map Section**:
- Apple Maps with route polyline
- Start pin (green)
- End pin (red)
- Full-screen map button

**Metrics Section**:
- Date & Time
- Duration (HH:MM:SS)
- Total Distance
- Average Speed
- Maximum Speed
- Starting Address
- Ending Address

**Speed Graph**:
- Line chart showing speed over time
- X-axis: Time
- Y-axis: Speed
- Highlight max speed point

**Altitude Graph**:
- Line chart showing elevation changes

**Actions**:
- Share trip button
- Export trip data button
- Delete trip button (destructive)

**Navigation**: Back button → History Screen

---

## 11. Pedometer Screen (Premium)

**Purpose**: Track walking/running metrics

**UI Elements**:

**Current Session Card**:
- Steps (large number)
- Distance
- Time elapsed
- Calories burned
- Current speed
- Pace (min/mile or min/km)

**Goal Progress**:
- Circular progress indicator
- Daily step goal (configurable)
- Percentage complete

**Controls**:
- Start Walking button (green)
- Stop button (red, when active)
- Pause button

**Pedometer History**:
- List of past walking/running sessions
- Similar format to trip history

**Settings**:
- Set step goal
- Set calorie calculation parameters (weight, height)

**Empty State**:
- Illustration: Walking person
- Message: "Start your first walk to track steps!"

---

## 12. Settings Screen

**Purpose**: App configuration and support

**UI Elements**:

**Account Section**:
- User name (from Apple ID)
- User email (from Apple ID)
- Edit Profile button
- Subscription status badge (Free/Premium)
- Upgrade button (if free)

**Preferences**:
- Language
- Speed Units (mph/km/h)
- Color Theme (Premium) →
- Mirror Mode toggle (Premium)
- Distance Units (miles/km)
- Temperature Units (°F/°C)

**Speed Alerts**:
- Enable Alerts toggle
- Maximum Speed Limit (number input)
- Minimum Speed Limit (number input)
- Sound Alerts toggle
- Vibration toggle
- Test Alert button

**Notifications**:
- Enable Notifications toggle
- Trip Completed Notifications
- Speed Alert Notifications

**Data & Sync**:
- iCloud Sync toggle
- Last Synced: timestamp
- Sync Now button
- Clear Cache button

**Subscription** (if Premium):
- Current Plan display
- Renew/Manage button → App Store
- Restore Purchase button

**Support & Info**:
- Terms of Service →
- Privacy Policy →
- Conditions of Use →
- Rate Us (App Store link)
- Contact Us (web URL)
- FAQ/Help
- App Version

**Account Actions**:
- Log Out (destructive)

**Navigation**: Each item → Detail/Action screen

---

## 13. Color Theme Screen (Premium)

**Purpose**: Customize speed display appearance

**UI Elements**:
- Preview card showing speed with selected theme
- Theme options (grid):
  - Default (White on Black)
  - Ocean Blue
  - Forest Green
  - Sunset Orange
  - Royal Purple
  - Gradient themes
- Save button

**Navigation**: Save → Back to Settings

---

## 14. Speed Alert Settings Screen

**Purpose**: Configure speed limit alerts

**UI Elements**:
- Enable Alerts toggle (master switch)
- Maximum Speed section:
  - Number input
  - Unit display (mph/km/h)
  - Slider for quick adjustment
- Minimum Speed section:
  - Number input
  - Enable toggle
- Alert Type:
  - Sound toggle
  - Vibration toggle
  - Visual only option
- Test Alert button
- Preview of alert sound
- Save button

**Navigation**: Save → Back to Settings

---

## 15. Edit Profile Screen

**Purpose**: Modify user information from Apple ID

**UI Elements**:
- Profile photo (from Apple ID, not editable)
- Name (editable)
- Email (from Apple ID, display only)
- Note: "Name changes sync to iCloud"
- Save button
- Cancel button

**Navigation**: Save → Back to Settings

---

## 16. Terms/Privacy/Conditions Screens

**Purpose**: Display legal documents

**UI Elements**:
- Title bar with back button
- Scrollable web view or native text
- Content loaded from web or bundled

**Navigation**: Back → Settings

---

## 17. Contact Us Screen

**Purpose**: Support and feedback

**UI Elements**:
- Opens web URL in Safari or in-app browser
- URL: https://speedtracker.app/contact (example)

**Navigation**: Close → Back to Settings

---

## 18. Restore Purchase Screen

**Purpose**: Restore previous subscription

**UI Elements**:
- Loading indicator during restore
- Success message:
  - "Purchase Restored!"
  - "Premium features unlocked"
  - Continue button
- Failure message:
  - "No purchases found"
  - "Would you like to subscribe?"
  - Subscribe button

**Navigation**: Continue → Settings or Home

---

## 19. Error/Alert Modals

### No Internet Connection
- Title: "No Internet Connection"
- Message: "Some features require internet. Speed tracking will continue to work."
- Action: OK

### GPS Not Available
- Title: "GPS Unavailable"
- Message: "Unable to acquire GPS signal. Please ensure location services are enabled."
- Action: Open Settings / Cancel

### Subscription Failed
- Title: "Purchase Failed"
- Message: "There was a problem processing your subscription. Please try again."
- Action: Try Again / Cancel

### iCloud Sync Failed
- Title: "Sync Failed"
- Message: "Unable to sync with iCloud. Your data is safe locally."
- Action: Retry / Dismiss

---

## Screen Navigation Map

```
Splash
  ↓
Language Selection
  ↓
Onboarding (4 screens)
  ↓
Paywall ←→ (can be dismissed)
  ↓
Apple Sign-In
  ↓
Permissions (3 dialogs)
  ↓
Home Screen (tab 1)
  ├─ History (tab 2)
  │   └─ Trip Detail
  ├─ Pedometer (tab 3)
  └─ Settings (tab 4)
      ├─ Language Selection
      ├─ Color Theme
      ├─ Speed Alert Settings
      ├─ Edit Profile
      ├─ Terms/Privacy/Conditions
      ├─ Contact Us
      └─ Restore Purchase

HUD Mode (overlay from Home)
```

## Total Screen Count

- **Onboarding Flow**: 6 screens
- **Main Tabs**: 4 screens
- **Detail Screens**: 3 screens
- **Settings Subsections**: 6 screens
- **Modals/Overlays**: 5 screens

**Total: ~24 unique screens**
