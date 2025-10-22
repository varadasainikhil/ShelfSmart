//
//  AllergiesOnboardingViewModel.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 10/13/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@Observable
class AllergiesOnboardingViewModel {
    var selectedIntolerances: Set<Intolerances> = []
    var isSaving: Bool = false
    var errorMessage: String?

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

    // Save allergies to Firebase and mark onboarding as complete
    @MainActor
    func saveAllergiesAndCompleteOnboarding(userId: String) async throws {
        isSaving = true
        errorMessage = nil

        do {
            let db = Firestore.firestore()

            // Convert selected intolerances to array of strings
            let allergiesArray = selectedIntolerances.map { $0.rawValue }

            // Update user document in Firebase
            try await db.collection("users").document(userId).updateData([
                "allergies": allergiesArray,
                "hasCompletedOnboarding": true
            ])

            print("✅ Successfully saved allergies and completed onboarding")
            print("📋 Allergies saved: \(allergiesArray)")

            isSaving = false

        } catch {
            print("❌ Failed to save allergies: \(error.localizedDescription)")
            errorMessage = "Failed to save your selections. Please try again."
            isSaving = false
            throw error
        }
    }
}
