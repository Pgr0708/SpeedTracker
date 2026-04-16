//
//  PaywallView.swift
//  SpeedTracker
//
import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var purchaseService: PurchaseService
    @AppStorage(AppConstants.UserDefaultsKeys.hasCompletedPaywall) private var hasCompletedPaywall = false
    @AppStorage(AppConstants.UserDefaultsKeys.isPremium) private var isPremium = false
    @State private var selectedPlanIndex = 2  // default: Yearly
    @State private var appeared = false
    @State private var showRestoreAlert = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Skip / X
                    HStack {
                        Spacer()
                        Button { withAnimation { hasCompletedPaywall = true; dismiss() } } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(theme.textSecondary.opacity(0.5))
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
                        Text("Unlock Premium").font(.system(size: 30, weight: .bold, design: .rounded)).foregroundColor(theme.textPrimary)
                        Text("Full speed tracking experience").font(.system(size: 15)).foregroundColor(theme.textSecondary)
                    }.opacity(appeared ? 1 : 0)

                    // Features
                    VStack(alignment: .leading, spacing: 12) {
                        PremiumFeature(icon: "car.windshield.front", text: "HUD Mode — windshield display", color: theme.primaryColor)
                        PremiumFeature(icon: "figure.walk", text: "Pedometer with calorie tracking", color: Color(hex:"39FF14"))
                        PremiumFeature(icon: "map.fill", text: "Full trip history with maps", color: Color(hex:"FF6B35"))
                        PremiumFeature(icon: "bell.badge.fill", text: "Speed limit alerts + beep sounds", color: Color(hex:"9D4EDD"))
                        PremiumFeature(icon: "paintbrush.fill", text: "Color themes & customization", color: Color(hex:"FFD700"))
                        PremiumFeature(icon: "icloud.fill", text: "iCloud sync across devices", color: Color(hex:"00D9FF"))
                        PremiumFeature(icon: "arrow.left.arrow.right", text: "Mirror mode for reflections", color: Color(hex:"FF3B5C"))
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

                    // Subscribe button
                    if purchaseService.isLoading {
                        ProgressView().tint(theme.primaryColor).scaleEffect(1.5).frame(height: 54)
                    } else {
                        let plan = purchaseService.plans[selectedPlanIndex]
                        AnimatedButton(plan.hasTrial ? "Start Free Trial" : "Subscribe Now", icon: plan.hasTrial ? "gift.fill" : "sparkles", variant: .primary) {
                            Task { await purchaseService.purchase(planID: plan.id)
                                if isPremium { hasCompletedPaywall = true; dismiss() }
                            }
                        }.padding(.horizontal, 24)
                    }

                    HStack(spacing: 20) {
                        Button("Restore Purchases") {
                            Task { await purchaseService.restore()
                                if isPremium { hasCompletedPaywall = true; dismiss() }
                            }
                        }.font(.system(size: 13)).foregroundColor(theme.textSecondary)
                        Button("Continue Free") { withAnimation { hasCompletedPaywall = true; dismiss() } }
                            .font(.system(size: 13, weight: .medium)).foregroundColor(theme.primaryColor)
                    }
                    Text("Auto-renewable. Cancel anytime in App Store settings.")
                        .font(.system(size: 11)).foregroundColor(theme.textTertiary).multilineTextAlignment(.center)
                        .padding(.horizontal, 40).padding(.bottom, 30)
                }
            }
        }
        .alert("Purchases Restored", isPresented: $purchaseService.showRestoreSuccess) {
            Button("OK") {}
        } message: { Text(isPremium ? "Your premium access has been restored!" : "No active subscription found.") }
        .onAppear { withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) { appeared = true } }
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
                    Text(plan.isBestValue ? "BEST VALUE" : "MOST POPULAR")
                        .font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                        .padding(.vertical, 5).frame(maxWidth: .infinity)
                        .background(plan.isBestValue ? AnyShapeStyle(LinearGradient(colors: [Color(hex:"FFD700"), Color(hex:"FFA500")], startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(theme.primaryGradient))
                }
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(plan.title).font(.system(size: 17, weight: .bold)).foregroundColor(theme.textPrimary)
                        Text(plan.badge).font(.system(size: 12)).foregroundColor(plan.hasTrial ? Color(hex:"39FF14") : theme.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(plan.price).font(.system(size: 17, weight: .bold)).foregroundColor(theme.textPrimary)
                        if !plan.period.isEmpty {
                            Text(plan.period).font(.system(size: 12)).foregroundColor(theme.textSecondary)
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
