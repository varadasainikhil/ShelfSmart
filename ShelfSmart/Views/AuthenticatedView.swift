//
//  ContentView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/21/25.
//

import SwiftUI

struct AuthenticatedView: View {
    @State var authManager : SignUpViewViewModel
    var body: some View {
        
        TabView{
            Tab("Home", systemImage: "house.fill") {
                HomeView()
            }
            Tab("Random Recipe", systemImage: "shuffle") {
                MealTypesView()
            }
            Tab("Profile", systemImage: "person.fill") {
                ProfileViewFixed()
            }
        }
    }
}

#Preview {
    AuthenticatedView(authManager: SignUpViewViewModel())
}
