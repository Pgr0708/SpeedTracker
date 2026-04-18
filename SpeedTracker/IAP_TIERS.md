# In-App Purchase Tiers

Detailed specification for Speed Tracker subscription products.

## Product Strategy

**Model**: Freemium with multiple subscription options
**Goal**: Maximize revenue while providing choice
**Approach**: Weekly for testers, Monthly for flexibility, Yearly for value, Lifetime for commitment

## Product Identifiers

All products follow reverse domain notation:

```
speedtracker_weekly
speedtracker_monthly
speedtracker_yearly
speedtracker_lifetime
```

**Note**: These IDs must be created in App Store Connect and match exactly in code.

## Subscription Group

**Group Name**: "Premium Access"
**Group ID**: `premium_access_group`

All auto-renewable subscriptions must be in the same group per Apple's requirements.

## Product Definitions

### 1. Weekly Subscription

**Product ID**: `speedtracker_weekly`
**Type**: Auto-renewable subscription
**Duration**: 1 week (7 days)
**Price**: $1.99 USD
**Renewal**: Automatic

**Localized Prices** (examples):
- United States: $1.99
- Canada: $3.99 CAD
- United Kingdom: £2.99
- Europe: €2.99
- Australia: $4.49 AUD
- Japan: ¥350

**Display Name**: "Weekly Premium"
**Description**: "Full access to all premium features for one week with automatic renewal."

**Marketing Copy**:
- Tagline: "Try Premium Risk-Free"
- Benefit: "Perfect for testing premium features before committing long-term"
- Best For: "Occasional users and trial seekers"

**Free Trial**: None

---

### 2. Monthly Subscription

**Product ID**: `speedtracker_monthly`
**Type**: Auto-renewable subscription
**Duration**: 1 month (30 days)
**Price**: $4.99 USD
**Renewal**: Automatic

**Localized Prices**:
- United States: $4.99
- Canada: $10.99 CAD
- United Kingdom: £7.99
- Europe: €7.99
- Australia: $11.99 AUD
- Japan: ¥900

**Display Name**: "Monthly Premium"
**Description**: "Full premium access with monthly billing. Cancel anytime."

**Marketing Copy**:
- Tagline: "Best Flexibility"
- Badge: "Most Popular"
- Benefit: "Pay monthly, cancel anytime, no long-term commitment"
- Best For: "Regular users who want flexibility"

**Savings**: 38% vs weekly ($8/month if weekly)

**Free Trial**: None

---

### 3. Yearly Subscription (Recommended)

**Product ID**: `speedtracker_yearly`
**Type**: Auto-renewable subscription
**Duration**: 1 year (365 days)
**Price**: $19.99 USD
**Renewal**: Automatic

**Localized Prices**:
- United States: $19.99
- Canada: $64.99 CAD
- United Kingdom: £49.99
- Europe: €49.99
- Australia: $74.99 AUD
- Japan: ¥6,000

**Display Name**: "Yearly Premium"
**Description**: "One year of premium features at the lowest effective monthly price."

**Marketing Copy**:
- Tagline: "BEST VALUE"
- Badge: "Best Value"
- Benefit: "Just $2.08/month - save $79/year vs weekly plan"
- Best For: "Committed users who drive regularly"

**Free Trial**: None

**Savings**: 
- 58% vs monthly ($60/year if monthly)
- 76% vs weekly ($104/year if weekly)

**Introductory Offer**: None

---

### 4. Lifetime Purchase

**Product ID**: `speedtracker_lifetime`
**Type**: Non-consumable (one-time purchase)
**Duration**: Forever (non-renewing)
**Price**: $99.99 USD

**Localized Prices**:
- United States: $99.99
- Canada: $129.99 CAD
- United Kingdom: £99.99
- Europe: €99.99
- Australia: $149.99 AUD
- Japan: ¥12,000

**Display Name**: "Lifetime Premium"
**Description**: "One-time purchase for lifetime access to all premium features. No subscriptions, ever."

**Marketing Copy**:
- Tagline: "Pay Once, Use Forever"
- Badge: "BEST FOR POWER USERS"
- Benefit: "Never pay again. Lifetime access for less than 2 years of monthly subscriptions."
- Best For: "Long-term users and power drivers"

**Value Proposition**: 
- Pays for itself in 13 months vs monthly plan
- Pays for itself in 2 years vs yearly plan
- No recurring charges ever

**No Free Trial**: Lifetime is immediate purchase

---

## Price Comparison Table

| Plan | Price | Per Month | Per Year | Savings |
|------|-------|-----------|----------|---------|
| Weekly | $2/week | $8.00 | $104.00 | — |
| Monthly | $5/month | $5.00 | $60.00 | 38% vs weekly |
| Yearly | $25/year | $2.08 | $25.00 | 76% vs weekly, 58% vs monthly |
| Lifetime | $99.99 once | — | — | Pays for itself in 13 months vs monthly |

## Paywall Display Strategy

### Visual Hierarchy

1. **Yearly** (top position, highlighted)
   - Large card with blue border
   - "BEST VALUE" badge
   - "BEST VALUE" badge
   - Show monthly price: "$2.08/month"
   - Small text: "Billed annually at $25"
   - Most prominent CTA

2. **Lifetime** (second position)
   - "PAY ONCE" badge
   - "Never pay again"
   - Show one-time price: "$99.99"
   - "Most popular with power users"

3. **Monthly** (third position)
   - "FLEXIBLE" badge
   - "Save 15% vs weekly"
   - Show monthly price: "$5/month"
   - "Cancel anytime"

4. **Weekly** (last position, smaller)
   - No badge
   - Show weekly price: "$2/week"
   - "Try before committing"

### Recommended Default

**Pre-select Yearly** by default to encourage best value option.

User can tap other options to change selection.

### CTA Button Text

- Weekly: "Subscribe for $2/week"
- Monthly: "Subscribe for $5/month"
- Yearly: "Subscribe for $25/year"
- Lifetime: "Buy Lifetime Access for $99.99"

## App Store Connect Configuration

### Subscription Group Settings

**Group Name**: Premium Access
**Description**: Access to all Speed Tracker premium features

**Subscription Ranking** (determines upgrade/downgrade):
1. Weekly (lowest rank)
2. Monthly
3. Yearly (highest rank)

### Yearly Subscription Free Trial

In App Store Connect for yearly product:

**Introductory Offer Type**: Free trial
**Duration**: 3 days
**Eligible**: New subscribers only

**Configuration**:
```
Free trial duration: 3 days
Standard price: $49.99
Duration: 1 year
Renewal: Automatic
```

### Lifetime Purchase

**Product Type**: Non-consumable
**Price**: $99.99
**Duration**: N/A (permanent)

**Important**: Non-consumable purchases must be restorable across devices.

## Localization Requirements

Each product needs localized metadata:

### Languages to Support

1. English (US, UK, Australia)
2. Spanish (Spain, Mexico, Latin America)
3. French (France, Canada)
4. German
5. Japanese
6. Chinese (Simplified, Traditional)

### Localized Fields

For each product in each language:
- **Display Name**
- **Description**
- **Marketing badges** (translated)

### Regional Pricing

Use App Store Connect's automatic pricing suggestions based on USD price.

**Manual Adjustments**:
- Round to .99 for psychological pricing
- Consider local purchasing power
- Match competitor pricing in each region

## Subscription Terms (Legal)

### Auto-Renewal Terms

Required disclosure per Apple guidelines:

```
• Payment will be charged to iTunes Account at confirmation of purchase
• Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period
• Account will be charged for renewal within 24 hours prior to the end of the current period
• Subscriptions may be managed by the user and auto-renewal may be turned off by going to the user's Account Settings after purchase
• Any unused portion of a free trial period, if offered, will be forfeited when the user purchases a subscription
```

### Links Required on Paywall

- Terms of Service: https://speedtracker.app/terms
- Privacy Policy: https://speedtracker.app/privacy
- Restore Purchases button

## Subscription Management

### User Can Manage Subscriptions

Users manage subscriptions through:
1. iOS Settings app
2. App Store app → Account → Subscriptions
3. App Store Connect account (web)

**Not** through Speed Tracker app (per Apple rules).

### App Responsibilities

Speed Tracker app must:
- Provide "Restore Purchase" button
- Show current subscription status in Settings
- Provide link to manage subscription (deep link to Settings)
- Handle subscription changes gracefully

## Upgrade/Downgrade Scenarios

### Upgrade Paths

**Weekly → Monthly**: 
- Prorated credit for unused weekly time
- Immediate access to monthly subscription

**Weekly/Monthly → Yearly**:
- Prorated credit
- Immediate yearly subscription with trial forfeited (already subscribed)

**Any Subscription → Lifetime**:
- Existing subscription runs until expiration
- Lifetime access activates immediately
- No refund on existing subscription (Apple policy)

### Downgrade Paths

**Yearly → Monthly/Weekly**:
- User loses remaining yearly time at period end
- New lower-tier subscription starts after current period

**Monthly → Weekly**:
- Similar to above

**Note**: Apple handles all proration and billing logic.

## Refund Policy

### App Store Refunds

Refunds are handled by Apple, not by Speed Tracker.

Users can request refunds through:
- reportaproblem.apple.com
- App Store app

### Grace Period

If payment fails, Apple may provide grace period (16-60 days depending on region).

During grace period:
- User retains premium access
- App shows billing issue warning
- User can update payment method

RevenueCat detects grace period automatically.

## Revenue Projections (Example)

Assumptions:
- 10,000 active users
- 20% conversion to premium
- 2,000 premium users

**Revenue Mix Estimate**:
- 10% Weekly: 200 users × $2.99 = $598/week = $31,096/year
- 30% Monthly: 600 users × $7.99 = $4,794/month = $57,528/year
- 50% Yearly: 1,000 users × $49.99 = $49,990/year
- 10% Lifetime: 200 users × $99.99 = $19,998 (one-time)

**Total Year 1**: ~$158,612

**Apple's Cut (30%)**: -$47,584
**Net Revenue**: ~$111,028

**Year 2+** (assuming 70% retention):
- Recurring: ~$97,027/year
- New lifetime purchases: lower but continuous

## A/B Testing Recommendations

Test these variables:

1. **Default Selection**: Yearly vs Monthly vs Lifetime
2. **Pricing**: $49.99 vs $44.99 vs $59.99 for yearly
3. **Trial Duration**: 3 days vs 7 days vs no trial
4. **Badge Copy**: "Best Value" vs "Most Popular" vs "Recommended"
5. **CTA Text**: "Start Free Trial" vs "Subscribe Now" vs "Unlock Premium"

Use RevenueCat's A/B testing features or third-party tools.

## Edge Cases

### Family Sharing

**Decision**: Do NOT enable Family Sharing initially.

**Reason**: Reduces revenue (6 users for price of 1).

**Future**: Consider enabling for yearly/lifetime only as a premium perk.

### Promotional Offers

Apple allows promotional offers for lapsed subscribers:

**Examples**:
- "Win-back" offer: 1 month for $0.99
- "Upgrade" offer: 50% off yearly
- "Friend" offer: 3 months for $14.99

Configure in App Store Connect after launch.

### Student Discounts

Consider future student pricing:
- Yearly: $34.99 (30% off)
- Require student verification via third-party service

## Implementation Checklist

- [ ] Create products in App Store Connect
- [ ] Configure subscription group
- [ ] Set up introductory offer (3-day trial for yearly)
- [ ] Add products to RevenueCat dashboard
- [ ] Map products to "premium" entitlement
- [ ] Localize product metadata (6+ languages)
- [ ] Set regional pricing (use Apple's suggestions)
- [ ] Test all products in sandbox
- [ ] Test free trial flow
- [ ] Test restore purchases
- [ ] Test subscription management
- [ ] Submit for App Review with subscription products
- [ ] Monitor analytics after launch
- [ ] Iterate based on conversion data
