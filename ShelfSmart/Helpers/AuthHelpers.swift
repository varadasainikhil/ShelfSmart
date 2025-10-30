//
//  AuthHelpers.swift
//  ShelfSmart
//
//  Created by Claude on 10/28/25.
//

import Foundation
import CryptoKit

/// Shared authentication helper functions
struct AuthHelpers {
    /// Hashes an email address using SHA256
    /// - Parameter email: The email address to hash
    /// - Returns: A hexadecimal string representation of the SHA256 hash
    static func hashEmail(_ email: String) -> String {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let inputData = Data(normalized.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
