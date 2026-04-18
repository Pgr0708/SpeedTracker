//
//  OnboardingPage.swift
//  SpeedTracker
//
//  Onboarding page data model
//

import Foundation

struct OnboardingPage: Identifiable {
    let id = UUID()
    let titleKey: String
    let descriptionKey: String
    let animationName: String
    let iconName: String
    let accentColor: String
}

extension OnboardingPage {
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            titleKey: "onboarding.page1.title",
            descriptionKey: "onboarding.page1.description",
            animationName: AppConstants.Animations.onboarding1,
            iconName: "speedometer",
            accentColor: "00D9FF"
        ),
        OnboardingPage(
            titleKey: "onboarding.page2.title",
            descriptionKey: "onboarding.page2.description",
            animationName: AppConstants.Animations.onboarding2,
            iconName: "map.fill",
            accentColor: "FF6B35"
        ),
        OnboardingPage(
            titleKey: "onboarding.page3.title",
            descriptionKey: "onboarding.page3.description",
            animationName: AppConstants.Animations.onboarding3,
            iconName: "trophy.fill",
            accentColor: "39FF14"
        )
    ]
}
