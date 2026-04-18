//
//  OnboardingContainerView.swift
//  SpeedTracker
//
//  Onboarding flow with smooth animations (step 2 in app flow)
//

import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject var theme: ThemeManager
    @StateObject private var viewModel = OnboardingViewModel()
    
    var body: some View {
        ZStack {
            // Animated gradient background
            theme.backgroundGradient
                .ignoresSafeArea()
            
            // Animated particles/stars effect
            ParticleBackgroundView(theme: theme)
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    
                    Button(action: {
                        viewModel.skip()
                    }) {
                        Text(L10n.text("onboarding.skip"))
                            .font(.bodyMedium)
                            .foregroundColor(theme.textSecondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                }
                .padding(.horizontal, AppConstants.Design.paddingL)
                .padding(.top, AppConstants.Design.paddingM)
                .opacity(viewModel.isLastPage ? 0 : 1)
                
                // Page content with tab view
                TabView(selection: $viewModel.currentPage) {
                    ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                            .environmentObject(theme)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(
                    response: AppConstants.Design.springResponse,
                    dampingFraction: AppConstants.Design.springDampingFraction
                ), value: viewModel.currentPage)
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<viewModel.pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == viewModel.currentPage ?
                                  theme.primaryColor :
                                  theme.textSecondary.opacity(0.3))
                            .frame(width: index == viewModel.currentPage ? 24 : 8,
                                   height: 8)
                            .animation(.spring(
                                response: AppConstants.Design.springResponse,
                                dampingFraction: AppConstants.Design.springDampingFraction
                            ), value: viewModel.currentPage)
                    }
                }
                .padding(.vertical, AppConstants.Design.paddingL)
                
                // Bottom action button
                VStack(spacing: 16) {
                    AnimatedButton(
                        viewModel.isLastPage ? L10n.string("onboarding.getStarted") : L10n.string("onboarding.next"),
                        icon: viewModel.isLastPage ? "checkmark.circle.fill" : "arrow.right",
                        variant: .primary
                    ) {
                        if viewModel.isLastPage {
                            viewModel.completeOnboarding()
                        } else {
                            viewModel.nextPage()
                        }
                    }
                    
                    if !viewModel.isLastPage {
                        Button(action: {
                            viewModel.previousPage()
                        }) {
                            Text(L10n.text("onboarding.back"))
                                .font(.bodyMedium)
                                .foregroundColor(theme.textSecondary)
                                .padding(.vertical, 12)
                        }
                        .opacity(viewModel.currentPage > 0 ? 1 : 0)
                    }
                }
                .padding(.horizontal, AppConstants.Design.paddingXL)
                .padding(.bottom, AppConstants.Design.paddingXL)
            }
        }
    }
}

// Particle background for dynamic effect
struct ParticleBackgroundView: View {
    let theme: ThemeManager
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat
        var opacity: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(theme.primaryColor)
                        .frame(width: 3, height: 3)
                        .scaleEffect(particle.scale)
                        .opacity(particle.opacity)
                        .position(x: particle.x, y: particle.y)
                        .blur(radius: 1)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
                animateParticles()
            }
        }
    }
    
    private func generateParticles(in size: CGSize) {
        particles = (0..<30).map { _ in
            Particle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                scale: CGFloat.random(in: 0.5...1.5),
                opacity: Double.random(in: 0.1...0.4)
            )
        }
    }
    
    private func animateParticles() {
        withAnimation(
            .linear(duration: 3)
            .repeatForever(autoreverses: true)
        ) {
            particles = particles.map { particle in
                var newParticle = particle
                newParticle.opacity = Double.random(in: 0.1...0.5)
                newParticle.scale = CGFloat.random(in: 0.5...1.5)
                return newParticle
            }
        }
    }
}

#Preview {
    OnboardingContainerView()
        .environmentObject(ThemeManager.shared)
}
