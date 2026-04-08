# Fonts Setup Guide

## Required Fonts

### 1. Orbitron Bold
- **Usage**: Headings, Speed Display, Branding
- **Download**: [Google Fonts - Orbitron](https://fonts.google.com/specimen/Orbitron)
- **File**: `Orbitron-Bold.ttf`

### 2. Rajdhani Medium
- **Usage**: UI Elements, Buttons, Labels
- **Download**: [Google Fonts - Rajdhani](https://fonts.google.com/specimen/Rajdhani)
- **File**: `Rajdhani-Medium.ttf`

### 3. Rajdhani Regular
- **Usage**: UI Elements, Body Text
- **Download**: [Google Fonts - Rajdhani](https://fonts.google.com/specimen/Rajdhani)
- **File**: `Rajdhani-Regular.ttf`

## Installation Steps

1. **Download Fonts**:
   - Go to Google Fonts
   - Download Orbitron (Bold weight)
   - Download Rajdhani (Medium and Regular weights)

2. **Add to Project**:
   - Place `.ttf` files in `Resources/Fonts/` directory
   - Add files to Xcode project (drag & drop)
   - Ensure "Target Membership" is checked for SpeedTracker

3. **Update Info.plist**:
   Add the following to your `Info.plist`:
   ```xml
   <key>UIAppFonts</key>
   <array>
       <string>Orbitron-Bold.ttf</string>
       <string>Rajdhani-Medium.ttf</string>
       <string>Rajdhani-Regular.ttf</string>
   </array>
   ```

4. **Verify Installation**:
   ```swift
   // Run this code to verify fonts are loaded
   for family in UIFont.familyNames.sorted() {
       let names = UIFont.fontNames(forFamilyName: family)
       print("Family: \(family) Font names: \(names)")
   }
   ```

## Usage Examples

```swift
// Headings
Text("125")
    .font(.displayLarge)  // Orbitron Bold 72pt

// Speed Display
Text("km/h")
    .font(.headingMedium)  // Orbitron Bold 28pt

// Buttons
Button("Start") {}
    .font(.button)  // Rajdhani Medium 16pt

// Labels
Text("Max Speed")
    .font(.label)  // Rajdhani Medium 14pt

// Body Text
Text("Description")
    .font(.bodyMedium)  // Rajdhani Medium 16pt
```

## Alternative (If fonts unavailable)

If you can't download the fonts, the app will fall back to system fonts:
- Orbitron → San Francisco Rounded Bold
- Rajdhani → San Francisco Medium/Regular
