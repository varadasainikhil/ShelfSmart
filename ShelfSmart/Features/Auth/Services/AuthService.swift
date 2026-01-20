//
//  AuthService.swift
//  ShelfSmart
//
//  Created by Architecture Refactoring on 1/19/26.
//

import Foundation
import FirebaseAuth

/// Error types for authentication operations
enum AuthServiceError: LocalizedError {
    case notAuthenticated
    case emailNotVerified
    case invalidCredential
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case requiresRecentLogin
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "No user is currently signed in"
        case .emailNotVerified:
            return "Please verify your email address"
        case .invalidCredential:
            return "Invalid email or password"
        case .userNotFound:
            return "No account found with this email"
        case .emailAlreadyInUse:
            return "An account already exists with this email"
        case .weakPassword:
            return "Password is too weak. Please use at least 6 characters"
        case .requiresRecentLogin:
            return "Please sign in again to complete this action"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

/// Firebase Authentication service implementation
final class AuthService: AuthServiceProtocol {
    
    /// Shared singleton instance
    static let shared = AuthService()
    
    private init() {}
    
    // MARK: - Properties
    
    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    var currentUserEmail: String? {
        return Auth.auth().currentUser?.email
    }
    
    var isEmailVerified: Bool {
        return Auth.auth().currentUser?.isEmailVerified ?? false
    }
    
    var isLoggedIn: Bool {
        return Auth.auth().currentUser != nil
    }
    
    // MARK: - Auth State Listener
    
    func addAuthStateListener(_ handler: @escaping (String?, String?, Bool, Bool) -> Void) -> AuthStateDidChangeListenerHandle {
        return Auth.auth().addStateDidChangeListener { _, user in
            handler(
                user?.uid,
                user?.email,
                user != nil,
                user?.isEmailVerified ?? false
            )
        }
    }
    
    func removeAuthStateListener(_ handle: AuthStateDidChangeListenerHandle) {
        Auth.auth().removeStateDidChangeListener(handle)
    }
    
    // MARK: - Email/Password Authentication
    
    func signIn(email: String, password: String) async throws -> String {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            print("✅ User signed in successfully: \(result.user.uid)")
            return result.user.uid
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    func createAccount(email: String, password: String) async throws -> String {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            print("✅ User account created: \(result.user.uid)")
            return result.user.uid
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Apple Sign In
    
    func signInWithApple(idToken: String, nonce: String, fullName: PersonNameComponents?) async throws -> (userId: String, email: String?, isNewUser: Bool) {
        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: fullName
        )
        
        do {
            let result = try await Auth.auth().signIn(with: credential)
            let isNewUser = result.additionalUserInfo?.isNewUser ?? false
            print("✅ User signed in with Apple: \(result.user.uid), isNewUser: \(isNewUser)")
            return (result.user.uid, result.user.email, isNewUser)
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            print("✅ User signed out successfully")
        } catch {
            print("❌ Error signing out: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Re-authentication
    
    func reauthenticate(email: String, password: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthServiceError.notAuthenticated
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        
        do {
            try await user.reauthenticate(with: credential)
            print("✅ User re-authenticated successfully")
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    func reauthenticateWithApple(idToken: String, nonce: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthServiceError.notAuthenticated
        }
        
        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: nil
        )
        
        do {
            try await user.reauthenticate(with: credential)
            print("✅ User re-authenticated with Apple successfully")
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Account Management
    
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthServiceError.notAuthenticated
        }
        
        do {
            try await user.delete()
            print("✅ User account deleted successfully")
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    func reloadCurrentUser() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthServiceError.notAuthenticated
        }
        
        try await user.reload()
        print("✅ User data reloaded")
    }
    
    func sendEmailVerification() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthServiceError.notAuthenticated
        }
        
        try await user.sendEmailVerification()
        print("✅ Email verification sent")
    }
    
    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
        print("✅ Password reset email sent")
    }
    
    // MARK: - Error Mapping
    
    private func mapFirebaseError(_ error: NSError) -> AuthServiceError {
        guard error.domain == AuthErrorDomain else {
            return .unknown(error)
        }
        
        switch AuthErrorCode(rawValue: error.code) {
        case .invalidCredential, .wrongPassword, .invalidEmail:
            return .invalidCredential
        case .userNotFound:
            return .userNotFound
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .weakPassword:
            return .weakPassword
        case .requiresRecentLogin:
            return .requiresRecentLogin
        default:
            return .unknown(error)
        }
    }
}
