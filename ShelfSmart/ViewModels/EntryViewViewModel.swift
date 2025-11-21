//
//  EntryViewViewModel.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/21/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@Observable
class EntryViewViewModel{
    var isLoggedIn : Bool = false
    var isEmailVerified : Bool = false
    var hasCompletedOnboarding : Bool? = nil  // nil = unknown, false = not completed, true = completed
    var currentUserId : String = ""
    var currentUserEmail : String = ""

    private var handler : AuthStateDidChangeListenerHandle? = nil

    init() {
        self.handler = Auth.auth().addStateDidChangeListener({ auth, user in
            self.currentUserId = user?.uid ?? ""
            self.currentUserEmail = user?.email ?? ""
            self.isLoggedIn = user != nil

            // Check email verification status
            if let user = user {
                self.isEmailVerified = user.isEmailVerified

                // Identify user in PostHog for already-signed-in users
                PostHogAnalyticsManager.shared.identify(
                    userId: user.uid,
                    properties: [
                        "email": user.email ?? ""
                    ]
                )
            } else {
                // User signed out - reset all state
                self.isEmailVerified = false
                self.hasCompletedOnboarding = nil  // Reset to unknown when signing out
                print("🚪 User signed out - state reset")
            }
        })
    }
    
    func stopHandler(){
        if let handler = handler {
            Auth.auth().removeStateDidChangeListener(handler)
            self.handler = nil
        }
    }

    func refreshUserStatus() async {
        guard let currentUser = Auth.auth().currentUser else {
            // User not authenticated - silently return
            return
        }

        do {
            // Reload user to get latest verification status
            try await currentUser.reload()

            // Fetch onboarding status from Firestore
            let db = Firestore.firestore()
            let userDoc = try await db.collection("users").document(currentUser.uid).getDocument()

            await MainActor.run {
                self.isEmailVerified = currentUser.isEmailVerified

                // Get hasCompletedOnboarding from Firestore
                // If field doesn't exist (existing users), default to false
                if let data = userDoc.data(),
                   let hasCompleted = data["hasCompletedOnboarding"] as? Bool {
                    self.hasCompletedOnboarding = hasCompleted
                    print("✅ Onboarding status fetched: \(hasCompleted)")
                } else {
                    self.hasCompletedOnboarding = false
                    print("⚠️ Onboarding status not found - treating as incomplete (existing user migration)")
                }
            }
        } catch {
            // Check if this is a permission error (expected during account deletion/sign-out)
            let nsError = error as NSError
            if nsError.domain == "FIRFirestoreErrorDomain" && nsError.code == 7 {
                // Code 7 = PERMISSION_DENIED - expected during deletion/sign-out
                print("ℹ️ Permission denied during user status refresh (expected during sign-out)")
            } else {
                print("❌ Error refreshing user status: \(error.localizedDescription)")
            }

            // On error, keep status as unknown (don't assume not completed)
            await MainActor.run {
                self.hasCompletedOnboarding = nil
            }
        }
    }
    
    deinit {    
        // Ensure cleanup happens even if stopHandler() isn't called
        stopHandler()
    }

}
