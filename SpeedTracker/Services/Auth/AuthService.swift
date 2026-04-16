//
//  AuthService.swift
//  SpeedTracker
//
import Foundation
import AuthenticationServices
import SwiftUI
import Combine

@MainActor
class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var userID: String = ""
    @Published var displayName: String = ""
    @Published var email: String = ""
    @Published var isLoading = false

    @AppStorage(AppConstants.UserDefaultsKeys.didLogOut) private var didLogOut = false

    private var signInCompletion: (() -> Void)?

    private override init() {
        super.init()
    }

    // MARK: - Silent credential check on launch
    func checkCredentialState() {
        let storedUserID = KeychainHelper.shared.read(key: "appleUserID") ?? ""
        guard !storedUserID.isEmpty else {
            isAuthenticated = false
            return
        }
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: storedUserID) { [weak self] state, _ in
            DispatchQueue.main.async {
                switch state {
                case .authorized:
                    self?.userID = storedUserID
                    self?.isAuthenticated = true
                    self?.loadProfile()
                case .revoked, .notFound:
                    self?.isAuthenticated = false
                    // Only force logout UI if user manually logged out before
                default:
                    self?.isAuthenticated = false
                }
            }
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
        controller.performRequests()
    }

    // MARK: - Sign Out
    func signOut() {
        isAuthenticated = false
        didLogOut = true
        userID = ""
        displayName = ""
        email = ""
        KeychainHelper.shared.delete(key: "appleUserID")
    }

    private func loadProfile() {
        let profile = UserProfile.load()
        if !profile.userID.isEmpty {
            displayName = profile.displayName
            email = profile.email ?? ""
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        Task { @MainActor in
            self.userID = credential.user
            self.isAuthenticated = true
            self.isLoading = false
            self.didLogOut = false
            KeychainHelper.shared.save(key: "appleUserID", value: credential.user)
            // Save profile
            var profile = UserProfile.load()
            profile = UserProfile(
                displayName: [credential.fullName?.givenName, credential.fullName?.familyName]
                    .compactMap { $0 }.joined(separator: " ").isEmpty
                    ? profile.displayName
                    : [credential.fullName?.givenName, credential.fullName?.familyName].compactMap { $0 }.joined(separator: " "),
                email: credential.email ?? profile.email,
                userID: credential.user,
                weightKg: profile.weightKg,
                dailyStepGoal: profile.dailyStepGoal
            )
            profile.save()
            self.displayName = profile.displayName
            self.email = profile.email ?? ""
            self.signInCompletion?()
            self.signInCompletion = nil
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            self.isLoading = false
        }
    }
}

extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first ?? UIWindow()
    }
}

// MARK: - Keychain Helper
class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}

    func save(key: String, value: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key,
                                    kSecValueData as String: data]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func read(key: String) -> String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key,
                                    kSecReturnData as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete(key: String) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key]
        SecItemDelete(query as CFDictionary)
    }
}
