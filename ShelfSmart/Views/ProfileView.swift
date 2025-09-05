//
//  ProfileView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/25/25.
//

import FirebaseAuth
import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(\.modelContext) var modelContext
    @State var viewModel = ProfileViewViewModel()
    @State private var currentUserId: String = Auth.auth().currentUser?.uid ?? ""
    
    // Get all groups and filter in the view - this will be reactive to changes
    @Query(sort: \GroupedProducts.expirationDate) private var allGroups: [GroupedProducts]
    
    // Computed property that filters groups by current user
    var groups: [GroupedProducts] {
        return allGroups.filter { group in
            group.userId == currentUserId
        }
    }
    
    var body: some View {
        VStack {
            Button {
                // Delete all the items in the modelContext with your userID
                viewModel.deleteGroups(groups: groups, modelContext: modelContext)
            } label: {
                ZStack{
                    RoundedRectangle(cornerRadius: 12)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
                    
                    Text("Delete all the items")
                        .foregroundStyle(.white)
                        .fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            
            
            Button{
                Task{
                    viewModel.signOut()
                }
            } label: {
                ZStack{
                    RoundedRectangle(cornerRadius: 12)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
                    
                    Text("Sign Out")
                        .foregroundStyle(.white)
                        .fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .padding()
        .onAppear {
            currentUserId = Auth.auth().currentUser?.uid ?? ""
        }
    }
}

#Preview {
    ProfileView(viewModel: ProfileViewViewModel())
}
