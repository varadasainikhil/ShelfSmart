//
//  ReauthenticationView.swift
//  ShelfSmart
//
//  Created for account deletion re-authentication
//

import SwiftUI
import FirebaseAuth
import AuthenticationServices
import CryptoKit

struct ReauthenticationView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isReauthenticated: Bool
    @State private var viewModel: ProfileViewViewModel

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var signupMethod: String = ""
    @State private var isLoadingSignupMethod: Bool = true

    // Apple Sign-In
    @State private var nonce: String = ""
    @State private var hashedNonce: String = ""

    init(isReauthenticated: Binding<Bool>, viewModel: ProfileViewViewModel) {
        self._isReauthenticated = isReauthenticated
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isLoadingSignupMethod {
                    ProgressView("Loading...")
                        .padding()
                } else {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 50))
                            .foregroundStyle(.orange)

                        Text("Verify Your Identity")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("For security, please re-enter your credentials to continue with account deletion.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)

                    Spacer()

                    // Re-authentication options based on signup method
                    if signupMethod == "email_password" {
                        // Email/Password Re-authentication
                        VStack(spacing: 16) {
                            TextField("Email", text: $email)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding(.horizontal)

                            SecureField("Password", text: $password)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.password)
                                .padding(.horizontal)

                            Button(action: {
                                Task {
                                    await reauthenticateWithEmail()
                                }
                            }) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                } else {
                                    Text("Verify")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                }
                            }
                            .background(.green)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .disabled(isLoading || email.isEmpty || password.isEmpty)
                            .opacity((isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                        }
                    } else if signupMethod == "apple_signin" {
                        // Apple Sign-In Re-authentication
                        VStack(spacing: 16) {
                            Text("You signed up with Apple Sign-In")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            SignInWithAppleButton(.signIn) { request in
                                generateNonce()
                                request.requestedScopes = [.email, .fullName]
                                request.nonce = hashedNonce
                            } onCompletion: { result in
                                Task {
                                    await handleAppleSignIn(result)
                                }
                            }
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 50)
                            .padding(.horizontal)
                        }
                    }

                    Spacer()

                    // Cancel button
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Re-authenticate")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                Task {
                    await loadSignupMethod()
                }

                // Pre-fill email if available
                if let currentEmail = Auth.auth().currentUser?.email {
                    email = currentEmail
                }
            }
        }
    }

    // Load user's signup method from Firebase Auth (more reliable than Firestore)
    private func loadSignupMethod() async {
        guard let user = Auth.auth().currentUser else {
            await MainActor.run {
                errorMessage = "No user logged in"
                showError = true
                isLoadingSignupMethod = false
            }
            return
        }

        // Get provider information from Firebase Auth
        // This is the source of truth and doesn't require a network call
        let providers = user.providerData.map { $0.providerID }

        print("🔍 Detected authentication providers: \(providers)")

        await MainActor.run {
            if providers.contains("apple.com") {
                // User signed in with Apple
                signupMethod = "apple_signin"
                print("✅ User authenticated with Apple Sign-In")
            } else if providers.contains("password") {
                // User signed in with email/password
                signupMethod = "email_password"
                print("✅ User authenticated with Email/Password")
            } else {
                // Unknown provider - show error
                errorMessage = "Unable to determine sign-in method. Please try again or contact support."
                showError = true
                print("⚠️ Unknown authentication provider: \(providers)")
            }

            isLoadingSignupMethod = false
        }
    }

    private func reauthenticateWithEmail() async {
        isLoading = true

        do {
            try await viewModel.reauthenticateWithEmail(email: email, password: password)

            await MainActor.run {
                isLoading = false
                isReauthenticated = true
                dismiss()
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                await MainActor.run {
                    errorMessage = "Failed to get Apple ID credentials"
                    showError = true
                }
                return
            }

            do {
                try await viewModel.reauthenticateWithApple(idToken: idTokenString, nonce: nonce)

                await MainActor.run {
                    isReauthenticated = true
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }

        case .failure(let error):
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    // MARK: - Apple Sign-In Nonce Generation

    private func generateNonce() {
        guard let generatedNonce = randomNonceString() else {
            errorMessage = "Unable to generate secure nonce"
            showError = true
            return
        }

        nonce = generatedNonce
        hashedNonce = sha256(generatedNonce)
    }

    private func randomNonceString(length: Int = 32) -> String? {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)

        if errorCode != errSecSuccess {
            return nil
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}
