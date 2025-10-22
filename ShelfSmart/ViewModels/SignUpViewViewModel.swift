//
//  AuthenticationManager.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/21/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import CryptoKit
import AuthenticationServices

@Observable
final class SignUpViewViewModel{
    var fullName : String = ""
    var emailAddress : String = "" {
        // Validating the email after a change is made to the email
        didSet {
            emailValidation()
            checkCriteriaMet()
        }
    }
    
    var password : String = "" {
        // Validating the password after a change is made to the email
        
        didSet{
            checkPasswords()
            checkCriteriaMet()
        }
    }
    
    var confirmationPassword : String = "" {
        // Validating the confirmPassword after a change is made to the email
        didSet{
            checkPasswords()
            checkCriteriaMet()
        }
    }
    
    var nonce : String? = ""
    var hashedNonce : String? = ""
    var passwordsMatching = false
    var passwordLengthOk = false
    var isEmailValidated : Bool = false
    var isButtonActive : Bool = false
    var showingError : Bool = false
    var errorMessage : String = ""
    var showingSuccess : Bool = false
    var successMessage : String = ""
    
    
    func checkCriteriaMet(){
        if passwordsMatching  && passwordLengthOk && isEmailValidated {
            isButtonActive = true
        }
        else{
            isButtonActive = false
        }
    }
    
    // Checking if the email has 1 @, ., alteast 7 characters and the first and last character is a letter
    final private func emailValidation() {
        if emailAddress.filter({$0 == "@"}).count == 1
            && emailAddress.contains(".")
            && emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).count > 7
            && emailAddress.last?.isLetter ?? false
            && emailAddress.first?.isLetter ?? false{
            isEmailValidated = true
        }
    }
    
    // Checking passwords if they are matching and if they are atleast 7 characters long
    final func checkPasswords(){
        if password == confirmationPassword {
            passwordsMatching = true
        } else{
            passwordsMatching = false
        }
        
        if password.trimmingCharacters(in: .whitespacesAndNewlines).count > 7 && confirmationPassword.trimmingCharacters(in: .whitespacesAndNewlines).count > 7 {
            passwordLengthOk = true
        }
        else{
            passwordLengthOk = false
        }
    }
    
    // Generating randomNonceString
    private func randomNonceString(length: Int = 32) -> String? {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            print("❌ Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            // Return nil instead of crashing - caller will handle the error
            return nil
        }

        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
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
    
    // Generating Random Nonce and Hashed Nonce with retry logic
    func generateNonce(){
        // Retry up to 3 times if nonce generation fails
        for attempt in 1...3 {
            if let generatedNonce = self.randomNonceString() {
                nonce = generatedNonce
                hashedNonce = self.sha256(generatedNonce)
                print("✅ Nonce generated successfully on attempt \(attempt)")
                return
            }
            print("⚠️ Nonce generation failed, attempt \(attempt) of 3")
        }

        // All attempts failed
        print("❌ Failed to generate nonce for Apple Sign-In after 3 attempts")
        errorMessage = "Unable to initialize secure sign-in. Please try again."
        showingError = true
    }
    
    
    func loginWithFirebase(_ authorization : ASAuthorization) async{
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce  else {
                errorMessage = "Cannot Process your request"
                showingError = true
                return
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                errorMessage = "Unable to fetch identity token"
                showingError = true
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "Unable to serialize token string from data: \(appleIDToken.debugDescription)"
                showingError = true
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            // Initialize a Firebase credential, including the user's full name.
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString, rawNonce: nonce, fullName: appleIDCredential.fullName)
            
            do {
                // Sign in with Firebase using async/await
                let authResult = try await Auth.auth().signIn(with: credential)
                print("User signed in successfully with Apple ID: \(authResult.user.uid)")
                
                // Get user information
                let userId = authResult.user.uid
                let userEmail = authResult.user.email ?? appleIDCredential.email ?? ""
                
                // For the name, try to get it from Apple ID credential first (only available on first sign-in)
                // If not available, use display name from Firebase user or fallback to email prefix
                var userName = ""
                if let fullName = appleIDCredential.fullName {
                    // Construct full name from available parts
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
                
                // Fallback strategies if no name from Apple ID credential
                if userName.isEmpty {
                    if let displayName = authResult.user.displayName,
                       !displayName.isEmpty {
                        userName = displayName
                    } else if !userEmail.isEmpty {
                        // Use email prefix as fallback name
                        userName = String(userEmail.split(separator: "@").first ?? "User")
                    } else {
                        userName = "Apple User"
                    }
                }
                
                print("Processing user: \(userName), email: \(userEmail), uid: \(userId)")

                // Check if user exists in Firestore BEFORE creating
                let db = Firestore.firestore()

                do {
                    // ALWAYS check if user document exists first
                    let userDocRef = db.collection("users").document(userId)
                    let userDoc = try await userDocRef.getDocument()

                    if userDoc.exists {
                        // Returning user - preserve existing data
                        print("✅ Existing user signed in with Apple: \(userId)")

                        // Fetch their onboarding status for logging
                        if let userData = userDoc.data(),
                           let hasCompletedOnboarding = userData["hasCompletedOnboarding"] as? Bool,
                           let allergies = userData["allergies"] as? [String] {
                            print("📊 User onboarding status: \(hasCompletedOnboarding ? "Completed" : "Incomplete")")
                            print("📋 User allergies: \(allergies.isEmpty ? "None" : allergies.joined(separator: ", "))")
                        } else {
                            print("⚠️ User data incomplete - may need to update schema")
                        }
                    } else {
                        // First-time signup - create new user document
                        print("🆕 New Apple Sign-In user detected - creating Firestore document")

                        // Explicitly create user with allergies as empty array
                        let user = User(
                            name: userName,
                            email: userEmail,
                            signupMethod: "apple_signin",
                            isEmailVerified: true,
                            emailVerificationSentAt: Date(),
                            allergies: [],  // Explicitly set to empty array
                            hasCompletedOnboarding: false  // Explicitly set to false
                        )

                        try userDocRef.setData(from: user)
                        print("✅ New user created in Firestore with allergies: [], hasCompletedOnboarding: false")
                        print("📝 User will be shown onboarding flow")
                    }
                } catch {
                    print("❌ Failed to check/save user to Firestore: \(error.localizedDescription)")
                    // Don't fail the sign-in if Firestore operation fails - user is already authenticated
                }
                
            } catch {
                print("Error signing in with Apple: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
                
            }
        }
    }

    // Clear text fields based on success or failure
    func clearTextFields(success: Bool) {
        if success {
            // Clear all fields on successful sign up
            fullName = ""
            emailAddress = ""
            password = ""
            confirmationPassword = ""
        } else {
            // Clear only password fields on failed sign up
            password = ""
            confirmationPassword = ""
        }
    }

    // Creating an account
    func createAccount() async{
        print("Sign Up button is pressed.")
        if isEmailValidated && passwordsMatching && passwordLengthOk{
            do {
                // Create user with Firebase Auth using async/await
                let authResult = try await Auth.auth().createUser(withEmail: emailAddress, password: password)
                print("User account created successfully with ID: \(authResult.user.uid)")

                // Send email verification
                try await authResult.user.sendEmailVerification()
                print("Email verification sent to: \(emailAddress)")

                // DO NOT create user in Firestore yet - wait for email verification
                // User will be added to Firestore only after email verification

                // Clear all fields on successful sign up
                await MainActor.run {
                    self.clearTextFields(success: true)
                    self.successMessage = "Account created! Please check your email to verify your account."
                    self.showingSuccess = true
                }

            } catch {
                print("Error creating account: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                    // Clear only password fields on failed sign up
                    self.clearTextFields(success: false)
                }
            }
        }
    }
}
