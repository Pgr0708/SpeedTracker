//
//  PaywallView.swift
//  SpeedTracker
//
import SwiftUI
import SafariServices

struct PaywallView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var purchaseService: PurchaseService
    @StateObject private var authService = AuthService.shared
    @AppStorage(AppConstants.UserDefaultsKeys.hasCompletedPaywall) private var hasCompletedPaywall = false
    @AppStorage(AppConstants.UserDefaultsKeys.isPremium) private var isPremium = false
    @State private var selectedPlanIndex = 2  // default: Yearly
    @State private var appeared = false
    @State private var showTermsSheet = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    HStack {
                        Spacer()
                        Button { withAnimation { hasCompletedPaywall = true; dismiss() } } label: {
                            Text(L10n.text("onboarding.skip"))
                                .font(.bodyMedium)
                                .foregroundColor(theme.textSecondary.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 24).padding(.top, 16)

                    // Crown
                    ZStack {
                        Circle()
                            .fill(RadialGradient(colors: [Color(hex:"FFD700").opacity(0.3), .clear], center: .center, startRadius: 20, endRadius: 80))
                            .frame(width: 140, height: 140)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(LinearGradient(colors: [Color(hex:"FFD700"), Color(hex:"FFA500")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .shadow(color: Color(hex:"FFD700").opacity(0.5), radius: 20)
                    }
                    .scaleEffect(appeared ? 1 : 0.5).opacity(appeared ? 1 : 0)

                    VStack(spacing: 6) {
                        Text(L10n.text("paywall.unlockPremium")).font(.headingMedium).foregroundColor(theme.textPrimary)
                        Text(L10n.text("paywall.fullExperience")).font(.bodySmall).foregroundColor(theme.textSecondary)
                    }.opacity(appeared ? 1 : 0)

                    // Features
                    VStack(alignment: .leading, spacing: 12) {
                        PremiumFeature(icon: "car.windshield.front", text: L10n.string("paywall.featureHud"), color: theme.primaryColor)
                        PremiumFeature(icon: "figure.walk", text: L10n.string("paywall.featurePedometer"), color: Color(hex:"39FF14"))
                        PremiumFeature(icon: "map.fill", text: L10n.string("paywall.featureHistory"), color: Color(hex:"FF6B35"))
                        PremiumFeature(icon: "bell.badge.fill", text: L10n.string("paywall.featureAlerts"), color: Color(hex:"9D4EDD"))
                        PremiumFeature(icon: "paintbrush.fill", text: L10n.string("paywall.featureThemes"), color: Color(hex:"FFD700"))
                        PremiumFeature(icon: "icloud.fill", text: L10n.string("paywall.featureSync"), color: Color(hex:"00D9FF"))
                        PremiumFeature(icon: "arrow.left.arrow.right", text: L10n.string("paywall.featureMirror"), color: Color(hex:"FF3B5C"))
                    }.padding(.horizontal, 28).opacity(appeared ? 1 : 0)

                    // 4 Plan Cards
                    VStack(spacing: 10) {
                        ForEach(Array(purchaseService.plans.enumerated()), id: \.offset) { index, plan in
                            PlanCard(plan: plan, isSelected: selectedPlanIndex == index, theme: theme) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedPlanIndex = index }
                                HapticManager.shared.selection()
                            }
                        }
                    }.padding(.horizontal, 20).opacity(appeared ? 1 : 0)

                    Spacer().frame(height: 220)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            paywallBottomBar
        }
        .sheet(isPresented: $showTermsSheet) {
            InAppWebView(url: URL(string: AppConstants.URLs.termsAndConditions)!)
        }
        .alert("Purchase Error", isPresented: $purchaseService.showError) {
            Button(L10n.string("common.done")) {}
        } message: {
            Text(purchaseService.errorMessage ?? "Unknown purchase error.")
        }
        .alert(L10n.string("paywall.restoreTitle"), isPresented: $purchaseService.showRestoreSuccess) {
            Button(L10n.string("common.done")) {}
        } message: { Text(purchaseService.restoreMessage) }
        .onAppear { withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) { appeared = true } }
        .onChange(of: purchaseService.isPremium) { _, premium in
            if premium {
                hasCompletedPaywall = true
                dismiss()
            }
        }
    }

    private var paywallBottomBar: some View {
        VStack(spacing: 14) {
            if purchaseService.isLoading {
                ProgressView().tint(theme.primaryColor).scaleEffect(1.4).frame(height: 54)
            } else {
                let plan = purchaseService.plans[selectedPlanIndex]
                AnimatedButton(plan.hasTrial ? L10n.string("paywall.startFreeTrial") : L10n.string("paywall.subscribeNow"), icon: plan.hasTrial ? "gift.fill" : "sparkles", variant: .primary) {
                    Task { await purchaseService.purchase(planID: plan.id) }
                }
            }

            #if DEBUG
            Button("⚡ DEV: Unlock Premium") {
                purchaseService.isPremium = true
            }
            .font(.caption)
            .foregroundColor(.orange)
            #endif

            HStack {
                Button(L10n.string("settings.appleSignIn")) {
                    Task {
                        authService.signIn { }
                    }
                }
                .font(.caption)
                .foregroundColor(theme.textSecondary)

                Spacer()

                Button(L10n.string("paywall.restorePurchases")) {
                    Task { await purchaseService.restore() }
                }
                .font(.caption)
                .foregroundColor(theme.textSecondary)

                Spacer()

                Button(L10n.string("paywall.termsButton")) {
                    showTermsSheet = true
                }
                .font(.caption)
                .foregroundColor(theme.primaryColor)
            }

            Text(L10n.text("paywall.autoRenewable"))
                .font(.caption)
                .foregroundColor(theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 20)
        .background(.ultraThinMaterial)
    }
}

struct PlanCard: View {
    let plan: PurchaseService.PlanInfo
    let isSelected: Bool
    let theme: ThemeManager
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                if plan.isMostPopular || plan.isBestValue {
                    Text(plan.isBestValue ? L10n.string("paywall.ribbon.bestValue") : L10n.string("paywall.ribbon.popular"))
                        .font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                        .padding(.vertical, 5).frame(maxWidth: .infinity)
                        .background(plan.isBestValue ? AnyShapeStyle(LinearGradient(colors: [Color(hex:"FFD700"), Color(hex:"FFA500")], startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(theme.primaryGradient))
                }
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(localizedPlanTitle).font(.bodyMedium).foregroundColor(theme.textPrimary)
                        Text(localizedPlanBadge).font(.caption).foregroundColor(plan.hasTrial ? Color(hex:"39FF14") : theme.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(plan.price).font(.orbitron(17)).foregroundColor(theme.textPrimary)
                        if !plan.period.isEmpty {
                            Text(localizedPlanPeriod).font(.caption).foregroundColor(theme.textSecondary)
                        }
                    }
                    Circle().strokeBorder(isSelected ? theme.primaryColor : theme.textSecondary.opacity(0.3), lineWidth: 2).frame(width: 22, height: 22)
                        .overlay(Circle().fill(isSelected ? theme.primaryColor : .clear).frame(width: 12, height: 12))
                        .padding(.leading, 10)
                }.padding(14)
            }
            .background(RoundedRectangle(cornerRadius: 14).fill(theme.isDarkMode ? Color.white.opacity(isSelected ? 0.1 : 0.05) : Color.black.opacity(isSelected ? 0.07 : 0.03)))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(isSelected ? theme.primaryColor : Color.clear, lineWidth: 2))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var localizedPlanTitle: String {
        switch plan.id {
        case AppConstants.Purchase.weeklyProductID: return L10n.string("paywall.plan.weekly")
        case AppConstants.Purchase.monthlyProductID: return L10n.string("paywall.plan.monthly")
        case AppConstants.Purchase.yearlyProductID: return L10n.string("paywall.plan.yearly")
        case AppConstants.Purchase.lifetimeProductID: return L10n.string("paywall.plan.lifetime")
        default: return plan.title
        }
    }

    private var localizedPlanBadge: String {
        switch plan.id {
        case AppConstants.Purchase.weeklyProductID: return L10n.string("paywall.badge.flexible")
        case AppConstants.Purchase.monthlyProductID: return L10n.string("paywall.badge.popular")
        case AppConstants.Purchase.yearlyProductID: return plan.badge
        case AppConstants.Purchase.lifetimeProductID: return L10n.string("paywall.badge.payOnce")
        default: return plan.badge
        }
    }

    private var localizedPlanPeriod: String {
        switch plan.id {
        case AppConstants.Purchase.weeklyProductID: return L10n.string("paywall.period.week")
        case AppConstants.Purchase.monthlyProductID: return L10n.string("paywall.period.month")
        case AppConstants.Purchase.yearlyProductID: return L10n.string("paywall.period.year")
        default: return plan.period
        }
    }
}

#Preview { PaywallView().environmentObject(ThemeManager.shared).environmentObject(PurchaseService.shared) }

struct PremiumFeature: View {
    let icon: String
    let text: String
    let color: Color
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(color).frame(width: 24)
            Text(text).font(.system(size: 14)).foregroundColor(.primary)
            Spacer()
        }
    }
}
