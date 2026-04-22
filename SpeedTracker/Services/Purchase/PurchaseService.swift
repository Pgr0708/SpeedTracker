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
import RevenueCat

@MainActor
class PurchaseService: NSObject, ObservableObject {
    static let shared = PurchaseService()

    @AppStorage(AppConstants.UserDefaultsKeys.isPremium) var isPremium = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showRestoreSuccess = false
    @Published var restoreMessage = ""
    @Published var hasLoadedProducts = false

    private var packagesByProductID: [String: Package] = [:]
    private var currentRevenueCatUserID: String?

    // Fallback plan display info until RevenueCat offerings are loaded.
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

    @Published var plans: [PlanInfo] = [
        PlanInfo(id: AppConstants.Purchase.weeklyProductID,  title: "Weekly",   price: "$1.99",  period: "/week",  badge: "Flexible",    isBestValue: false, isMostPopular: false, hasTrial: false),
        PlanInfo(id: AppConstants.Purchase.monthlyProductID, title: "Monthly",  price: "$4.99",  period: "/month", badge: "Most Popular", isBestValue: false, isMostPopular: true,  hasTrial: false),
        PlanInfo(id: AppConstants.Purchase.yearlyProductID,  title: "Yearly",   price: "$19.99", period: "/year",  badge: "Best Value",  isBestValue: true,  isMostPopular: false, hasTrial: false),
        PlanInfo(id: AppConstants.Purchase.lifetimeProductID,title: "Lifetime", price: "$99.99", period: "",       badge: "Pay Once",    isBestValue: false, isMostPopular: false, hasTrial: false)
    ]

    private override init() {
        super.init()
    }

    static func configure() {
        guard AppConstants.Purchase.revenueCatAPIKey != "appl_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" else {
            print("RevenueCat skipped: replace AppConstants.Purchase.revenueCatAPIKey with your public iOS SDK key.")
            return
        }

        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: AppConstants.Purchase.revenueCatAPIKey)
        Purchases.shared.delegate = PurchaseService.shared
    }

    func purchase(planID: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            if packagesByProductID[planID] == nil {
                try await refreshProducts()
            }

            guard let package = packagesByProductID[planID] else {
                throw PurchaseError.packageNotFound
            }

            let result = try await Purchases.shared.purchase(package: package)
            handle(customerInfo: result.customerInfo)
            HapticManager.shared.notification(type: .success)
        } catch {
            #if DEBUG
            // In debug/simulator: if offerings aren't set up yet, unlock directly
            let msg = error.localizedDescription.lowercased()
            if msg.contains("configuration") || msg.contains("offering") || msg.contains("fetched") {
                isPremium = true
                HapticManager.shared.notification(type: .success)
                return
            }
            #endif
            presentError(error)
        }
    }

    func restore() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let info = try await Purchases.shared.restorePurchases()
            handle(customerInfo: info)

            if isPremium {
                CloudKitService.shared.syncAll(tripStore: TripStore.shared, pedometerService: PedometerService.shared)
                restoreMessage = L10n.string("paywall.restoreSuccess")
                HapticManager.shared.notification(type: .success)
            } else {
                restoreMessage = L10n.string("paywall.restoreNeedLogin")
            }

            showRestoreSuccess = true
        } catch {
            presentError(error)
        }
    }

    func checkPremiumStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            handle(customerInfo: info)
        } catch {
            presentError(error)
        }
    }

    func refreshProducts() async throws {
        let offerings = try await Purchases.shared.offerings()
        guard let packages = offerings.current?.availablePackages, !packages.isEmpty else {
            throw PurchaseError.noOfferingsAvailable
        }

        packagesByProductID = Dictionary(
            uniqueKeysWithValues: packages.map { ($0.storeProduct.productIdentifier, $0) }
        )

        let preferredOrder = [
            AppConstants.Purchase.yearlyProductID,
            AppConstants.Purchase.lifetimeProductID,
            AppConstants.Purchase.monthlyProductID,
            AppConstants.Purchase.weeklyProductID
        ]

        let sortedPackages = packages.sorted { lhs, rhs in
            preferredOrder.firstIndex(of: lhs.storeProduct.productIdentifier) ?? .max
            <
            preferredOrder.firstIndex(of: rhs.storeProduct.productIdentifier) ?? .max
        }

        plans = sortedPackages.map(planInfo(for:))
        hasLoadedProducts = true
    }

    func syncRevenueCatUser(isAuthenticated: Bool, userID: String) async {
        guard Purchases.isConfigured else { return }

        if isAuthenticated, !userID.isEmpty {
            guard currentRevenueCatUserID != userID else { return }
            do {
                let result = try await Purchases.shared.logIn(userID)
                currentRevenueCatUserID = userID
                handle(customerInfo: result.customerInfo)
            } catch {
                presentError(error)
            }
        } else if currentRevenueCatUserID != nil {
            do {
                let info = try await Purchases.shared.logOut()
                currentRevenueCatUserID = nil
                handle(customerInfo: info)
            } catch {
                presentError(error)
            }
        }
    }

    func resetToFreeMode() {
        isPremium = false
        currentRevenueCatUserID = nil
        UserDefaults.standard.set(false, forKey: AppConstants.UserDefaultsKeys.isMirrorModeEnabled)
        UserDefaults.standard.set(AppConstants.SpeedUnit.kmh.rawValue, forKey: AppConstants.UserDefaultsKeys.preferredSpeedUnit)
        UserDefaults.standard.set(AppConstants.ThemeColor.blue.rawValue, forKey: AppConstants.UserDefaultsKeys.themeColor)
        UserDefaults.standard.set(120.0, forKey: AppConstants.UserDefaultsKeys.maxSpeedLimit)
        UserDefaults.standard.set(0.0, forKey: AppConstants.UserDefaultsKeys.minSpeedLimit)
        UserDefaults.standard.set(true, forKey: AppConstants.UserDefaultsKeys.isDarkModeEnabled)
        UserDefaults.standard.set(0.0, forKey: AppConstants.UserDefaultsKeys.lastCloudKitSync)
    }

    private func handle(customerInfo: CustomerInfo) {
        let entitlements = customerInfo.entitlements.all
        isPremium =
            entitlements[AppConstants.Purchase.primaryEntitlementID]?.isActive == true ||
            entitlements[AppConstants.Purchase.lifetimeEntitlementID]?.isActive == true
    }

    private func presentError(_ error: Error) {
        errorMessage = (error as? PurchaseError)?.localizedDescription ?? error.localizedDescription
        showError = true
        HapticManager.shared.notification(type: .error)
    }

    private func planInfo(for package: Package) -> PlanInfo {
        let productID = package.storeProduct.productIdentifier

        return PlanInfo(
            id: productID,
            title: title(for: productID),
            price: package.storeProduct.localizedPriceString,
            period: period(for: productID),
            badge: badge(for: productID),
            isBestValue: productID == AppConstants.Purchase.yearlyProductID,
            isMostPopular: productID == AppConstants.Purchase.monthlyProductID,
            hasTrial: package.storeProduct.introductoryDiscount != nil
        )
    }

    private func title(for productID: String) -> String {
        switch productID {
        case AppConstants.Purchase.weeklyProductID: return "Weekly"
        case AppConstants.Purchase.monthlyProductID: return "Monthly"
        case AppConstants.Purchase.yearlyProductID: return "Yearly"
        case AppConstants.Purchase.lifetimeProductID: return "Lifetime"
        default: return "Premium"
        }
    }

    private func period(for productID: String) -> String {
        switch productID {
        case AppConstants.Purchase.weeklyProductID: return "/week"
        case AppConstants.Purchase.monthlyProductID: return "/month"
        case AppConstants.Purchase.yearlyProductID: return "/year"
        default: return ""
        }
    }

    private func badge(for productID: String) -> String {
        switch productID {
        case AppConstants.Purchase.weeklyProductID: return "Flexible"
        case AppConstants.Purchase.monthlyProductID: return "Most Popular"
        case AppConstants.Purchase.yearlyProductID: return "Best Value"
        case AppConstants.Purchase.lifetimeProductID: return "Pay Once"
        default: return ""
        }
    }
}

extension PurchaseService: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            PurchaseService.shared.handle(customerInfo: customerInfo)
        }
    }
}

private enum PurchaseError: LocalizedError {
    case noOfferingsAvailable
    case packageNotFound

    var errorDescription: String? {
        switch self {
        case .noOfferingsAvailable:
            return "RevenueCat has no current offering. Check your dashboard offering and App Store product mapping."
        case .packageNotFound:
            return "Selected product is not available in the current RevenueCat offering."
        }
    }
}
