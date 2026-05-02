//
//  HUDModeView.swift
//  SpeedTracker
//
import SwiftUI
import Combine

// MARK: - Tilt Manager (persists across SwiftUI view updates)
class TiltManager: ObservableObject {
    @Published var deviceRotation: Double = 0
    var isTrackingActive = false
    private var orientationObserver: NSObjectProtocol?

    func start() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        orientationObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateRotation()
        }
    }

    func stop() {
        if let observer = orientationObserver {
            NotificationCenter.default.removeObserver(observer)
            orientationObserver = nil
        }
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    private func updateRotation() {
        guard isTrackingActive else {
            if deviceRotation != 0 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    deviceRotation = 0
                }
            }
            return
        }

        let orientation = UIDevice.current.orientation
        let newRotation: Double
        switch orientation {
        case .portrait:            newRotation = 0
        case .landscapeLeft:       newRotation = -90   // home button on right
        case .landscapeRight:      newRotation = 90    // home button on left
        case .portraitUpsideDown:   newRotation = 180
        default: return // ignore .faceUp, .faceDown, .unknown
        }

        if newRotation != deviceRotation {
            withAnimation(.easeInOut(duration: 0.3)) {
                deviceRotation = newRotation
            }
        }
    }
}

// MARK: - HUD Mode View
struct HUDModeView: View {
    @EnvironmentObject var theme: ThemeManager
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var tripStore = TripStore.shared
    @StateObject private var tiltManager = TiltManager()

    @AppStorage(AppConstants.UserDefaultsKeys.preferredSpeedUnit) private var speedUnitRaw = AppConstants.SpeedUnit.kmh.rawValue
    @AppStorage(AppConstants.UserDefaultsKeys.maxSpeedLimit) private var maxSpeedLimit: Double = 120
    @AppStorage(AppConstants.UserDefaultsKeys.isMirrorModeEnabled) private var isMirrorMode = false
    @Environment(\.dismiss) private var dismiss
    @State private var isHorizontalMode = false

    var speedUnit: AppConstants.SpeedUnit { AppConstants.SpeedUnit(rawValue: speedUnitRaw) ?? .kmh }
    var displaySpeed: Double { locationManager.convertedSpeed(locationManager.currentSpeed, unit: speedUnit) }

    var maxGaugeValue: Double {
        switch speedUnit {
        case .kmh:   return 250
        case .mph:   return 155
        case .ms:    return 69
        case .knots: return 135
        }
    }

    var speedColor: Color {
        if displaySpeed > maxSpeedLimit { return Color(hex:"FF3B5C") }
        if displaySpeed > maxSpeedLimit * 0.8 { return AppConstants.Colors.neonOrange }
        return theme.primaryColor
    }
    var isReversedHUDDisplay: Bool { !isMirrorMode }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GeometryReader { proxy in
                let size = proxy.size
                let autoHorizontalMode = size.width > size.height
                let shouldUseHorizontal = locationManager.isTracking ? autoHorizontalMode : isHorizontalMode
                Group {
                    if shouldUseHorizontal {
                        horizontalHUDScreen(size: size, safeBottom: max(proxy.safeAreaInsets.bottom + 10, 20))
                    } else {
                        verticalHUDScreen(size: size, safeTop: max(proxy.safeAreaInsets.top + 10, 22), safeBottom: max(proxy.safeAreaInsets.bottom + 10, 20))
                    }
                }
                .frame(width: size.width, height: size.height)
            }

        }
        .statusBar(hidden: true)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            tiltManager.isTrackingActive = locationManager.isTracking
            tiltManager.start()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            tiltManager.stop()
        }
        .onReceive(locationManager.$isTracking) { tracking in
            tiltManager.isTrackingActive = tracking
        }
    }


    // MARK: - Actions

    private func closeHUD() {
        if let trip = locationManager.stopTracking() {
            tripStore.saveTrip(trip)
            HapticManager.shared.notification(type: .success)
        }
        AudioService.shared.resetAlertCooldowns()
        dismiss()
    }

    private func timeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    // MARK: - Subviews

    private var hudHeader: some View {
        HStack(alignment: .top, spacing: 10) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(alignment: .leading, spacing: 2) {
                    Text(isMirrorMode ? "Mirror" : "HUD")
                        .font(.rajdhaniMedium(14))
                        .foregroundColor(.white.opacity(0.55))
                    Text(timeString(for: context.date))
                        .font(.orbitron(18))
                        .foregroundColor(.white)
                }
                .rotationEffect(.degrees(isHorizontalMode ? 90 : 0))
            }

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                hudCapsuleButton(
                    icon: "arrow.left.and.right.righttriangle.left.righttriangle.right",
                    title: isMirrorMode ? "Direct HUD" : "Mirror"
                ) {
                    isMirrorMode.toggle()
                }
                hudCapsuleButton(
                    icon: locationManager.isTracking ? "stop.fill" : "rectangle.portrait.and.arrow.right",
                    title: locationManager.isTracking ? L10n.string("main.stopMini") : L10n.string("common.close")
                ) {
                    closeHUD()
                }
            }
            .rotationEffect(.degrees(isHorizontalMode ? 90 : 0))
        }
    }

    private func verticalHUDScreen(size: CGSize, safeTop: CGFloat, safeBottom: CGFloat) -> some View {
        VStack(spacing: 0) {
            if locationManager.isTracking {
                ZStack(alignment: .topTrailing) {
                    activeHUDGauge(size: size, rotated: false)
                    closeOnlyButton
                        .padding(.top, safeTop)
                        .padding(.trailing, 20)
                }
            } else {
                VStack(spacing: 0) {
                    hudHeader
                        .padding(.horizontal, 20)
                        .padding(.top, safeTop)
                    Spacer(minLength: 16)
                    readyLayout(size: size)
                    Spacer(minLength: 14)
                    Text(isMirrorMode ? L10n.text("hud.mirrorInstruction") : L10n.text("hud.directView"))
                        .font(.bodySmall)
                        .foregroundColor(.white.opacity(0.35))
                        .padding(.horizontal, 20)
                        .padding(.bottom, safeBottom)
                }
            }
        }
    }

    private func horizontalHUDScreen(size: CGSize, safeBottom: CGFloat) -> some View {
        return ZStack(alignment: .topTrailing) {
            if locationManager.isTracking {
                activeHUDGauge(size: size, rotated: true)
            } else {
                VStack(spacing: 0) {
                    hudHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 22)
                    Spacer(minLength: 16)
                    readyLayout(size: size)
                    Spacer(minLength: 14)
                    Text(isMirrorMode ? L10n.text("hud.mirrorInstruction") : L10n.text("hud.directView"))
                        .font(.bodySmall)
                        .foregroundColor(.white.opacity(0.35))
                        .rotationEffect(.degrees(90))
                        .padding(.bottom, safeBottom)
                }
            }

            closeOnlyButton
                .rotationEffect(.degrees(90))
                .padding(.top, 22)
                .padding(.trailing, 20)
        }
    }

    private func activeHUDGauge(size: CGSize, rotated: Bool) -> some View {
        let gaugeSize = min(size.width * 0.94, size.height * (rotated ? 0.96 : 0.84))

        return ZStack {
            SportBikeSpeedometer(
                speed: displaySpeed,
                unit: L10n.string(speedUnit.localizationKey),
                accentColor: speedColor,
                theme: theme,
                maxValue: maxGaugeValue,
                diameter: gaugeSize,
                mirrored: isReversedHUDDisplay
            )
            .rotationEffect(.degrees(isMirrorMode ? tiltManager.deviceRotation : -tiltManager.deviceRotation))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var closeOnlyButton: some View {
        Button {
            closeHUD()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 42, height: 42)
                .background(Circle().fill(.white.opacity(0.12)))
        }
    }

    private func readyLayout(size: CGSize) -> some View {
        let gaugeSize = min(size.width * 0.78, size.height * 0.38)

        return VStack(spacing: 22) {
            SportBikeSpeedometer(
                speed: 0,
                unit: L10n.string(speedUnit.localizationKey),
                accentColor: theme.primaryColor,
                theme: theme,
                maxValue: maxGaugeValue,
                diameter: gaugeSize,
                mirrored: isReversedHUDDisplay
            )

            VStack(spacing: 8) {
                Text(L10n.text("hud.readyTitle"))
                    .font(.headingSmall)
                    .foregroundColor(.white)
                Text(L10n.text("hud.readySubtitle"))
                    .font(.bodySmall)
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            Button {
                locationManager.startTracking()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                    Text(L10n.text("main.startTrip"))
                }
                .font(.button)
                .foregroundColor(.black)
                .padding(.horizontal, 28)
                .padding(.vertical, 18)
                .background(Capsule().fill(theme.primaryColor))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func hudCapsuleButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                Text(title).font(.rajdhaniMedium(13))
            }
            .foregroundColor(.white.opacity(0.84))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(.white.opacity(0.1)))
        }
    }
}

#Preview { HUDModeView().environmentObject(ThemeManager.shared) }
