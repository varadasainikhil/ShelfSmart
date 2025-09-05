//
//  AuthenticationManager.swift
//  FreshAlert
//
//  Created by Sai Nikhil Varada on 8/21/25.
//

import Foundation
import FirebaseAuth
import CryptoKit
import AuthenticationServices

@Observable
final class SignUpViewViewModel{
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
    
    // Creating an account
    func createAccount() async{
        print("Sign Up button is pressed.")
        if isEmailValidated && passwordsMatching && passwordLengthOk{
            Auth.auth().createUser(withEmail: emailAddress, password: password){ result, error in
                print(error?.localizedDescription ?? "User signed in succesfully")
            }
        }
    }
    
    // Signing Out
    func signOut(){
        do{
            try Auth.auth().signOut()
            print("User signed out successfully.")
        }
        catch{
            print(error.localizedDescription)
        }
        
    }
    
}
