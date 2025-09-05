//
//  EntryViewViewModel.swift
//  FreshAlert
//
//  Created by Sai Nikhil Varada on 8/21/25.
//

import Foundation
import FirebaseAuth

@Observable
class EntryViewViewModel{
    var isLoggedIn : Bool = false
    var currentUserId : String = ""
    
    private var handler : AuthStateDidChangeListenerHandle? = nil
    
    init() {
        self.handler = Auth.auth().addStateDidChangeListener({ auth, user in
            self.currentUserId = user?.uid ?? ""
            self.isLoggedIn = user != nil
        })
    }
    
    func stopHandler(){
        if let handler = handler {
            Auth.auth().removeStateDidChangeListener(handler)
            self.handler = nil
        }
    }
    
    deinit {
        // Ensure cleanup happens even if stopHandler() isn't called
        stopHandler()
    }

}
