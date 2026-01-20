//
//  AuthServiceProtocol.swift
//  ShelfSmart
//
//  Created by Architecture Refactoring on 1/19/26.
//

import Foundation
import FirebaseAuth

/// Protocol defining authentication operations
/// This abstraction allows for easy testing and swapping of auth implementations
protocol AuthServiceProtocol {
    /// Current authenticated user ID, nil if not logged in
    var currentUserId: String? { get }
    
    /// Current authenticated user email, nil if not logged in
    var currentUserEmail: String? { get }
    
    /// Whether the current user's email is verified
    var isEmailVerified: Bool { get }
    
    /// Whether a user is currently logged in
    var isLoggedIn: Bool { get }
    
    /// Add a listener for authentication state changes
    /// - Parameter handler: Closure called with (userId, email, isLoggedIn, isEmailVerified)
    /// - Returns: A handle that can be used to remove the listener
    func addAuthStateListener(_ handler: @escaping (String?, String?, Bool, Bool) -> Void) -> AuthStateDidChangeListenerHandle
    
    /// Remove an authentication state listener
    /// - Parameter handle: The handle returned from addAuthStateListener
    func removeAuthStateListener(_ handle: AuthStateDidChangeListenerHandle)
    
    /// Sign in with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: The authenticated user's ID
    func signIn(email: String, password: String) async throws -> String
    
    /// Create a new account with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: The new user's ID
    func createAccount(email: String, password: String) async throws -> String
    
    /// Sign in with Apple credential
    /// - Parameters:
    ///   - idToken: The ID token from Apple
    ///   - nonce: The raw nonce used for the request
    ///   - fullName: Optional full name from Apple
    /// - Returns: Tuple containing (userId, email, isNewUser)
    func signInWithApple(idToken: String, nonce: String, fullName: PersonNameComponents?) async throws -> (userId: String, email: String?, isNewUser: Bool)
    
    /// Sign out the current user
    func signOut() throws
    
    /// Re-authenticate user with email/password (required before sensitive operations)
    func reauthenticate(email: String, password: String) async throws
    
    /// Re-authenticate user with Apple credential
    func reauthenticateWithApple(idToken: String, nonce: String) async throws
    
    /// Delete the current user's account
    func deleteAccount() async throws
    
    /// Reload the current user to get fresh data
    func reloadCurrentUser() async throws
    
    /// Send email verification to current user
    func sendEmailVerification() async throws
    
    /// Send password reset email
    func sendPasswordReset(email: String) async throws
}
