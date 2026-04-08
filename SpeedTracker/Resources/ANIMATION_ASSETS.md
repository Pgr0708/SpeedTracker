# Animation Assets Guide

## Lottie Animations

SpeedTracker uses Lottie animations for smooth, scalable animations.

### Required Lottie Files

Place these JSON files in `Resources/Lottie/`:

1. **speedometer.json** - Main speedometer animation
2. **onboarding_1.json** - First onboarding screen animation
3. **onboarding_2.json** - Second onboarding screen animation
4. **onboarding_3.json** - Third onboarding screen animation
5. **success.json** - Success/achievement animation
6. **loading.json** - Loading spinner

### Where to Find Lottie Animations

- **LottieFiles**: [lottiefiles.com](https://lottiefiles.com)
- Search for: "speedometer", "speed", "car dashboard", "trophy", "success"
- Download as JSON

### Recommended Animations

1. **Speedometer**: 
   - Search: "speedometer", "gauge", "speed dial"
   - Style: Modern, minimalist, sport theme
   
2. **Onboarding 1** (Speed Tracking):
   - Search: "GPS", "location tracking", "speedometer"
   
3. **Onboarding 2** (Journey Recording):
   - Search: "map", "route", "journey", "path"
   
4. **Onboarding 3** (Compete):
   - Search: "trophy", "winner", "achievement", "medal"

### Integration

The app uses a `LottieView` wrapper (to be implemented) that works with SwiftUI:

```swift
LottieView(animationName: "speedometer", loopMode: .loop)
    .frame(width: 200, height: 200)
```

### Package Dependency

Add Lottie to your project via SPM:
```
https://github.com/airbnb/lottie-ios.git
```

## SVG Icons

Place SVG files in `Resources/SVG/`:
- Custom sport-themed icons
- UI elements that need to be scalable
- Special effect graphics

## Image Assets

Place in `Assets.xcassets/`:
- App icon (multiple sizes)
- Launch screen graphics
- Any raster images needed

## Current Status

🔴 **Action Required**: Download and add animation files
📁 Folders are set up and ready
📦 Lottie package needs to be added via SPM
