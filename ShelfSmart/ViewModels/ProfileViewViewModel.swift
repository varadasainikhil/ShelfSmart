//
//  ProfileViewViewModel.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/5/25.
//

import FirebaseAuth
import Foundation
import SwiftData

@Observable
class ProfileViewViewModel{
    
    func deleteGroups(groups : [GroupedProducts], modelContext : ModelContext){
        for group in groups{
            modelContext.delete(group)
        }
        do{
            try modelContext.save()
        }
        catch{
            print("Problem saving the modelContext")
        }
    }
    
    // Signing Out
    func signOut(){
        do{
            try Auth.auth().signOut()
            print("User signed out successfully.")
        }
        catch{
            print(error.localizedDescription)
        }
    }
}
