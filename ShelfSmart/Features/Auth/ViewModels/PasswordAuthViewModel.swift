//
//  PasswordAuthViewModel.swift
//  ShelfSmart
//
//  Created by Claude on 10/27/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@Observable
class PasswordAuthViewModel {
    var userName: String = "" {
        didSet {
            validatePassword()
        }
    }

    var password: String = "" {
        didSet {
            validatePassword()
        }
    }

    var confirmPassword: String = "" {
        didSet {
            validatePassword()
        }
    }

    var isButtonActive: Bool = false
    var passwordLengthOk: Bool = false
    var passwordsMatching: Bool = false
    var userNameValid: Bool = false
    var showingError: Bool = false
    var errorMessage: String = ""
    var showingSuccess: Bool = false
    var successMessage: String = ""
    var isLoading: Bool = false

    let email: String
    let isSignUpMode: Bool

    // Forgot Password
    var forgotPasswordEmail: String = "" {
        didSet {
            forgotPasswordEmailValidation()
        }
    }
    var readyForResetPassword: Bool = false
    var isResetLoading: Bool = false
    var resetSuccessMessage: String = ""
    var resetErrorMessage: String = ""
    var showingResetSuccess: Bool = false
    var showingResetError: Bool = false
    var shouldShowSignUpOption: Bool = false
    var shouldShowAppleSignInOptions: Bool = false

    init(email: String, isSignUpMode: Bool) {
        self.email = email
        self.isSignUpMode = isSignUpMode
        // Pre-fill forgot password email with the email user entered
        self.forgotPasswordEmail = email
    }

    // MARK: - Password Validation
    private func validatePassword() {
        // Check password length
        if password.trimmingCharacters(in: .whitespacesAndNewlines).count > 7 {
            passwordLengthOk = true
        } else {
            passwordLengthOk = false
        }

        // Check if passwords match (only relevant for sign-up)
        if isSignUpMode {
            if password == confirmPassword && !password.isEmpty && !confirmPassword.isEmpty {
                passwordsMatching = true
            } else {
                passwordsMatching = false
            }

            // Check if user name is valid (at least 2 characters, trimmed)
            if userName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 {
                userNameValid = true
            } else {
                userNameValid = false
            }

            // Button is active only if all conditions are met for sign-up
            isButtonActive = passwordLengthOk && passwordsMatching && userNameValid
        } else {
            // For sign-in, only password length matters
            isButtonActive = passwordLengthOk
        }
    }

    // MARK: - Sign In
    func signIn() async {
        guard isButtonActive else { return }

        await MainActor.run {
            isLoading = true
        }

        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            print("✅ User signed in successfully")

            // Identify user in PostHog analytics
            if let user = Auth.auth().currentUser {
                PostHogAnalyticsManager.shared.identify(
                    userId: user.uid,
                    properties: [
                        "email": email,
                        "login_method": "email_password"
                    ]
                )
            }

            await MainActor.run {
                isLoading = false
            }
        } catch let error as NSError {
            await MainActor.run {
                isLoading = false

                // Parse Firebase Auth error and provide user-friendly message
                if let authError = AuthErrorCode(rawValue: error.code) {
                    switch authError {
                    case .wrongPassword, .invalidCredential:
                        errorMessage = "Incorrect password. Please try again."

                    case .userNotFound:
                        errorMessage = "Account not found. Please check your email or sign up."

                    case .invalidEmail:
                        errorMessage = "Please enter a valid email address."

                    case .networkError:
                        errorMessage = "Network error. Please check your internet connection."

                    case .tooManyRequests:
                        errorMessage = "Too many failed attempts. Please try again later."

                    case .userDisabled:
                        errorMessage = "This account has been disabled. Please contact support."

                    default:
                        errorMessage = "Unable to sign in. Please try again."
                    }
                } else {
                    errorMessage = "Unable to sign in. Please try again."
                }

                showingError = true
                // Clear password on error
                password = ""
            }
        }
    }

    // MARK: - Sign Up
    func signUp() async {
        guard isButtonActive else { return }

        await MainActor.run {
            isLoading = true
        }

        do {
            // Create user with Firebase Auth
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            print("✅ User account created successfully with ID: \(authResult.user.uid)")

            // Send email verification
            try await authResult.user.sendEmailVerification()
            print("📧 Email verification sent to: \(email)")

            // Store username in Firestore authUsers collection
            let trimmedUserName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
            let hashedEmail = AuthHelpers.hashEmail(email)
            let db = Firestore.firestore()
            let authUserDocRef = db.collection("authUsers").document(hashedEmail)
            try await authUserDocRef.setData([
                "signupMethod": "email_password",
                "pendingUserName": trimmedUserName
            ])
            print("💾 Stored pending user name in Firebase authUsers collection")

            // DO NOT create user in Firestore yet - wait for email verification
            // EmailVerificationView will create the Firestore document after verification

            await MainActor.run {
                isLoading = false
                password = ""
                confirmPassword = ""
                successMessage = "Account created! Please check your email to verify your account."
                showingSuccess = true
                
                successMessage = "Account created! Please check your email to verify your account."
                showingSuccess = true
            }

            // User is now authenticated (Firebase does this automatically)
            // EntryView will detect this and show EmailVerificationView after user dismisses the success alert
            print("🔄 User authenticated - EntryView will show EmailVerificationView")

        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
                showingError = true
                password = ""
                confirmPassword = ""
            }
        }
    }

    // MARK: - Forgot Password

    func forgotPasswordEmailValidation() {
        if forgotPasswordEmail.filter({ $0 == "@" }).count == 1
            && forgotPasswordEmail.contains(".")
            && forgotPasswordEmail.trimmingCharacters(in: .whitespacesAndNewlines).count > 7
            && forgotPasswordEmail.last?.isLetter ?? false
            && forgotPasswordEmail.first?.isLetter ?? false {
            readyForResetPassword = true
        } else {
            readyForResetPassword = false
        }
    }

    private func checkSignupMethod(email: String) async throws -> String? {
        // Hash the email to use as document ID in authUsers collection
        let hashedEmail = AuthHelpers.hashEmail(email)

        // Check authUsers collection
        let db = Firestore.firestore()
        let authUserDoc = try await db.collection("authUsers").document(hashedEmail).getDocument()

        if authUserDoc.exists {
            return authUserDoc.data()?["signupMethod"] as? String
        }

        return nil
    }

    func resetPassword() async {
        await MainActor.run {
            isResetLoading = true
            showingResetSuccess = false
            showingResetError = false
            shouldShowAppleSignInOptions = false
            shouldShowSignUpOption = false
        }

        // Try sending password reset email FIRST
        // Firebase Auth will tell us if the user exists
        let auth = Auth.auth()

        do {
            try await auth.sendPasswordReset(withEmail: forgotPasswordEmail)

            // Success! Firebase sent the reset email
            await MainActor.run {
                isResetLoading = false
                resetSuccessMessage = "Password reset email sent to \(forgotPasswordEmail). Please check your inbox and follow the instructions to reset your password."
                showingResetSuccess = true
            }

        } catch let error as NSError {
            // Password reset failed - handle the error
            await MainActor.run {
                isResetLoading = false
            }

            // Check what kind of error occurred
            if let authError = AuthErrorCode(rawValue: error.code) {
                switch authError {
                case .userNotFound:
                    // User doesn't exist in Firebase Auth
                    // Check Firestore to provide more helpful context
                    await handleUserNotFoundError()

                case .invalidEmail:
                    await MainActor.run {
                        resetErrorMessage = "Please enter a valid email address."
                        showingResetError = true
                    }

                case .networkError:
                    await MainActor.run {
                        resetErrorMessage = "Network error. Please check your internet connection and try again."
                        showingResetError = true
                    }

                case .tooManyRequests:
                    await MainActor.run {
                        resetErrorMessage = "Too many requests. Please wait a moment before trying again."
                        showingResetError = true
                    }

                default:
                    await MainActor.run {
                        resetErrorMessage = "An error occurred: \(error.localizedDescription)"
                        showingResetError = true
                    }
                }
            } else {
                await MainActor.run {
                    resetErrorMessage = "An unexpected error occurred. Please try again."
                    showingResetError = true
                }
            }
        }
    }

    // Helper method to provide context when user is not found
    private func handleUserNotFoundError() async {
        do {
            // Check if user might have signed up with Apple Sign In
            let signupMethod = try await checkSignupMethod(email: forgotPasswordEmail)

            if signupMethod == "apple_signin" {
                // User exists in Firestore with Apple Sign In
                await MainActor.run {
                    resetErrorMessage = "This email was signed up using Apple ID. Please sign up using apple button."
                    shouldShowAppleSignInOptions = true
                    showingResetError = true
                }
            } else {
                // User not found anywhere - suggest sign up
                await MainActor.run {
                    resetErrorMessage = "Email not found. Please sign up to create an account."
                    shouldShowSignUpOption = true
                    showingResetError = true
                }
            }
        } catch {
            // Firestore check failed - show generic not found message
            await MainActor.run {
                resetErrorMessage = "Email not found. Please sign up to create an account."
                shouldShowSignUpOption = true
                showingResetError = true
            }
        }
    }
}
