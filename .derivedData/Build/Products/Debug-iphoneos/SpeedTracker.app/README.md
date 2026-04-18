# Speed Tracker

A modern, privacy-focused iOS speed tracking application designed for drivers who want to monitor their speed, track their trips, and review their driving history—all without the complexity of traditional backend infrastructure.

## Overview

Speed Tracker is a native iOS application that uses Apple's CoreLocation framework to provide real-time speed monitoring, trip history, and optional pedometer functionality. The app leverages Apple ID for authentication and iCloud for seamless data synchronization across devices.

## Key Highlights

- **Privacy-First**: Apple ID authentication only, no custom backend
- **Seamless Sync**: iCloud-powered data synchronization
- **No Server Costs**: All data stored locally and synced via iCloud
- **Subscription Model**: RevenueCat-powered weekly, monthly, yearly, and lifetime plans
- **Rich Features**: Live speed tracking, HUD mode, trip history with maps, pedometer
- **Professional UX**: Clean onboarding flow with proper permission handling

## Tech Stack

- **Platform**: iOS 15.0+
- **Language**: Swift/SwiftUI
- **Authentication**: Sign in with Apple (Apple ID only)
- **Data Sync**: CloudKit/iCloud
- **Location**: CoreLocation framework
- **Maps**: MapKit
- **Subscriptions**: RevenueCat SDK
- **Pedometer**: CoreMotion framework
- **Weather**: WeatherKit (iOS 16+) or OpenWeatherMap API (lightweight)

## Core Features

### Free Tier
- Basic speed tracking (current speed only)
- Speed unit selection (mph/km/h)
- Simple drive history (last 5 trips)
- Speed limit alerts with sound/vibration
- Apple ID sign-in
- Basic settings

### Premium Tier
- Full dashboard (altitude, distance, avg speed, max speed, coordinates)
- HUD mode for windshield display
- Unlimited trip history with maps
- Route visualization on Apple Maps
- Speed graphs and analytics
- Pedometer integration
- Mirror mode
- Compass display
- Weather integration
- Advanced customization (color themes)
- iCloud sync for history
- Export trip data

## App Flow

1. **Splash Screen** → Brand introduction
2. **Language Selection** → Choose preferred language
3. **Onboarding** → Feature walkthrough (3-4 screens)
4. **Paywall** → Subscription options (dismissible)
5. **Apple ID Sign-In** → Authentication
6. **Permission Requests** → Location, Motion, Notifications
7. **Home Screen** → Main speed tracking interface

## Target Audience

- Daily commuters who want to monitor their driving speed
- Drivers in speed-sensitive zones
- Fitness enthusiasts who walk/run and want speed tracking
- Users who prefer privacy-focused apps without account creation hassles

## Competitive Advantages

- No email/password registration friction
- No backend server = faster, more reliable
- Apple ecosystem integration (Apple ID, iCloud, Apple Maps)
- One-time lifetime purchase option
- Works offline (except weather)

## Project Structure

```
SpeedTracker/
├── README.md (this file)
├── PRODUCT_REQUIREMENTS.md
├── USER_FLOWS.md
├── SCREEN_LIST.md
├── FEATURE_MATRIX.md
├── REVENUECAT_PLAN.md
├── IAP_TIERS.md
├── ICLOUD_SYNC_PLAN.md
├── PERMISSIONS_PLAN.md
├── DATA_MODEL.md
├── SETTINGS_SPEC.md
├── HISTORY_SPEC.md
├── PRACTICAL_LIMITS.md
├── TESTING_PLAN.md
└── ROADMAP.md
```

## Implementation Priority

1. **Live Speed Tracking** - Core functionality
2. **HUD Mode** - Unique selling point
3. **Pedometer** - Additional tracking capability
4. **History** - User retention feature
5. **Settings** - Configuration and support

## Getting Started

Review the documentation files in this order:

1. `PRODUCT_REQUIREMENTS.md` - Detailed feature specifications
2. `USER_FLOWS.md` - User journey maps
3. `SCREEN_LIST.md` - All screens and their purpose
4. `FEATURE_MATRIX.md` - Free vs Premium breakdown
5. `ROADMAP.md` - Development phases

## License

Proprietary - All rights reserved

## Version

1.0.0 - Initial documentation
