//
//  ProfileViewViewModel.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/5/25.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftData

@Observable
class ProfileViewViewModel{
    
    var userName : String = "Unknown User"
    
     func getUserName() async{
            guard let userId = Auth.auth().currentUser?.uid else{
                print("Could not get userId")
                return
            }
    
            let db = Firestore.firestore()
            do{
                let user = try await db.collection("users").document(userId).getDocument(as: User.self)
                userName = user.name
            }
            catch{
                print(error.localizedDescription)
            }
    
    
        }
    
    
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
