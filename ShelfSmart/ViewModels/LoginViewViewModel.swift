//
//  LoginViewViewModel.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/21/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

@Observable
class LoginViewViewModel{
    var emailAddress : String = ""{
        didSet{
            emailAndPasswordValidation()
        }
    }
    
    var password : String = ""{
        didSet{
            emailAndPasswordValidation()
        }
    }
    
    var readyForSignIn : Bool = false
    var errorMessage : String = ""
    var showingError : Bool = false
    var nonce : String? = ""
    var hashedNonce : String? = ""
    
    // ForgotPasswordView Variables
    var readyForResetPassword = false
    var forgotPasswordEmail : String = "" {
        didSet{
            forgotPasswordEmailValidation()
        }
    }
    var isResetLoading = false
    var resetSuccessMessage = ""
    var resetErrorMessage = ""
    var showingResetSuccess = false
    var showingResetError = false
    var shouldShowSignUpOption = false
    var shouldShowAppleSignInOptions = false

    func forgotPasswordEmailValidation(){
        if forgotPasswordEmail.filter({$0 == "@"}).count == 1
            && forgotPasswordEmail.contains(".")
            && forgotPasswordEmail.trimmingCharacters(in: .whitespacesAndNewlines).count > 7
            && forgotPasswordEmail.last?.isLetter ?? false
            && forgotPasswordEmail.first?.isLetter ?? false{
            readyForResetPassword = true
        } else {
            readyForResetPassword = false
        }
    }
    
    
    func emailAndPasswordValidation(){
        if emailAddress.filter({$0 == "@"}).count == 1
        && emailAddress.contains(".")
        && emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).count > 7
        && emailAddress.last?.isLetter ?? false
        && emailAddress.first?.isLetter ?? false
        && password.trimmingCharacters(in: .whitespacesAndNewlines).count > 7 {
            readyForSignIn = true
        }
    }
    
    func signIn() async{
        if readyForSignIn{
            Auth.auth().signIn(withEmail: emailAddress, password: password){result, error in
                if (error != nil){
                    print(String(error!.localizedDescription))
                    self.errorMessage = String(error!.localizedDescription)
                    self.showingError = true
                }
            }
        }
    }
    
    // Generating randomNonceString
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
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
    
    // Generating Random Nonce and Hashed Nonce
    func generateNonce(){
        nonce = self.randomNonceString()
        hashedNonce = self.sha256(nonce!)
    }
    
    
    func loginWithFirebase(_ authorization : ASAuthorization){
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
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if (error != nil) {
                    // Error. If error.code == .MissingOrInvalidNonce, make sure
                    // you're sending the SHA256-hashed nonce as a hex string with
                    // your request to Apple.
                    print(error!.localizedDescription)
                    return
                }
                // User is signed in to Firebase with Apple.
                // ...
            }
            
        }
    }
    
    private func checkSignupMethod(email: String) async throws -> String? {
        let db = Firestore.firestore()
        let querySnapshot = try await db.collection("users")
            .whereField("email", isEqualTo: email)
            .getDocuments()

        if let document = querySnapshot.documents.first {
            let data = document.data()
            return data["signupMethod"] as? String
        }
        return nil
    }

    func resetPassword() async {
        await MainActor.run {
            isResetLoading = true
            showingResetSuccess = false
            showingResetError = false
            shouldShowAppleSignInOptions = false
        }

        do {
            let signupMethod = try await checkSignupMethod(email: forgotPasswordEmail)

            if signupMethod == nil {
                await MainActor.run {
                    isResetLoading = false
                    resetErrorMessage = "Email not found. Please sign up to create an account."
                    shouldShowSignUpOption = true
                    showingResetError = true
                }
                return
            }

            if signupMethod == "apple_signin" {
                await MainActor.run {
                    isResetLoading = false
                    resetErrorMessage = "This email is registered with Apple Sign-In. Please use the Apple Sign-In button to log in."
                    shouldShowAppleSignInOptions = true
                    showingResetError = true
                }
                return
            }

            if signupMethod == "email_password" {
                let auth = Auth.auth()
                try await auth.sendPasswordReset(withEmail: forgotPasswordEmail)

                await MainActor.run {
                    isResetLoading = false
                    resetSuccessMessage = "Password reset email sent to \(forgotPasswordEmail). Please check your inbox and follow the instructions to reset your password."
                    showingResetSuccess = true
                }
            } else {
                await MainActor.run {
                    isResetLoading = false
                    resetErrorMessage = "This email is registered with a different sign-in method. Please use the same method you used to sign up."
                    showingResetError = true
                }
            }
        } catch {
            await MainActor.run {
                isResetLoading = false

                if let authError = error as NSError? {
                    switch AuthErrorCode(rawValue: authError.code) {
                    case .invalidEmail:
                        resetErrorMessage = "Please enter a valid email address."
                    case .networkError:
                        resetErrorMessage = "Network error. Please check your internet connection and try again."
                    case .tooManyRequests:
                        resetErrorMessage = "Too many requests. Please wait a moment before trying again."
                    default:
                        resetErrorMessage = "An error occurred: \(error.localizedDescription)"
                    }
                } else {
                    resetErrorMessage = "An unexpected error occurred. Please try again."
                }

                showingResetError = true
            }
        }
    }
}



// The functionality of resetting is perfect.
// UI Changes - Clear the sign up view textfields after the sign up is successfull, check for login View as well.
