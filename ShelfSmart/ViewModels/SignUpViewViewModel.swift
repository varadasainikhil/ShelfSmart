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
                
                // Check if user document already exists
                let db = Firestore.firestore()
            
                do{
                    let user = User(name: userName, email: userEmail)
                    
                    try db.collection("users").document(userId).setData(from: user)
                    print("User with user id: \(userId) updated to Firebase")
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
    
    // Creating an account
    func createAccount() async{
        print("Sign Up button is pressed.")
        if isEmailValidated && passwordsMatching && passwordLengthOk{
            do {
                // Create user with Firebase Auth using async/await
                let authResult = try await Auth.auth().createUser(withEmail: emailAddress, password: password)
                print("User signed in successfully with ID: \(authResult.user.uid)")
                
                // Get the user ID from the auth result
                let userId = authResult.user.uid
                
                // Create a new user document in Firestore
                let db = Firestore.firestore()
                let user = User(name: fullName, email: emailAddress)
                
                try db.collection("users").document(userId).setData(from: user)
                print("User with user id: \(userId) updated to Firebase")
                
            } catch {
                print("Error creating account: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
}
