//
//  EntryView.swift
//  FreshAlert
//
//  Created by Sai Nikhil Varada on 8/21/25.
//

import SwiftUI

struct EntryView: View {
    @State var viewModel = EntryViewViewModel()
    @State var authManager = SignUpViewViewModel()
    var body: some View {
        VStack{
            if viewModel.isLoggedIn && !viewModel.currentUserId.isEmpty{
                // User is autheticated
                AuthenticatedView(authManager: authManager)
            } else {
                SignUpView(viewModel: authManager)
            }
        }
        .onDisappear {
            viewModel.stopHandler()
        }
    }
}

#Preview {
    EntryView()
}
