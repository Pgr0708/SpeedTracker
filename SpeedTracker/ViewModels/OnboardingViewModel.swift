//
//  OnboardingViewModel.swift
//  SpeedTracker
//
//  Onboarding flow view model
//

import SwiftUI
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentPage: Int = 0
    @Published var hasCompletedOnboarding: Bool = false
    
    let pages = OnboardingPage.pages
    
    var isLastPage: Bool {
        currentPage == pages.count - 1
    }
    
    func nextPage() {
        if currentPage < pages.count - 1 {
            withAnimation(.spring(
                response: AppConstants.Design.springResponse,
                dampingFraction: AppConstants.Design.springDampingFraction
            )) {
                currentPage += 1
            }
            HapticManager.shared.selection()
        }
    }
    
    func previousPage() {
        if currentPage > 0 {
            withAnimation(.spring(
                response: AppConstants.Design.springResponse,
                dampingFraction: AppConstants.Design.springDampingFraction
            )) {
                currentPage -= 1
            }
            HapticManager.shared.selection()
        }
    }
    
    func skip() {
        completeOnboarding()
    }
    
    func completeOnboarding() {
        HapticManager.shared.notification(type: .success)
        UserDefaults.standard.set(true, forKey: AppConstants.UserDefaultsKeys.hasCompletedOnboarding)
        withAnimation(.spring(
            response: AppConstants.Design.springResponse,
            dampingFraction: AppConstants.Design.springDampingFraction
        )) {
            hasCompletedOnboarding = true
        }
    }
}
