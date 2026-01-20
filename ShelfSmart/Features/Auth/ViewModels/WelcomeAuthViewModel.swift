//
//  WelcomeAuthViewModel.swift
//  ShelfSmart
//
//  Created by Claude on 10/27/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit
import Swift

// Removed SignupMethod enum - simplified to just check if user exists

@Observable
class WelcomeAuthViewModel {
    var emailAddress: String = "" {
        didSet {
            emailValidation()
        }
    }

    var isEmailValid: Bool = false
    var isCheckingUser: Bool = false
    var showingError: Bool = false
    var errorMessage: String = ""

    // Apple Sign In
    var nonce: String? = ""
    var hashedNonce: String? = ""

    // Navigation state
    var shouldNavigateToPassword: Bool = false
    var isSignUpMode: Bool = false // true = sign up, false = sign in

    // MARK: - Email Validation
    private func emailValidation() {
        if emailAddress.filter({ $0 == "@" }).count == 1
            && emailAddress.contains(".")
            && emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).count > 7
            && emailAddress.last?.isLetter ?? false
            && emailAddress.first?.isLetter ?? false {
            isEmailValid = true
        } else {
            isEmailValid = false
        }
    }

    // MARK: - Check User in Firestore
    func checkUserAndProceed() async {
        guard isEmailValid else { return }

        await MainActor.run {
            isCheckingUser = true
        }

        do {
            let (userExists, signUpMethod) = try await checkUserExists(email: emailAddress)

            await MainActor.run {
                isCheckingUser = false

                if userExists {
                    // User exists - check their sign-up method
                    if signUpMethod == "email_password" {
                        // Navigate to sign-in mode
                        isSignUpMode = false
                        shouldNavigateToPassword = true
                    } else if signUpMethod == "apple_signin" {
                        // User registered with Apple - show error
                        errorMessage = "This email was signed up using Apple ID. Please sign up using apple button."
                        showingError = true
                    } else {
                        // Unknown sign-up method
                        errorMessage = "Unable to determine sign-in method. Please contact support."
                        showingError = true
                    }
                } else {
                    // User doesn't exist - navigate to sign-up mode
                    isSignUpMode = true
                    shouldNavigateToPassword = true
                }
            }
        } catch {
            await MainActor.run {
                isCheckingUser = false
                errorMessage = "Unable to verify email. Please try again."
                showingError = true
            }
        }
    }

    private func checkUserExists(email: String) async throws -> (exists: Bool, signUpMethod: String?) {
        // Hash the email to use as document ID in authUsers collection
        let hashedEmail = AuthHelpers.hashEmail(email)

        // Check if document exists in authUsers collection
        let db = Firestore.firestore()
        let authUserDoc = try await db.collection("authUsers").document(hashedEmail).getDocument()

        if authUserDoc.exists {
            // Document exists - get the signupMethod
            let signupMethod = authUserDoc.data()?["signupMethod"] as? String
            return (true, signupMethod)
        } else {
            // Document doesn't exist - new user
            return (false, nil)
        }
    }

    // MARK: - Apple Sign In

    // Generate random nonce string
    private func randomNonceString(length: Int = 32) -> String? {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            print("❌ Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            return nil
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    // SHA 256 encryption
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }

    // Generate nonce with retry logic
    func generateNonce() {
        for attempt in 1...3 {
            if let generatedNonce = self.randomNonceString() {
                nonce = generatedNonce
                hashedNonce = self.sha256(generatedNonce)
                print("✅ Nonce generated successfully on attempt \(attempt)")
                return
            }
            print("⚠️ Nonce generation failed, attempt \(attempt) of 3")
        }

        print("❌ Failed to generate nonce for Apple Sign-In after 3 attempts")
        errorMessage = "Unable to initialize secure sign-in. Please try again."
        showingError = true
    }

    // Handle Apple Sign In
    func handleAppleSignIn(_ authorization: ASAuthorization) async {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce else {
                await MainActor.run {
                    errorMessage = "Cannot process your request"
                    showingError = true
                }
                return
            }

            guard let appleIDToken = appleIDCredential.identityToken else {
                await MainActor.run {
                    errorMessage = "Unable to fetch identity token"
                    showingError = true
                }
                return
            }

            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                await MainActor.run {
                    errorMessage = "Unable to serialize token string"
                    showingError = true
                }
                return
            }

            // Get email from Apple (try credential first, then will check after sign-in)
            let appleEmail = appleIDCredential.email ?? ""

            // If we have an email at this point, check authUsers collection
            if !appleEmail.isEmpty {
                do {
                    let (userExists, signUpMethod) = try await checkUserExists(email: appleEmail)

                    if userExists && signUpMethod == "email_password" {
                        // User already registered with email/password - show error
                        await MainActor.run {
                            errorMessage = "This email is already registered with a password. Please sign in using your email and password."
                            showingError = true
                        }
                        return
                    }
                    // If signUpMethod is "apple_signin" or user doesn't exist, continue with sign-in
                } catch {
                    print("⚠️ Error checking authUsers before Apple Sign In: \(error.localizedDescription)")
                    // Continue anyway - will handle in the sign-in flow
                }
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )

            do {
                let authResult = try await Auth.auth().signIn(with: credential)
                print("User signed in successfully with Apple ID: \(authResult.user.uid)")

                let userId = authResult.user.uid
                let userEmail = authResult.user.email ?? appleIDCredential.email ?? ""

                // Validate we have an email
                if userEmail.isEmpty {
                    await MainActor.run {
                        errorMessage = "Unable to retrieve email from Apple. Please try a different sign-in method."
                        showingError = true
                    }
                    // Sign out the user since we can't proceed without email
                    try? Auth.auth().signOut()
                    return
                }

                // Get user name
                var userName = ""
                if let fullName = appleIDCredential.fullName {
                    var nameComponents: [String] = []

                    if let givenName = fullName.givenName, !givenName.isEmpty {
                        nameComponents.append(givenName)
                    }

                    if let familyName = fullName.familyName, !familyName.isEmpty {
                        nameComponents.append(familyName)
                    }

                    if !nameComponents.isEmpty {
                        userName = nameComponents.joined(separator: " ")
                    }
                }

                if userName.isEmpty {
                    if let displayName = authResult.user.displayName, !displayName.isEmpty {
                        userName = displayName
                    } else if !userEmail.isEmpty {
                        userName = String(userEmail.split(separator: "@").first ?? "User")
                    } else {
                        userName = "Apple User"
                    }
                }

                print("Processing user: \(userName), email: \(userEmail), uid: \(userId)")

                // Hash the email for authUsers collection
                let hashedEmail = AuthHelpers.hashEmail(userEmail)

                let db = Firestore.firestore()

                // Create or update authUsers document
                let authUserDocRef = db.collection("authUsers").document(hashedEmail)
                try await authUserDocRef.setData([
                    "signupMethod": "apple_signin"
                ], merge: true)
                print("✅ authUsers document created/updated for Apple Sign In")

                // Check if user exists in Firestore users collection
                let userDocRef = db.collection("users").document(userId)
                let userDoc = try await userDocRef.getDocument()

                if userDoc.exists {
                    // Existing user signed in with apple
                    print("✅ Existing user signed in with Apple: \(userId)")

                    // Identify user in PostHog analytics
                    PostHogAnalyticsManager.shared.identify(
                        userId: userId,
                        properties: [
                            "email": userEmail,
                            "login_method": "apple_signin"
                        ]
                    )
                } else {
                    print("🆕 New Apple Sign-In user detected - creating Firestore document")

                    let user = User(
                        id: userId,
                        name: userName,
                        email: userEmail,
                        signupMethod: .appleSignIn,
                        isEmailVerified: true,
                        emailVerificationSentAt: Date(),
                        allergies: [],
                        hasCompletedOnboarding: false
                    )

                    try userDocRef.setData(from: user)
                    print("✅ New user created in Firestore")

                    // Identify user in PostHog analytics
                    PostHogAnalyticsManager.shared.identify(
                        userId: userId,
                        properties: [
                            "email": userEmail,
                            "name": userName,
                            "signup_method": "apple_signin",
                            "is_email_verified": true
                        ]
                    )
                }

            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}
