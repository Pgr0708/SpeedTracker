//
//  SignInView.swift
//  SpeedTracker
//  Only shown when user manually logs out (didLogOut == true)
//
import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var theme: ThemeManager
    @StateObject private var authService = AuthService.shared
    var onSuccess: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            AppConstants.Colors.backgroundGradient.ignoresSafeArea()
            VStack(spacing: 40) {
                Spacer()
                // Branding
                VStack(spacing: 16) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(theme.primaryGradient)
                        .shadow(color: theme.primaryColor.opacity(0.5), radius: 20)
                    Text("SPEEDTRACKER")
                        .font(Font.custom(AppConstants.Typography.orbitronBold, size: 26))
                        .foregroundColor(theme.textPrimary)
                }
                .scaleEffect(appeared ? 1 : 0.8)
                .opacity(appeared ? 1 : 0)

                VStack(spacing: 12) {
                    Text(L10n.text("auth.welcomeBack"))
                        .font(.headingMedium)
                        .foregroundColor(theme.textPrimary)
                    Text(L10n.text("auth.restoreDesc"))
                        .font(.bodySmall)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                Spacer()

                VStack(spacing: 16) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        switch result {
                        case .success:
                            authService.signIn { onSuccess() }
                        case .failure:
                            break
                        }
                    }
                    .signInWithAppleButtonStyle(theme.isDarkMode ? .white : .black)
                    .frame(height: 54)
                    .cornerRadius(14)
                    .padding(.horizontal, 32)

                    Text(L10n.text("auth.privateData"))
                        .font(.caption)
                        .foregroundColor(theme.textTertiary)
                }
                .opacity(appeared ? 1 : 0)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.15)) { appeared = true }
        }
    }
}
