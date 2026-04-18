# SpeedTracker Architecture

## 📁 Folder Structure

```
SpeedTracker/
├── App/
│   └── SpeedTrackerApp.swift          # App entry point
│
├── Views/
│   ├── Onboarding/                     # Onboarding screens
│   │   ├── OnboardingContainerView.swift
│   │   ├── OnboardingPageView.swift
│   │   └── WelcomeView.swift
│   ├── Main/                           # Main speed tracking
│   │   ├── SpeedTrackerView.swift
│   │   ├── SpeedGaugeView.swift
│   │   └── StatsCardView.swift
│   ├── History/                        # Trip history
│   │   ├── HistoryListView.swift
│   │   └── TripDetailView.swift
│   ├── Settings/                       # Settings screens
│   │   ├── SettingsView.swift
│   │   └── PreferencesView.swift
│   └── Components/                     # Reusable UI components
│       ├── GlassMorphismCard.swift
│       ├── AnimatedButton.swift
│       ├── LottieView.swift
│       └── GradientBackground.swift
│
├── ViewModels/
│   ├── SpeedTrackerViewModel.swift
│   ├── OnboardingViewModel.swift
│   ├── HistoryViewModel.swift
│   └── SettingsViewModel.swift
│
├── Models/
│   ├── SpeedData.swift
│   ├── Trip.swift
│   ├── UserPreferences.swift
│   └── OnboardingPage.swift
│
├── Services/
│   ├── Location/
│   │   └── LocationManager.swift      # GPS & speed tracking
│   ├── Storage/
│   │   ├── DataManager.swift          # Local storage
│   │   └── CloudSyncManager.swift     # iCloud sync
│   └── Analytics/
│       └── AnalyticsService.swift     # Analytics tracking
│
├── Utilities/
│   ├── Constants.swift                 # App constants
│   ├── Extensions.swift                # Swift extensions
│   ├── Haptics.swift                   # Haptic feedback
│   └── SpeedFormatter.swift           # Speed formatting utilities
│
├── Resources/
│   ├── Fonts/                          # Custom fonts
│   │   ├── Orbitron-Bold.ttf
│   │   ├── Rajdhani-Medium.ttf
│   │   └── Rajdhani-Regular.ttf
│   ├── Lottie/                         # Lottie animations
│   │   ├── speedometer.json
│   │   ├── onboarding_1.json
│   │   ├── onboarding_2.json
│   │   └── onboarding_3.json
│   ├── Images/                         # Image assets
│   └── SVG/                           # SVG files
│
├── Localization/
│   ├── en.lproj/                      # English
│   ├── ko.lproj/                      # Korean
│   ├── ja.lproj/                      # Japanese
│   ├── el.lproj/                      # Greek
│   ├── fr.lproj/                      # French
│   ├── de.lproj/                      # German
│   ├── es.lproj/                      # Spanish
│   ├── pt.lproj/                      # Portuguese
│   ├── zh-Hans.lproj/                 # Chinese (Simplified)
│   ├── vi.lproj/                      # Vietnamese
│   ├── pt-BR.lproj/                   # Portuguese (Brazil)
│   ├── tr.lproj/                      # Turkish
│   ├── it.lproj/                      # Italian
│   └── ar.lproj/                      # Arabic
│
└── Extensions/
    ├── Color+Extensions.swift
    ├── View+Extensions.swift
    └── Font+Extensions.swift
```

## 🎨 Design System

### Typography
- **Headings/Speed/Branding**: Orbitron Bold
- **UI/Buttons/Labels**: Rajdhani Medium/Regular

### Color Palette (Sport Theme)
- **Primary**: Electric Blue (#00D9FF)
- **Secondary**: Neon Orange (#FF6B35)
- **Accent**: Lime Green (#39FF14)
- **Background**: Deep Navy (#0A1128)
- **Surface**: Dark Blue (#1E2749)
- **Text**: White (#FFFFFF)
- **Text Secondary**: Light Gray (#B8C1EC)

### UI Features
- Liquid glass morphism effects
- Smooth animations (60 FPS)
- Lottie animations for engaging interactions
- SVG icons for crisp graphics
- Gradient backgrounds
- Blur effects

## 🌍 Localization
Supports 14 languages with RTL support for Arabic

## 🚀 Performance Goals
- Smooth 60 FPS animations
- Efficient memory management
- Battery-optimized GPS tracking
- Haptic feedback for interactions
