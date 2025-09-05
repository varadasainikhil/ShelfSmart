//
//  LoginViewViewModel.swift
//  FreshAlert
//
//  Created by Sai Nikhil Varada on 8/21/25.
//

import Foundation
import FirebaseAuth
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
}
