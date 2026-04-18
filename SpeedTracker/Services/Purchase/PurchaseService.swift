//
//  PurchaseService.swift
//  SpeedTracker
//
//  RevenueCat wrapper. Add RevenueCat SPM package before building:
//  https://github.com/RevenueCat/purchases-ios  ~> 5.0
//
//  IMPORTANT: Replace AppConstants.Purchase.revenueCatAPIKey with your real key.
//
import Foundation
import SwiftUI
import Combine
// import RevenueCat  ← Uncomment after adding RevenueCat via SPM

@MainActor
class PurchaseService: ObservableObject {
    static let shared = PurchaseService()

    @AppStorage(AppConstants.UserDefaultsKeys.isPremium) var isPremium = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showRestoreSuccess = false
    @Published var restoreMessage = ""

    // Plan display info (populated from RevenueCat packages in production)
    struct PlanInfo: Identifiable {
        let id: String
        let title: String
        let price: String
        let period: String
        let badge: String
        let isBestValue: Bool
        let isMostPopular: Bool
        let hasTrial: Bool
    }

    let plans: [PlanInfo] = [
        PlanInfo(id: AppConstants.Purchase.weeklyProductID,  title: "Weekly",   price: "$2.99",  period: "/week",  badge: "Flexible",          isBestValue: false, isMostPopular: false, hasTrial: false),
        PlanInfo(id: AppConstants.Purchase.monthlyProductID, title: "Monthly",  price: "$7.99",  period: "/month", badge: "Most Popular",       isBestValue: false, isMostPopular: true,  hasTrial: false),
        PlanInfo(id: AppConstants.Purchase.yearlyProductID,  title: "Yearly",   price: "$49.99", period: "/year",  badge: "3-Day Free Trial",  isBestValue: true,  isMostPopular: false, hasTrial: true),
        PlanInfo(id: AppConstants.Purchase.lifetimeProductID,title: "Lifetime", price: "$99.99", period: "",       badge: "Pay Once",          isBestValue: false, isMostPopular: false, hasTrial: false)
    ]

    private init() {}

    static func configure() {
        // Purchases.configure(withAPIKey: AppConstants.Purchase.revenueCatAPIKey)
        // Purchases.shared.delegate = PurchaseService.shared  // set up delegate
        print("RevenueCat configure() called. Add SDK via SPM to activate.")
    }

    func purchase(planID: String) async {
        isLoading = true
        defer { isLoading = false }

        // In production with RevenueCat SDK:
        // let offerings = try await Purchases.shared.offerings()
        // guard let package = offerings.current?.availablePackages.first(where: { $0.storeProduct.productIdentifier == planID }) else { return }
        // let result = try await Purchases.shared.purchase(package: package)
        // isPremium = !result.customerInfo.entitlements[AppConstants.Purchase.entitlementID]?.isActive == false

        // Sandbox simulation:
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        isPremium = true
        HapticManager.shared.notification(type: .success)
    }

    func restore() async {
        isLoading = true
        defer { isLoading = false }

        // In production: let info = try await Purchases.shared.restorePurchases()
        // isPremium = info.entitlements[AppConstants.Purchase.entitlementID]?.isActive == true

        try? await Task.sleep(nanoseconds: 1_000_000_000)
        if AuthService.shared.isAuthenticated {
            isPremium = true
            CloudKitService.shared.syncAll(tripStore: TripStore.shared, pedometerService: PedometerService.shared)
            restoreMessage = L10n.string("paywall.restoreSuccess")
        } else {
            restoreMessage = L10n.string("paywall.restoreNeedLogin")
        }
        showRestoreSuccess = true
        HapticManager.shared.notification(type: .success)
    }

    func checkPremiumStatus() async {
        // let info = try? await Purchases.shared.customerInfo()
        // isPremium = info?.entitlements[AppConstants.Purchase.entitlementID]?.isActive == true
    }

    func resetToFreeMode() {
        isPremium = false
        UserDefaults.standard.set(false, forKey: AppConstants.UserDefaultsKeys.isMirrorModeEnabled)
        UserDefaults.standard.set(AppConstants.SpeedUnit.kmh.rawValue, forKey: AppConstants.UserDefaultsKeys.preferredSpeedUnit)
        UserDefaults.standard.set(AppConstants.ThemeColor.blue.rawValue, forKey: AppConstants.UserDefaultsKeys.themeColor)
        UserDefaults.standard.set(120.0, forKey: AppConstants.UserDefaultsKeys.maxSpeedLimit)
        UserDefaults.standard.set(0.0, forKey: AppConstants.UserDefaultsKeys.minSpeedLimit)
        UserDefaults.standard.set(true, forKey: AppConstants.UserDefaultsKeys.isDarkModeEnabled)
        UserDefaults.standard.set(0.0, forKey: AppConstants.UserDefaultsKeys.lastCloudKitSync)
    }
}
