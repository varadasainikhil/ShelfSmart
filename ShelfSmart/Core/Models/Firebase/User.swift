//
//  User.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/5/25.
//  Refactored on 1/19/26 to add Identifiable conformance and SignupMethod enum.
//

import Foundation

/// Represents the method used to sign up for the app
enum SignupMethod: String, Codable, CaseIterable {
    case email = "email"
    case appleSignIn = "apple-signin"
    case googleSignIn = "google-signin"
    
    /// Display-friendly name
    var displayName: String {
        switch self {
        case .email: return "Email"
        case .appleSignIn: return "Apple Sign-In"
        case .googleSignIn: return "Google Sign-In"
        }
    }
}

struct User: Codable, Identifiable {
    /// Unique identifier for the user (matches Firebase Auth UID)
    var id: String
    
    var name: String
    var email: String
    var joinDate: Date = Date.now
    
    /// The method used to create this account
    var signupMethod: SignupMethod
    
    var isEmailVerified: Bool = false
    var emailVerificationSentAt: Date? = nil
    var allergies: [String] = []
    var hasCompletedOnboarding: Bool = false
    
    // MARK: - Custom Coding
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case joinDate
        case signupMethod
        case isEmailVerified
        case emailVerificationSentAt
        case allergies
        case hasCompletedOnboarding
    }
    
    // Custom initializer to handle legacy string-based signupMethod
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // id might not exist in legacy documents - use empty string as fallback
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        self.name = try container.decode(String.self, forKey: .name)
        self.email = try container.decode(String.self, forKey: .email)
        self.joinDate = try container.decodeIfPresent(Date.self, forKey: .joinDate) ?? Date.now
        
        // Handle legacy string format or new enum format
        if let methodString = try? container.decode(String.self, forKey: .signupMethod) {
            self.signupMethod = SignupMethod(rawValue: methodString) ?? .email
        } else {
            self.signupMethod = try container.decodeIfPresent(SignupMethod.self, forKey: .signupMethod) ?? .email
        }
        
        self.isEmailVerified = try container.decodeIfPresent(Bool.self, forKey: .isEmailVerified) ?? false
        self.emailVerificationSentAt = try container.decodeIfPresent(Date.self, forKey: .emailVerificationSentAt)
        self.allergies = try container.decodeIfPresent([String].self, forKey: .allergies) ?? []
        self.hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false
    }
    
    // Standard memberwise initializer
    init(id: String, name: String, email: String, joinDate: Date = Date.now, signupMethod: SignupMethod, isEmailVerified: Bool = false, emailVerificationSentAt: Date? = nil, allergies: [String] = [], hasCompletedOnboarding: Bool = false) {
        self.id = id
        self.name = name
        self.email = email
        self.joinDate = joinDate
        self.signupMethod = signupMethod
        self.isEmailVerified = isEmailVerified
        self.emailVerificationSentAt = emailVerificationSentAt
        self.allergies = allergies
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}

extension User {
    static var mockData: User {
        User(
            id: "mock-user-id-123",
            name: "Mock User",
            email: "mockuser@gmail.com",
            signupMethod: .appleSignIn,
            isEmailVerified: true,
            allergies: [],
            hasCompletedOnboarding: true
        )
    }
}
