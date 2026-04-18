# RevenueCat Integration Plan

Comprehensive guide for implementing RevenueCat subscription management in Speed Tracker.

## Why RevenueCat?

RevenueCat simplifies subscription management by providing:
- Cross-platform receipt validation
- Subscription status tracking
- Real-time webhooks for subscription events
- Analytics and metrics dashboard
- Easy integration with Apple StoreKit
- Server-side receipt validation (no backend needed)
- Subscription state sync across devices

## RevenueCat Setup

### 1. Account Configuration

1. Create RevenueCat account at https://app.revenuecat.com
2. Create new project: "Speed Tracker"
3. Platform: iOS
4. Get API keys:
   - **Public API Key** (for iOS SDK)
   - **Secret API Key** (for webhooks, if needed)

### 2. App Store Connect Configuration

1. Create app in App Store Connect
2. Configure in-app purchases (see IAP_TIERS.md)
3. Create subscription groups
4. Get Shared Secret from App Store Connect
5. Add Shared Secret to RevenueCat dashboard

### 3. Product IDs

Create these product identifiers in App Store Connect:

```
Weekly:   speedtracker_weekly
Monthly:  speedtracker_monthly
Yearly:   speedtracker_yearly
Lifetime: speedtracker_lifetime
```

### 4. RevenueCat Entitlements

Create one entitlement: **"premium"**

All subscription products grant the same entitlement level.

Map products to entitlement in RevenueCat:
- `speedtracker_weekly` → "premium"
- `speedtracker_monthly` → "premium"
- `speedtracker_yearly` → "premium"
- `speedtracker_lifetime` → "premium"

## iOS SDK Integration

### 1. Install RevenueCat SDK

Add to Xcode project via Swift Package Manager:

```
https://github.com/RevenueCat/purchases-ios.git
```

Or via CocoaPods:

```ruby
pod 'RevenueCat'
```

### 2. Initialize SDK

In `SpeedTrackerApp.swift`:

```swift
import RevenueCat

@main
struct SpeedTrackerApp: App {
    init() {
        // Configure RevenueCat
        Purchases.logLevel = .debug // .info for production
        Purchases.configure(withAPIKey: "YOUR_PUBLIC_API_KEY")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 3. Identify Users

After Apple Sign-In:

```swift
func signInWithApple(appleUserID: String) {
    // Set user ID in RevenueCat
    Purchases.shared.logIn(appleUserID) { customerInfo, created, error in
        if let error = error {
            print("RevenueCat login error: \(error)")
            return
        }
        
        // Check subscription status
        let isPremium = customerInfo?.entitlements["premium"]?.isActive == true
        UserDefaults.standard.set(isPremium, forKey: "isPremium")
    }
}
```

### 4. Fetch Offerings

Load subscription options from RevenueCat:

```swift
func loadSubscriptionOfferings() {
    Purchases.shared.getOfferings { offerings, error in
        if let error = error {
            print("Error fetching offerings: \(error)")
            return
        }
        
        guard let packages = offerings?.current?.availablePackages else {
            print("No offerings available")
            return
        }
        
        // Display packages in paywall UI
        for package in packages {
            print("Package: \(package.identifier)")
            print("Price: \(package.localizedPriceString)")
            print("Intro offer: \(package.storeProduct.introductoryDiscount?.localizedPriceString ?? "None")")
        }
    }
}
```

### 5. Purchase Flow

When user taps Subscribe:

```swift
func purchase(package: Package) {
    Purchases.shared.purchase(package: package) { transaction, customerInfo, error, userCancelled in
        if userCancelled {
            print("User cancelled purchase")
            return
        }
        
        if let error = error {
            print("Purchase error: \(error)")
            showPurchaseError(error)
            return
        }
        
        // Purchase successful
        let isPremium = customerInfo?.entitlements["premium"]?.isActive == true
        
        if isPremium {
            unlockPremiumFeatures()
            showPurchaseSuccess()
        }
    }
}
```

### 6. Check Subscription Status

On app launch and before accessing premium features:

```swift
func checkSubscriptionStatus() {
    Purchases.shared.getCustomerInfo { customerInfo, error in
        if let error = error {
            print("Error fetching customer info: \(error)")
            return
        }
        
        let isPremium = customerInfo?.entitlements["premium"]?.isActive == true
        UserDefaults.standard.set(isPremium, forKey: "isPremium")
        
        // Update UI
        updatePremiumUI(isPremium: isPremium)
        
        // Log subscription details
        if let entitlement = customerInfo?.entitlements["premium"] {
            print("Premium active: \(entitlement.isActive)")
            print("Expires: \(entitlement.expirationDate ?? Date())")
            print("Product: \(entitlement.productIdentifier)")
            print("Will renew: \(entitlement.willRenew)")
        }
    }
}
```

### 7. Restore Purchases

When user taps "Restore Purchase":

```swift
func restorePurchases() {
    showLoadingIndicator()
    
    Purchases.shared.restorePurchases { customerInfo, error in
        hideLoadingIndicator()
        
        if let error = error {
            print("Restore error: \(error)")
            showRestoreError()
            return
        }
        
        let isPremium = customerInfo?.entitlements["premium"]?.isActive == true
        
        if isPremium {
            showRestoreSuccess()
            unlockPremiumFeatures()
        } else {
            showNoSubscriptionFound()
        }
    }
}
```

## Paywall Implementation

### Paywall View Structure

```swift
struct PaywallView: View {
    @State private var offerings: Offerings?
    @State private var isPurchasing = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            // Close button
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                }
            }
            
            // Feature list
            FeatureListView()
            
            // Subscription options
            if let packages = offerings?.current?.availablePackages {
                SubscriptionOptionsView(packages: packages)
            }
            
            // Purchase button
            PurchaseButton(isPurchasing: $isPurchasing)
            
            // Continue with Free
            Button("Continue with Free") {
                dismiss()
            }
            
            // Legal
            LegalLinksView()
        }
        .onAppear {
            loadOfferings()
        }
    }
}
```

### Package Display Order

Display packages in this order (most attractive first):

1. **Yearly** (with "Best Value" badge)
2. **Lifetime** (with "One-Time Purchase" badge)
3. **Monthly** (with "Most Popular" badge)
4. **Weekly** (no badge)

### Free Trial Handling

No free trial is configured:

```swift
func hasFreeTrial(package: Package) -> Bool {
    return package.storeProduct.introductoryDiscount != nil
}

func freeTrialDuration(package: Package) -> String? {
    guard let intro = package.storeProduct.introductoryDiscount else {
        return nil
    }
    
    let unit = intro.subscriptionPeriod.unit
    let value = intro.subscriptionPeriod.value
    
    // e.g., "3 Days", "1 Week", etc.
    return "\(value) \(unit.description)"
}
```

## Subscription Status Management

### Local Cache

Use UserDefaults for quick access:

```swift
class SubscriptionManager: ObservableObject {
    @Published var isPremium: Bool = false
    
    init() {
        self.isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        checkSubscriptionStatus()
    }
    
    func checkSubscriptionStatus() {
        Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
            guard let self = self else { return }
            
            let premium = customerInfo?.entitlements["premium"]?.isActive == true
            
            DispatchQueue.main.async {
                self.isPremium = premium
                UserDefaults.standard.set(premium, forKey: "isPremium")
            }
        }
    }
}
```

### Subscription State Syncing

RevenueCat automatically syncs subscription state across devices when users are logged in with the same Apple ID.

No additional code needed if user is logged in via RevenueCat.

## Handling Edge Cases

### 1. Subscription Expiration

Listen for customer info updates:

```swift
// Add delegate in app initialization
Purchases.shared.delegate = self

extension YourClass: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        let isPremium = customerInfo.entitlements["premium"]?.isActive == true
        
        if !isPremium && UserDefaults.standard.bool(forKey: "isPremium") {
            // Subscription expired
            handleSubscriptionExpired()
        }
        
        UserDefaults.standard.set(isPremium, forKey: "isPremium")
    }
}

func handleSubscriptionExpired() {
    // Show gentle upgrade message
    // Downgrade to free tier
    // Lock premium features
    showSubscriptionExpiredAlert()
}
```

### 2. Grace Period

If user's payment method fails, Apple may give a grace period:

```swift
func checkGracePeriod(customerInfo: CustomerInfo) -> Bool {
    if let entitlement = customerInfo.entitlements["premium"] {
        return entitlement.isActive && entitlement.billingIssueDetectedAt != nil
    }
    return false
}
```

Show billing issue warning to user.

### 3. Refund Handling

RevenueCat detects refunds automatically:

```swift
func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
    let isPremium = customerInfo.entitlements["premium"]?.isActive == true
    
    if !isPremium {
        // Could be expiration OR refund
        // Check entitlement history to differentiate
        handlePremiumLoss()
    }
}
```

### 4. Subscription Upgrades/Downgrades

RevenueCat handles proration automatically through Apple.

User can change plans in App Store subscriptions.

### 5. Network Failures

Cache subscription status locally:

```swift
func checkSubscriptionStatus() {
    // Always check cache first
    let cachedPremium = UserDefaults.standard.bool(forKey: "isPremium")
    self.isPremium = cachedPremium
    
    // Then update from server
    Purchases.shared.getCustomerInfo { customerInfo, error in
        if let error = error {
            print("Using cached subscription status due to error: \(error)")
            return
        }
        
        let isPremium = customerInfo?.entitlements["premium"]?.isActive == true
        UserDefaults.standard.set(isPremium, forKey: "isPremium")
        self.isPremium = isPremium
    }
}
```

## Testing

### Sandbox Testing

1. Create sandbox test account in App Store Connect
2. Sign out of production App Store on device
3. Sign in with sandbox account when prompted during purchase
4. Test all subscription flows:
   - Purchase weekly
   - Purchase monthly
   - Purchase yearly (verify 3-day trial)
   - Purchase lifetime
   - Restore purchases
   - Subscription expiration (accelerated in sandbox)
   - Refunds

### Sandbox Time Acceleration

In sandbox environment:
- 1 week subscription = 3 minutes
- 1 month subscription = 5 minutes
- 1 year subscription = 1 hour

Perfect for testing renewals and expirations.

### RevenueCat Test Mode

Enable test mode in RevenueCat dashboard to:
- Simulate purchases without App Store
- Test subscription events
- Verify webhook delivery

## Analytics

RevenueCat provides built-in analytics:

### Key Metrics to Monitor

1. **Conversion Rate**: Free to paid %
2. **Churn Rate**: Subscription cancellations %
3. **Revenue by Product**: Which plan sells best?
4. **Trial Conversions**: Free trial to paid %
5. **Lifetime Value (LTV)**: Revenue per user
6. **Active Subscribers**: Current premium users

### Custom Events

Track custom events for better insights:

```swift
Purchases.shared.setAttributes([
    "onboarding_completed": "true",
    "feature_used_hud": "5",
    "feature_used_pedometer": "12"
])
```

## Security Best Practices

1. **Never hardcode API keys** in public repositories
2. **Use public API key only** in iOS app (not secret key)
3. **Validate receipts server-side** (RevenueCat does this automatically)
4. **Check subscription status** on app launch and before accessing premium features
5. **Trust RevenueCat** for subscription truth, not local flags

## Production Checklist

- [ ] RevenueCat account created
- [ ] iOS app configured in RevenueCat
- [ ] App Store Connect in-app purchases created
- [ ] Product IDs match in both systems
- [ ] Shared Secret added to RevenueCat
- [ ] Entitlement "premium" created
- [ ] All products mapped to entitlement
- [ ] SDK integrated and initialized
- [ ] Purchase flow implemented
- [ ] Restore purchase implemented
- [ ] Subscription status checking implemented
- [ ] Paywall UI complete
- [ ] Free trial configured (yearly only)
- [ ] Sandbox testing complete
- [ ] Error handling implemented
- [ ] Analytics tracking set up
- [ ] Privacy policy updated with subscription terms
- [ ] App Store metadata mentions subscriptions

## Migration Strategy

If adding subscriptions to existing app:

1. Grandfather existing users:
   - Give lifetime premium to early adopters
   - Or offer special discount code

2. Communicate changes:
   - Email notification
   - In-app announcement
   - Special "thank you" message

3. Maintain access:
   - Don't immediately lock features
   - Provide grace period
   - Honor commitments

## Additional Resources

- RevenueCat Docs: https://docs.revenuecat.com
- iOS SDK Reference: https://sdk.revenuecat.com/ios/
- Sample Apps: https://github.com/RevenueCat/purchases-ios/tree/main/Examples
- Community: https://community.revenuecat.com
