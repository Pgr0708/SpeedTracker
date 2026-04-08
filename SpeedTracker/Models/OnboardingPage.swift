//
//  OnboardingPage.swift
//  SpeedTracker
//
//  Onboarding page data model
//

import Foundation

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let animationName: String
    let iconName: String
    let accentColor: String
}

extension OnboardingPage {
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Track Your Speed",
            description: "Real-time GPS speed tracking with precision accuracy. Monitor your speed in km/h, mph, m/s, or knots.",
            animationName: AppConstants.Animations.onboarding1,
            iconName: "speedometer",
            accentColor: "00D9FF"
        ),
        OnboardingPage(
            title: "Record Your Journeys",
            description: "Automatically save your trips with detailed statistics, routes, and achievements.",
            animationName: AppConstants.Animations.onboarding2,
            iconName: "map.fill",
            accentColor: "FF6B35"
        ),
        OnboardingPage(
            title: "Compete & Improve",
            description: "Set personal records, track your progress, and challenge yourself to go faster.",
            animationName: AppConstants.Animations.onboarding3,
            iconName: "trophy.fill",
            accentColor: "39FF14"
        )
    ]
}
