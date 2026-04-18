# Product Requirements Document

## Product Vision

Speed Tracker is a privacy-focused iOS speed monitoring application that helps drivers and pedestrians track their movement metrics without the complexity of traditional account management or backend infrastructure.

## Business Goals

1. Generate recurring revenue through subscriptions
2. Achieve 20%+ free-to-paid conversion rate
3. Maintain 4.5+ App Store rating
4. Build a sustainable app with minimal operational costs
5. Create a foundation for future driving-related features

## Target Users

### Primary Personas

**Persona 1: Daily Commuter Dave**
- Age: 30-45
- Drives 45+ minutes daily
- Wants to avoid speeding tickets
- Values privacy
- Willing to pay for premium features

**Persona 2: Fitness Enthusiast Emma**
- Age: 25-40
- Walks/runs regularly
- Tracks all fitness metrics
- Wants consolidated tracking
- Prefers Apple ecosystem

**Persona 3: Cautious Driver Carol**
- Age: 50-65
- Drives in residential areas
- Needs speed limit reminders
- Prefers simple interfaces
- Values reliability over features

## Functional Requirements

### FR-1: Authentication

**FR-1.1** - App must support Sign in with Apple only
- No email/password login
- No Google/Facebook login
- No manual account creation

**FR-1.2** - On first launch, prompt for Apple ID sign-in
**FR-1.3** - After logout, require Apple ID sign-in on next launch
**FR-1.4** - Store Apple user identifier securely in Keychain
**FR-1.5** - Handle sign-in failures gracefully with retry option

### FR-2: Onboarding Flow

**FR-2.1** - Display splash screen with app branding (2-3 seconds)
**FR-2.2** - Show language selection screen with at least:
- English
- Spanish
- French
- German
- Japanese
- Chinese (Simplified)

**FR-2.3** - Present 3-4 onboarding screens explaining:
- Screen 1: Live speed tracking
- Screen 2: Trip history and maps
- Screen 3: HUD mode for windshield
- Screen 4: Pedometer and fitness tracking

**FR-2.4** - Show dismissible paywall after onboarding
**FR-2.5** - Request permissions in logical order

### FR-3: Live Speed Tracking

**FR-3.1** - Display current speed in large, readable font
**FR-3.2** - Show speed in selected units (mph or km/h)
**FR-3.3** - Update speed in real-time (1-2 second refresh rate)

**FR-3.4** - Premium: Show additional metrics:
- Altitude (in meters or feet)
- Distance traveled (session)
- Average speed
- Maximum speed
- Minimum speed
- Latitude/Longitude coordinates
- GPS accuracy indicator
- Current heading/bearing

**FR-3.5** - Free: Show current speed only with unit selection

### FR-4: HUD Mode (Premium)

**FR-4.1** - Mirror the speed display for windshield projection
**FR-4.2** - Show large speed number in high contrast
**FR-4.3** - Minimize other UI elements
**FR-4.4** - Keep screen brightness at maximum
**FR-4.5** - Prevent screen auto-lock during HUD mode
**FR-4.6** - Toggle HUD mode with single tap
**FR-4.7** - Exit HUD mode with swipe down gesture

### FR-5: Speed Customization

**FR-5.1** - Allow speed unit selection (mph/km/h)
**FR-5.2** - Premium: Provide color themes for speed display:
- Default (white/black)
- Blue
- Green
- Red
- Purple
- Custom gradient options

**FR-5.3** - Save user preferences to iCloud
**FR-5.4** - Apply default values if user skips customization:
- Default unit: mph (US) or km/h (based on device region)
- Default color: white on black
- Default language: device language

### FR-6: Speed Limit Alerts

**FR-6.1** - Allow users to set maximum speed limit
**FR-6.2** - Allow users to set minimum speed limit
**FR-6.3** - Play sound alert when limits are crossed
**FR-6.4** - Provide vibration feedback when limits are crossed
**FR-6.5** - Provide mute toggle in settings
**FR-6.6** - Allow separate mute for sound and vibration
**FR-6.7** - Show visual indicator when speed limit is exceeded

### FR-7: Compass (Premium)

**FR-7.1** - Display compass heading in degrees
**FR-7.2** - Show cardinal direction (N, NE, E, SE, S, SW, W, NW)
**FR-7.3** - Update compass in real-time
**FR-7.4** - Require device magnetometer calibration if needed

### FR-8: Weather (Premium)

**FR-8.1** - Display current temperature
**FR-8.2** - Show weather condition icon (sunny, cloudy, rainy, etc.)
**FR-8.3** - Use WeatherKit for iOS 16+ devices
**FR-8.4** - Fall back to OpenWeatherMap API for iOS 15 devices
**FR-8.5** - Update weather every 15 minutes
**FR-8.6** - Cache last known weather data
**FR-8.7** - Handle weather API failures gracefully

### FR-9: Mirror Mode (Premium)

**FR-9.1** - Flip entire UI horizontally for mirror reflection
**FR-9.2** - Useful for mounting phone backward on dashboard
**FR-9.3** - Toggle with settings switch
**FR-9.4** - Persist mirror preference to iCloud

### FR-10: Trip History (Premium)

**FR-10.1** - Automatically save each driving session
**FR-10.2** - Define session rules:
- Session starts when speed > 3 mph/5 km/h
- Session ends when stopped for 5+ minutes
- Minimum session duration: 2 minutes

**FR-10.3** - Display trip list with:
- Date and start time
- Duration
- Starting location (reverse geocoded address)
- Ending location
- Total distance
- Average speed
- Maximum speed

**FR-10.4** - Free tier: Show last 5 trips only
**FR-10.5** - Premium tier: Show unlimited trip history

**FR-10.6** - Trip detail view shows:
- Full route on Apple Maps
- Speed graph over time
- Altitude graph
- Distance breakdown
- Time spent in speed ranges

**FR-10.7** - Allow trip deletion (swipe to delete)
**FR-10.8** - Allow trip search/filter by date

### FR-11: Pedometer (Premium)

**FR-11.1** - Track walking/running sessions separately from driving
**FR-11.2** - Display pedometer metrics:
- Steps
- Distance
- Time duration
- Calories burned (estimated)
- Current speed
- Step goal (configurable)

**FR-11.3** - Allow manual start/stop of pedometer session
**FR-11.4** - Store pedometer sessions in history
**FR-11.5** - Show pedometer data on separate tab/screen
**FR-11.6** - Sync pedometer sessions to iCloud

### FR-12: Settings

**FR-12.1** - Language selection
**FR-12.2** - Speed unit preference
**FR-12.3** - Color theme preference (Premium)
**FR-12.4** - Speed limit alerts (max/min values)
**FR-12.5** - Alert sound on/off
**FR-12.6** - Alert vibration on/off
**FR-12.7** - Mirror mode toggle (Premium)
**FR-12.8** - Notifications toggle
**FR-12.9** - Terms of Service link
**FR-12.10** - Privacy Policy link
**FR-12.11** - Conditions of Use link
**FR-12.12** - Rate Us button (deep link to App Store)
**FR-12.13** - Contact Us button (opens web URL)
**FR-12.14** - Restore Purchase button
**FR-12.15** - Log Out button
**FR-12.16** - Edit Profile button (change name/email from Apple ID)
**FR-12.17** - App version display

### FR-13: Subscriptions (RevenueCat)

**FR-13.1** - Offer subscription tiers:
- Weekly: $2.99/week
- Monthly: $7.99/month (best value per week)
- Yearly: $49.99/year with 3-day free trial (best value overall)
- Lifetime: $99.99 one-time purchase

**FR-13.2** - Show paywall after onboarding (dismissible)
**FR-13.3** - Show paywall when accessing premium features
**FR-13.4** - Show "Upgrade" button in settings
**FR-13.5** - Implement restore purchases
**FR-13.6** - Handle subscription expiration gracefully
**FR-13.7** - Sync subscription status across devices via RevenueCat
**FR-13.8** - Display subscription status in settings

### FR-14: iCloud Sync

**FR-14.1** - Sync user preferences to iCloud
**FR-14.2** - Sync trip history to iCloud (Premium only)
**FR-14.3** - Sync pedometer sessions to iCloud (Premium only)
**FR-14.4** - Handle sync conflicts (last-write-wins strategy)
**FR-14.5** - Indicate sync status in UI
**FR-14.6** - Allow manual sync trigger
**FR-14.7** - Work offline and sync when connection restored

## Non-Functional Requirements

### NFR-1: Performance

- App launch time < 2 seconds
- Speed updates at 1 Hz minimum
- Smooth 60 fps animations
- Map rendering < 1 second

### NFR-2: Battery Efficiency

- Use significant location changes when app is backgrounded
- Disable GPS when app is idle
- Use optimized location accuracy based on speed
- Minimize network requests

### NFR-3: Offline Capability

- Core speed tracking works without internet
- History browsing works offline
- Maps require internet for tile loading
- Weather requires internet

### NFR-4: Accessibility

- VoiceOver support for all screens
- Dynamic Type support
- High contrast mode compatibility
- Minimum touch target size: 44x44 pt

### NFR-5: Localization

- Support 6+ languages initially
- RTL layout support for Arabic/Hebrew
- Localized number and date formats
- Localized units based on region

### NFR-6: Privacy

- No user data sent to custom servers
- No analytics tracking without consent
- Clear privacy policy
- Minimal data collection

## Out of Scope (v1.0)

- Android version
- Web dashboard
- Custom backend/API
- Social features (sharing, leaderboards)
- Multi-user support
- CarPlay integration (future consideration)
- Apple Watch companion app (future consideration)
- Automatic speed limit detection via maps
- Speed camera alerts
- Driving score/rating system
- Export to third-party apps
