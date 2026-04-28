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

    // UNLOCK: set to true to give all users premium. Remove this line to restore gating.
    var isPremium: Bool { true }
    @AppStorage(AppConstants.UserDefaultsKeys.isPremium) private var _isPremiumStored = false
    @AppStorage(AppConstants.UserDefaultsKeys.currentPlanName) private var storedPlanName = "Free Plan"
    @AppStorage(AppConstants.UserDefaultsKeys.currentProductID) private var storedProductID = ""
    @AppStorage(AppConstants.UserDefaultsKeys.currentExpirationDate) private var storedExpirationDate: Double = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showRestoreSuccess = false
    @Published var restoreMessage = ""
    @Published var hasLoadedProducts = false
    @Published private(set) var currentPlanName = "Free Plan"
    @Published private(set) var currentProductID = ""
    @Published private(set) var currentExpirationDate: Date?

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
        restoreStoredSubscriptionMetadata()
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
        showError = false
        showRestoreSuccess = false
        errorMessage = nil
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
            reconcilePostEntitlementChange(forceAppleSignIn: true)
            HapticManager.shared.notification(type: .success)
        } catch {
            presentError(error)
        }
    }

    func restore() async {
        showError = false
        showRestoreSuccess = false
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let info = try await restoreCustomerInfo()
            handle(customerInfo: info)
            reconcilePostEntitlementChange(forceAppleSignIn: true)

            if isPremium {
                restoreMessage = AuthService.shared.isAuthenticated
                    ? L10n.string("paywall.restoreSuccess")
                    : "Premium restored. Sign in with Apple to turn on iCloud sync."
                HapticManager.shared.notification(type: .success)
            } else {
                restoreMessage = "No active purchase found to restore."
            }

            showRestoreSuccess = true
        } catch {
            presentError(error)
        }
    }

    func checkPremiumStatus() async {
        do {
            var info = try await Purchases.shared.customerInfo()
            if shouldAttemptReceiptSync(for: info) {
                info = try await syncReceiptBackedCustomerInfo()
            }
            handle(customerInfo: info)
            reconcilePostEntitlementChange(forceAppleSignIn: false)
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
                var result = try await Purchases.shared.logIn(userID)
                if shouldAttemptReceiptSync(for: result.customerInfo) {
                    let syncedInfo = try await syncReceiptBackedCustomerInfo()
                    result = (customerInfo: syncedInfo, created: result.created)
                }
                currentRevenueCatUserID = userID
                handle(customerInfo: result.customerInfo)
                reconcilePostEntitlementChange(forceAppleSignIn: false)
            } catch {
                presentError(error)
            }
        } else if currentRevenueCatUserID != nil {
            // Log out from RevenueCat on sign-out so the anonymous user's info
            // doesn't carry the premium entitlement into checkPremiumStatus().
            do {
                let anonInfo = try await Purchases.shared.logOut()
                currentRevenueCatUserID = nil
                handle(customerInfo: anonInfo)
            } catch {
                currentRevenueCatUserID = nil
            }
        }
    }

    func resetToFreeMode() {
        _isPremiumStored = false
        // Do NOT clear currentRevenueCatUserID here — syncRevenueCatUser needs it
        // to know it should call Purchases.shared.logOut() when isAuthenticated flips to false.
        currentPlanName = "Free Plan"
        currentProductID = ""
        currentExpirationDate = nil
        persistSubscriptionMetadata()
        UserDefaults.standard.set(false, forKey: AppConstants.UserDefaultsKeys.isMirrorModeEnabled)
        UserDefaults.standard.set(AppConstants.SpeedUnit.kmh.rawValue, forKey: AppConstants.UserDefaultsKeys.preferredSpeedUnit)
        UserDefaults.standard.set(AppConstants.ThemeColor.blue.rawValue, forKey: AppConstants.UserDefaultsKeys.themeColor)
        UserDefaults.standard.set(120.0, forKey: AppConstants.UserDefaultsKeys.maxSpeedLimit)
        UserDefaults.standard.set(0.0, forKey: AppConstants.UserDefaultsKeys.minSpeedLimit)
        UserDefaults.standard.set(true, forKey: AppConstants.UserDefaultsKeys.isDarkModeEnabled)
        UserDefaults.standard.set(0.0, forKey: AppConstants.UserDefaultsKeys.lastCloudKitSync)
    }

    private func handle(customerInfo: CustomerInfo) {
        // Block RC delegate from re-enabling premium after sign-out
        guard AuthService.shared.isAuthenticated else {
            _isPremiumStored = false
            currentPlanName = "Free Plan"
            currentProductID = ""
            currentExpirationDate = nil
            persistSubscriptionMetadata()
            return
        }

        let activeEntitlements = customerInfo.entitlements.active

        if let activeEntitlement = activeEntitlements[AppConstants.Purchase.primaryEntitlementID]
            ?? activeEntitlements[AppConstants.Purchase.lifetimeEntitlementID]
            ?? activeEntitlements.values.first {
            _isPremiumStored = true
            currentProductID = activeEntitlement.productIdentifier
            currentExpirationDate = activeEntitlement.expirationDate
            currentPlanName = title(for: activeEntitlement.productIdentifier)
            persistSubscriptionMetadata()
            return
        }

        if let activeSubscriptionID = currentActiveSubscriptionProductID(in: customerInfo) {
            _isPremiumStored = true
            currentProductID = activeSubscriptionID
            currentExpirationDate = customerInfo.expirationDate(forProductIdentifier: activeSubscriptionID)
            currentPlanName = title(for: activeSubscriptionID)
            persistSubscriptionMetadata()
            return
        }

        if customerInfo.nonSubscriptions.contains(where: { $0.productIdentifier == AppConstants.Purchase.lifetimeProductID }) {
            _isPremiumStored = true
            currentProductID = AppConstants.Purchase.lifetimeProductID
            currentExpirationDate = nil
            currentPlanName = title(for: AppConstants.Purchase.lifetimeProductID)
            persistSubscriptionMetadata()
            return
        }

        _isPremiumStored = false
        currentProductID = ""
        currentExpirationDate = nil
        currentPlanName = "Free Plan"
        persistSubscriptionMetadata()
    }

    private func reconcilePostEntitlementChange(forceAppleSignIn: Bool) {
        guard isPremium else { return }

        if AuthService.shared.isAuthenticated {
            CloudKitService.shared.syncAll(tripStore: TripStore.shared, pedometerService: PedometerService.shared)
        } else {
            AuthService.shared.signInIfNeeded(forcePrompt: forceAppleSignIn)
        }
    }

    private func presentError(_ error: Error) {
        errorMessage = (error as? PurchaseError)?.localizedDescription ?? error.localizedDescription
        showError = true
        HapticManager.shared.notification(type: .error)
    }

    private func restoreCustomerInfo() async throws -> CustomerInfo {
        await ensureRevenueCatIdentityMatchesAppleSignIn(forceRefresh: false)

        let restoredInfo = try await Purchases.shared.restorePurchases()
        if containsActivePremium(in: restoredInfo) {
            return restoredInfo
        }

        let syncedInfo = try await syncReceiptBackedCustomerInfo()
        if containsActivePremium(in: syncedInfo) {
            return syncedInfo
        }

        await ensureRevenueCatIdentityMatchesAppleSignIn(forceRefresh: true)
        return try await Purchases.shared.customerInfo()
    }

    private func ensureRevenueCatIdentityMatchesAppleSignIn(forceRefresh: Bool) async {
        guard AuthService.shared.isAuthenticated, !AuthService.shared.userID.isEmpty else { return }
        guard forceRefresh || currentRevenueCatUserID != AuthService.shared.userID else { return }

        do {
            let result = try await Purchases.shared.logIn(AuthService.shared.userID)
            currentRevenueCatUserID = AuthService.shared.userID
            handle(customerInfo: result.customerInfo)
        } catch {
            // Keep restore flowing even if RevenueCat login could not be refreshed yet.
        }
    }

    private func containsActivePremium(in customerInfo: CustomerInfo) -> Bool {
        !customerInfo.entitlements.active.isEmpty ||
            currentActiveSubscriptionProductID(in: customerInfo) != nil ||
            customerInfo.nonSubscriptions.contains(where: { $0.productIdentifier == AppConstants.Purchase.lifetimeProductID })
    }

    private func syncReceiptBackedCustomerInfo() async throws -> CustomerInfo {
        let syncedInfo = try await Purchases.shared.syncPurchases()
        if containsActivePremium(in: syncedInfo) {
            return syncedInfo
        }

        return try await Purchases.shared.customerInfo()
    }

    private func shouldAttemptReceiptSync(for customerInfo: CustomerInfo) -> Bool {
        guard !containsActivePremium(in: customerInfo) else { return false }
        return AuthService.shared.isAuthenticated || isPremium || !currentProductID.isEmpty
    }

    private func currentActiveSubscriptionProductID(in customerInfo: CustomerInfo) -> String? {
        let activeSubscriptions = customerInfo.activeSubscriptions
        if activeSubscriptions.contains(AppConstants.Purchase.yearlyProductID) {
            return AppConstants.Purchase.yearlyProductID
        }
        if activeSubscriptions.contains(AppConstants.Purchase.monthlyProductID) {
            return AppConstants.Purchase.monthlyProductID
        }
        if activeSubscriptions.contains(AppConstants.Purchase.weeklyProductID) {
            return AppConstants.Purchase.weeklyProductID
        }
        return activeSubscriptions.first
    }

    private func restoreStoredSubscriptionMetadata() {
        currentPlanName = storedPlanName
        currentProductID = storedProductID
        currentExpirationDate = storedExpirationDate > 0 ? Date(timeIntervalSince1970: storedExpirationDate) : nil
    }

    private func persistSubscriptionMetadata() {
        storedPlanName = currentPlanName
        storedProductID = currentProductID
        storedExpirationDate = currentExpirationDate?.timeIntervalSince1970 ?? 0
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

    var remainingTimeSummary: String {
        // Treat as free if there's no real product on record, even when the unlock flag is on.
        guard !currentProductID.isEmpty else { return "Free plan active" }

        if currentProductID == AppConstants.Purchase.lifetimeProductID {
            return "Never expires"
        }

        guard let expirationDate = currentExpirationDate else {
            return "Plan active"
        }

        let secondsRemaining = expirationDate.timeIntervalSinceNow
        if secondsRemaining <= 0 {
            return "Expired"
        }

        let totalSeconds = Int(secondsRemaining)
        let days = totalSeconds / 86_400
        let hours = (totalSeconds % 86_400) / 3600
        let minutes = (totalSeconds % 3600) / 60

        if days >= 1 {
            return "\(days) \(days == 1 ? "day" : "days") left"
        } else if hours >= 1 {
            return "\(hours) \(hours == 1 ? "hour" : "hours") left"
        } else if minutes >= 1 {
            return "\(minutes) \(minutes == 1 ? "minute" : "minutes") left"
        } else {
            return "Expires soon"
        }
    }
}

// MARK: - Test Helpers
#if DEBUG
extension PurchaseService {
    func _testSetState(planName: String, productID: String, expirationDate: Date?, premium: Bool) {
        currentPlanName = planName
        currentProductID = productID
        currentExpirationDate = expirationDate
        _isPremiumStored = premium
        persistSubscriptionMetadata()
    }
}
#endif

extension PurchaseService: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            PurchaseService.shared.handle(customerInfo: customerInfo)
            PurchaseService.shared.reconcilePostEntitlementChange(forceAppleSignIn: false)
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
