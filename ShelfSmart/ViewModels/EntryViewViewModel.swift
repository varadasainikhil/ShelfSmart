//
//  EntryViewViewModel.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/21/25.
//

import Foundation
import FirebaseAuth

@Observable
class EntryViewViewModel{
    var isLoggedIn : Bool = false
    var isEmailVerified : Bool = false
    var currentUserId : String = ""
    var currentUserEmail : String = ""

    private var handler : AuthStateDidChangeListenerHandle? = nil

    init() {
        self.handler = Auth.auth().addStateDidChangeListener({ auth, user in
            self.currentUserId = user?.uid ?? ""
            self.currentUserEmail = user?.email ?? ""
            self.isLoggedIn = user != nil

            // Check email verification status
            if let user = user {
                self.isEmailVerified = user.isEmailVerified
            } else {
                self.isEmailVerified = false
            }
        })
    }
    
    func stopHandler(){
        if let handler = handler {
            Auth.auth().removeStateDidChangeListener(handler)
            self.handler = nil
        }
    }

    func refreshUserStatus() async {
        guard let currentUser = Auth.auth().currentUser else { return }

        do {
            // Reload user to get latest verification status
            try await currentUser.reload()

            await MainActor.run {
                self.isEmailVerified = currentUser.isEmailVerified
            }
        } catch {
            print("Error refreshing user status: \(error.localizedDescription)")
        }
    }
    
    deinit {    
        // Ensure cleanup happens even if stopHandler() isn't called
        stopHandler()
    }

}
