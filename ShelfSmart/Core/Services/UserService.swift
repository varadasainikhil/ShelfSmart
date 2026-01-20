//
//  UserService.swift
//  ShelfSmart
//
//  Created by Architecture Refactoring on 1/19/26.
//

import Foundation
import FirebaseFirestore

/// Error types for user data operations
enum UserServiceError: LocalizedError {
    case userNotFound
    case invalidData
    case permissionDenied
    case networkError
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User data not found"
        case .invalidData:
            return "Invalid user data"
        case .permissionDenied:
            return "Permission denied"
        case .networkError:
            return "Network error. Please check your connection"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

/// Firestore user data service implementation
final class UserService: UserServiceProtocol {
    
    /// Shared singleton instance
    static let shared = UserService()
    
    private let db: Firestore
    private let usersCollection = "users"
    private let authUsersCollection = "authUsers"
    
    private init() {
        self.db = Firestore.firestore()
    }
    
    /// Initialize with custom Firestore instance (for testing)
    init(firestore: Firestore) {
        self.db = firestore
    }
    
    // MARK: - User CRUD Operations
    
    func fetchUser(userId: String) async throws -> User {
        do {
            let document = try await db.collection(usersCollection).document(userId).getDocument()
            
            guard document.exists else {
                throw UserServiceError.userNotFound
            }
            
            let user = try document.data(as: User.self)
            print("✅ User data fetched for: \(userId)")
            return user
        } catch let error as DecodingError {
            print("❌ Failed to decode user: \(error)")
            throw UserServiceError.invalidData
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    func createUser(userId: String, user: User) async throws {
        do {
            try db.collection(usersCollection).document(userId).setData(from: user)
            print("✅ User document created for: \(userId)")
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    func updateUser(userId: String, fields: [String: Any]) async throws {
        do {
            try await db.collection(usersCollection).document(userId).updateData(fields)
            print("✅ User data updated for: \(userId)")
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    func deleteUser(userId: String) async throws {
        do {
            try await db.collection(usersCollection).document(userId).delete()
            print("✅ User document deleted for: \(userId)")
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    // MARK: - Allergies
    
    func fetchAllergies(userId: String) async throws -> [String] {
        do {
            let document = try await db.collection(usersCollection).document(userId).getDocument()
            
            guard document.exists,
                  let data = document.data(),
                  let allergies = data["allergies"] as? [String] else {
                return []
            }
            
            print("✅ Fetched \(allergies.count) allergies for user: \(userId)")
            return allergies
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    func updateAllergies(userId: String, allergies: [String]) async throws {
        try await updateUser(userId: userId, fields: ["allergies": allergies])
        print("✅ Updated allergies for user: \(userId)")
    }
    
    // MARK: - Onboarding
    
    func hasCompletedOnboarding(userId: String) async throws -> Bool? {
        do {
            let document = try await db.collection(usersCollection).document(userId).getDocument()
            
            guard document.exists, let data = document.data() else {
                return nil
            }
            
            let hasCompleted = data["hasCompletedOnboarding"] as? Bool
            print("✅ Onboarding status for \(userId): \(hasCompleted ?? false)")
            return hasCompleted
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    func completeOnboarding(userId: String) async throws {
        try await updateUser(userId: userId, fields: ["hasCompletedOnboarding": true])
        print("✅ Onboarding completed for user: \(userId)")
    }
    
    // MARK: - Auth Method Lookup
    
    func checkUserExists(email: String) async throws -> (exists: Bool, signupMethod: String?) {
        let hashedEmail = AuthHelpers.hashEmail(email)
        
        do {
            let document = try await db.collection(authUsersCollection).document(hashedEmail).getDocument()
            
            if document.exists, let data = document.data() {
                let signupMethod = data["signupMethod"] as? String
                return (true, signupMethod)
            } else {
                return (false, nil)
            }
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    func storeAuthMethod(email: String, method: String) async throws {
        let hashedEmail = AuthHelpers.hashEmail(email)
        
        do {
            try await db.collection(authUsersCollection).document(hashedEmail).setData([
                "signupMethod": method
            ], merge: true)
            print("✅ Auth method stored for email")
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    func deleteAuthMethod(email: String) async throws {
        let hashedEmail = AuthHelpers.hashEmail(email)
        
        do {
            try await db.collection(authUsersCollection).document(hashedEmail).delete()
            print("✅ Auth method deleted for email")
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    // MARK: - Error Mapping
    
    private func mapFirestoreError(_ error: Error) -> UserServiceError {
        let nsError = error as NSError
        
        if nsError.domain == "FIRFirestoreErrorDomain" {
            switch nsError.code {
            case 7: // PERMISSION_DENIED
                return .permissionDenied
            case 14: // UNAVAILABLE
                return .networkError
            default:
                return .unknown(error)
            }
        }
        
        return .unknown(error)
    }
}
