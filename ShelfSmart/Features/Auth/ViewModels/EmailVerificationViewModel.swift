//
//  EmailVerificationViewModel.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/23/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@Observable
final class EmailVerificationViewModel {
    var userEmail: String
    var userFullName: String
    var isCheckingVerification: Bool = false
    var isResendingEmail: Bool = false
    var resendCooldownSeconds: Int = 0
    var showingSuccess: Bool = false
    var showingError: Bool = false
    var successMessage: String = ""
    var errorMessage: String = ""
    private var cooldownTimer: Timer?
    private let resendCooldownDuration: Int = 60 // 60 seconds cooldown

    var canResendEmail: Bool {
        return !isResendingEmail && resendCooldownSeconds == 0
    }

    init(userEmail: String, userFullName: String) {
        self.userEmail = userEmail
        self.userFullName = userFullName
    }

    func checkEmailVerification(onSuccess: (() async -> Void)? = nil) async {
        await MainActor.run {
            isCheckingVerification = true
        }

        do {
            // Reload the current user to get the latest verification status
            try await Auth.auth().currentUser?.reload()

            guard let currentUser = Auth.auth().currentUser else {
                await MainActor.run {
                    self.errorMessage = "No user found. Please try signing up again."
                    self.showingError = true
                    self.isCheckingVerification = false
                }
                return
            }

            if currentUser.isEmailVerified {
                // Email is verified, create user in Firestore
                await createUserInFirestore(currentUser)

                await MainActor.run {
                    self.successMessage = "Email verified successfully! Welcome to ShelfSmart."
                    self.showingSuccess = true
                    self.isCheckingVerification = false
                }

                // Call the success callback if provided
                if let onSuccess = onSuccess {
                    await onSuccess()
                }
            } else {
                await MainActor.run {
                    self.errorMessage = "Email not yet verified. Please check your inbox and click the verification link."
                    self.showingError = true
                    self.isCheckingVerification = false
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Error checking verification status: \(error.localizedDescription)"
                self.showingError = true
                self.isCheckingVerification = false
            }
        }
    }

    func resendVerificationEmail() async {
        guard canResendEmail else { return }

        await MainActor.run {
            isResendingEmail = true
        }

        do {
            try await Auth.auth().currentUser?.sendEmailVerification()

            await MainActor.run {
                self.successMessage = "Verification email sent! Please check your inbox."
                self.showingSuccess = true
                self.isResendingEmail = false
                self.startResendCooldown()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Error sending verification email: \(error.localizedDescription)"
                self.showingError = true
                self.isResendingEmail = false
            }
        }
    }

    func signOut() async {
        do {
            try Auth.auth().signOut()
        } catch {
            await MainActor.run {
                self.errorMessage = "Error signing out: \(error.localizedDescription)"
                self.showingError = true
            }
        }
    }

    private func createUserInFirestore(_ firebaseUser: FirebaseAuth.User) async {
        let db = Firestore.firestore()
        let userId = firebaseUser.uid
        let userEmail = firebaseUser.email ?? ""

        do {
            // 1. Fetch the pending user name from authUsers collection
            let hashedEmail = AuthHelpers.hashEmail(userEmail)
            let authUserDocRef = db.collection("authUsers").document(hashedEmail)
            let authUserDoc = try await authUserDocRef.getDocument()

            var userName = userFullName // Default to passed value
            if let pendingName = authUserDoc.data()?["pendingUserName"] as? String, !pendingName.isEmpty {
                userName = pendingName
                print("📥 Retrieved pending user name from authUsers: \(pendingName)")
            }

            // 2. Update authUsers document with signupMethod only (remove pendingUserName)
            try await authUserDocRef.setData([
                "signupMethod": "email_password"
            ], merge: true)
            print("✅ authUsers document updated for email_password user")

            // 3. Create user document in users collection
            let user = User(
                id: userId,
                name: userName,
                email: userEmail,
                signupMethod: .email,
                isEmailVerified: true,
                emailVerificationSentAt: Date()
            )

            try db.collection("users").document(userId).setData(from: user)
            print("✅ Verified user with ID: \(userId) added to Firestore")

            // Identify user in PostHog analytics
            PostHogAnalyticsManager.shared.identify(
                userId: userId,
                properties: [
                    "email": userEmail,
                    "name": userName,
                    "signup_method": "email_password",
                    "is_email_verified": true
                ]
            )
        } catch {
            print("❌ Error adding verified user to Firestore: \(error.localizedDescription)")
        }
    }


    func startCooldownTimer() {
        // Start with initial cooldown if recently sent
        startResendCooldown()
    }

    func stopCooldownTimer() {
        cooldownTimer?.invalidate()
        cooldownTimer = nil
    }

    private func startResendCooldown() {
        resendCooldownSeconds = resendCooldownDuration

        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                if self.resendCooldownSeconds > 0 {
                    self.resendCooldownSeconds -= 1
                } else {
                    self.cooldownTimer?.invalidate()
                    self.cooldownTimer = nil
                }
            }
        }
    }

    deinit {
        stopCooldownTimer()
    }
}