//
//  UserServiceProtocol.swift
//  ShelfSmart
//
//  Created by Architecture Refactoring on 1/19/26.
//

import Foundation

/// Protocol defining user data operations
/// This abstraction allows for easy testing and swapping of data sources
protocol UserServiceProtocol {
    /// Fetch user data from the database
    /// - Parameter userId: The user's unique identifier
    /// - Returns: User object if found
    func fetchUser(userId: String) async throws -> User
    
    /// Create a new user document
    /// - Parameters:
    ///   - userId: The user's unique identifier
    ///   - user: The user data to store
    func createUser(userId: String, user: User) async throws
    
    /// Update user data
    /// - Parameters:
    ///   - userId: The user's unique identifier
    ///   - fields: Dictionary of fields to update
    func updateUser(userId: String, fields: [String: Any]) async throws
    
    /// Delete a user document
    /// - Parameter userId: The user's unique identifier
    func deleteUser(userId: String) async throws
    
    /// Fetch user's allergies
    /// - Parameter userId: The user's unique identifier
    /// - Returns: Array of allergy strings
    func fetchAllergies(userId: String) async throws -> [String]
    
    /// Update user's allergies
    /// - Parameters:
    ///   - userId: The user's unique identifier
    ///   - allergies: Array of allergy strings to save
    func updateAllergies(userId: String, allergies: [String]) async throws
    
    /// Check if a user has completed onboarding
    /// - Parameter userId: The user's unique identifier
    /// - Returns: True if onboarding is complete, false otherwise, nil if unknown
    func hasCompletedOnboarding(userId: String) async throws -> Bool?
    
    /// Mark onboarding as completed for a user
    /// - Parameter userId: The user's unique identifier
    func completeOnboarding(userId: String) async throws
    
    /// Check if user exists by hashed email (for auth method lookup)
    /// - Parameter email: The user's email (will be hashed internally)
    /// - Returns: Tuple of (exists, signupMethod)
    func checkUserExists(email: String) async throws -> (exists: Bool, signupMethod: String?)
    
    /// Store auth method for email lookup
    /// - Parameters:
    ///   - email: The user's email
    ///   - method: The signup method (e.g., "email_password", "apple_signin")
    func storeAuthMethod(email: String, method: String) async throws
    
    /// Delete auth method entry for email
    /// - Parameter email: The user's email
    func deleteAuthMethod(email: String) async throws
}
