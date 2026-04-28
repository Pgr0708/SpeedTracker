//
//  AuthService.swift
//  SpeedTracker
//
//  Sign In with Apple + credential management
//

import Foundation
import AuthenticationServices
import SwiftUI
import Combine
import UIKit

@MainActor
class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var userID: String = ""
    @Published var displayName: String = ""
    @Published var email: String = ""
    @Published var isLoading = false

    @AppStorage(AppConstants.UserDefaultsKeys.didLogOut) private var didLogOut = false
    @AppStorage(AppConstants.UserDefaultsKeys.lastCloudKitSync) private var lastCloudKitSync: Double = 0

    private var signInCompletion: (() -> Void)?
    private var authController: ASAuthorizationController?

    private override init() {
        super.init()
        restoreCachedSession()
    }

    // MARK: - Silent credential check on launch
    func checkCredentialState(onAuthenticated: (() -> Void)? = nil) {
        let storedUserID = KeychainHelper.shared.read(key: "appleUserID") ?? ""
        guard !storedUserID.isEmpty else {
            isAuthenticated = false
            userID = ""
            displayName = ""
            email = ""
            return
        }

        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: storedUserID) { [weak self] state, _ in
            DispatchQueue.main.async {
                guard let self else { return }

                switch state {
                case .authorized:
                    self.userID = storedUserID
                    self.isAuthenticated = true
                    self.isLoading = false
                    self.loadProfile(for: storedUserID)
                    self.onSignInComplete()
                    onAuthenticated?()
                case .revoked, .notFound:
                    self.isAuthenticated = false
                    self.userID = ""
                    self.displayName = ""
                    self.email = ""
                    self.authController = nil
                    KeychainHelper.shared.delete(key: "appleUserID")
                default:
                    self.isLoading = false
                }
            }
        }
    }

    // MARK: - Auto Sign In
    func autoSignIn() {
        guard !didLogOut, !isAuthenticated else { return }

        let storedUserID = KeychainHelper.shared.read(key: "appleUserID") ?? ""
        if storedUserID.isEmpty {
            signIn { }
        } else {
            checkCredentialState()
        }
    }

    // MARK: - Sign In with Apple
    func signIn(onSuccess: @escaping () -> Void) {
        isLoading = true
        signInCompletion = onSuccess

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        authController = controller
        controller.performRequests()
    }

    // MARK: - Sign Out
    func signOut() {
        isAuthenticated = false
        didLogOut = true
        isLoading = false
        userID = ""
        displayName = ""
        email = ""
        authController = nil
        signInCompletion = nil
        KeychainHelper.shared.delete(key: "appleUserID")

        // Preserve email in profile so re-login can restore it (Apple sends email only once)
        let profile = UserProfile.load()
        UserProfile(
            displayName: profile.displayName,
            email: profile.email,
            userID: "",
            weightKg: profile.weightKg,
            dailyStepGoal: profile.dailyStepGoal
        ).save()

        lastCloudKitSync = 0

        // Lock premium features and clear local data
        PurchaseService.shared.resetToFreeMode()
        TripStore.shared.clearAllTrips()
        PedometerService.shared.clearAllSessions()
    }

    // MARK: - Sign In if needed
    func signInIfNeeded(forcePrompt: Bool = false) {
        guard forcePrompt || !didLogOut else { return }
        guard !isAuthenticated else { return }

        let storedUserID = KeychainHelper.shared.read(key: "appleUserID") ?? ""
        if !storedUserID.isEmpty {
            checkCredentialState()
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            guard !self.isAuthenticated else { return }
            self.signIn { }
        }
    }

    // MARK: - Handle Native SignInWithAppleButton Result
    func handleAuthorizationResult(_ result: Result<ASAuthorization, Error>, onSuccess: (() -> Void)? = nil) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                isLoading = false
                authController = nil
                return
            }
            completeSignIn(with: credential, onSuccess: onSuccess)
        case .failure:
            isLoading = false
            authController = nil
            signInCompletion = nil
        }
    }

    // MARK: - Sign In success handler
    private func onSignInComplete() {
        didLogOut = false
        Task {
            await PurchaseService.shared.syncRevenueCatUser(
                isAuthenticated: isAuthenticated,
                userID: userID
            )
            await PurchaseService.shared.checkPremiumStatus()
        }
        CloudKitService.shared.syncAll(tripStore: TripStore.shared, pedometerService: PedometerService.shared)
    }

    private func restoreCachedSession() {
        guard !didLogOut else { return }

        let storedUserID = KeychainHelper.shared.read(key: "appleUserID") ?? ""
        guard !storedUserID.isEmpty else { return }

        userID = storedUserID
        isAuthenticated = true
        loadProfile(for: storedUserID)
    }

    private func loadProfile(for expectedUserID: String? = nil) {
        let profile = UserProfile.load()
        let canUseProfile = expectedUserID == nil || profile.userID.isEmpty || profile.userID == expectedUserID
        let keychainDisplayName = expectedUserID.flatMap { KeychainHelper.shared.read(key: keychainDisplayNameKey(for: $0)) } ?? ""
        let keychainEmail = expectedUserID.flatMap { KeychainHelper.shared.read(key: keychainEmailKey(for: $0)) } ?? ""

        let resolvedDisplayName = canUseProfile && !profile.displayName.isEmpty && profile.displayName != UserProfile.default.displayName
            ? profile.displayName
            : keychainDisplayName
        let resolvedEmail = canUseProfile && !(profile.email ?? "").isEmpty
            ? (profile.email ?? "")
            : keychainEmail

        displayName = resolvedDisplayName
        email = resolvedEmail

        if let expectedUserID {
            let persistedProfile = UserProfile(
                displayName: resolvedDisplayName.isEmpty ? profile.displayName : resolvedDisplayName,
                email: resolvedEmail.isEmpty ? profile.email : resolvedEmail,
                userID: expectedUserID,
                weightKg: profile.weightKg,
                dailyStepGoal: profile.dailyStepGoal
            )
            persistedProfile.save()
            persistIdentitySnapshot(for: persistedProfile)
        }
    }

    private func completeSignIn(with credential: ASAuthorizationAppleIDCredential, onSuccess: (() -> Void)? = nil) {
        userID = credential.user
        isAuthenticated = true
        isLoading = false
        didLogOut = false
        authController = nil

        KeychainHelper.shared.save(key: "appleUserID", value: credential.user)

        let currentProfile = UserProfile.load()
        let updatedName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        let profile = UserProfile(
            displayName: updatedName.isEmpty ? currentProfile.displayName : updatedName,
            email: credential.email ?? currentProfile.email,
            userID: credential.user,
            weightKg: currentProfile.weightKg,
            dailyStepGoal: currentProfile.dailyStepGoal
        )

        profile.save()
        persistIdentitySnapshot(for: profile)
        displayName = profile.displayName
        email = profile.email ?? ""

        onSignInComplete()

        let storedCompletion = signInCompletion
        signInCompletion = nil
        storedCompletion?()
        onSuccess?()
    }

    private func persistIdentitySnapshot(for profile: UserProfile) {
        guard !profile.userID.isEmpty else { return }

        if !profile.displayName.isEmpty {
            KeychainHelper.shared.save(key: keychainDisplayNameKey(for: profile.userID), value: profile.displayName)
        }

        if let email = profile.email, !email.isEmpty {
            KeychainHelper.shared.save(key: keychainEmailKey(for: profile.userID), value: email)
        }
    }

    private func keychainDisplayNameKey(for userID: String) -> String {
        "appleDisplayName.\(userID)"
    }

    private func keychainEmailKey(for userID: String) -> String {
        "appleEmail.\(userID)"
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            self.handleAuthorizationResult(.success(authorization))
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            self.handleAuthorizationResult(.failure(error))
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }

            if let keyWindow = windowScenes
                .first(where: { $0.activationState == .foregroundActive })?
                .windows
                .first(where: { $0.isKeyWindow }) {
                return keyWindow
            }

            if let firstWindow = windowScenes.flatMap(\.windows).first {
                return firstWindow
            }

            return UIWindow()
        }
    }
}

// MARK: - Keychain Helper
class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}

    func save(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)

        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
