//
//  EditAllergiesViewModel.swift
//  ShelfSmart
//
//  Created by Claude Code
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@Observable
class EditAllergiesViewModel {
    var selectedIntolerances: Set<Intolerances> = []
    var isLoading: Bool = false
    var isSaving: Bool = false
    var errorMessage: String?

    // Fetch current allergies from Firebase
    @MainActor
    func fetchCurrentAllergies(userId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let db = Firestore.firestore()
            let user = try await db.collection("users").document(userId).getDocument(as: User.self)

            // Convert string array to Set<Intolerances>
            let allergiesSet: Set<Intolerances> = Set(user.allergies.compactMap { allergyString in
                Intolerances(rawValue: allergyString)
            })

            selectedIntolerances = allergiesSet
            print("✅ Successfully fetched allergies: \(user.allergies)")

            isLoading = false
        } catch {
            print("❌ Failed to fetch allergies: \(error.localizedDescription)")
            errorMessage = "Failed to load your allergies. Please try again."
            isLoading = false
        }
    }

    // Toggle selection for an intolerance
    func toggleIntolerance(_ intolerance: Intolerances) {
        if selectedIntolerances.contains(intolerance) {
            selectedIntolerances.remove(intolerance)
        } else {
            selectedIntolerances.insert(intolerance)
        }
    }

    // Check if an intolerance is selected
    func isSelected(_ intolerance: Intolerances) -> Bool {
        return selectedIntolerances.contains(intolerance)
    }

    // Save updated allergies to Firebase
    @MainActor
    func saveAllergies(userId: String) async throws {
        isSaving = true
        errorMessage = nil

        do {
            let db = Firestore.firestore()

            // Convert selected intolerances to array of strings
            let allergiesArray = selectedIntolerances.map { $0.rawValue }

            // Update user document in Firebase
            try await db.collection("users").document(userId).updateData([
                "allergies": allergiesArray
            ])

            print("✅ Successfully updated allergies")
            print("📋 Allergies saved: \(allergiesArray)")

            isSaving = false

        } catch {
            print("❌ Failed to save allergies: \(error.localizedDescription)")
            errorMessage = "Failed to save your changes. Please try again."
            isSaving = false
            throw error
        }
    }
}
