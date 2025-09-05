//
//  LoginView.swift
//  FreshAlert
//
//  Created by Sai Nikhil Varada on 8/21/25.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @State var viewModel = LoginViewViewModel()
    var body: some View {
        NavigationStack{
            VStack{
                Spacer()
                
                CustomTextField(textToShow: "Enter your email", variableToBind: $viewModel.emailAddress)
                
                CustomSecureField(textToShow: "Enter your password", variableToBind: $viewModel.password)
                
                Button{
                    // Sign up
                    Task{
                        await viewModel.signIn()
                    }
                } label: {
                    ZStack{
                        RoundedRectangle(cornerRadius: 12)
                            .foregroundStyle(.green)
                            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
                            
                        Text("Sign In")
                            .foregroundStyle(.white)
                    }
                    
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .shadow(radius: 5)
                    .opacity(viewModel.readyForSignIn ? 1.0 : 0.6)
                }
                .disabled(!viewModel.readyForSignIn)
                .padding(.top, 30)
                
                
                ZStack{
                    Divider()
                    Text("or")
                        .frame(width: 30)
                        .background(.white)
                        .foregroundStyle(.gray)
                        .font(.footnote)
                }
                .padding(.vertical, 20)
                
            
                
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.email, .fullName]
                    viewModel.generateNonce()
                    request.nonce = viewModel.hashedNonce
                } onCompletion: { result in
                    switch result{
                    case .success(let authorization):
                        viewModel.loginWithFirebase(authorization)
                    case .failure(_):
                        break
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
            
                Spacer()
                
            }
            .padding()
            .navigationTitle("Welcome Back")
            .alert("Error", isPresented: $viewModel.showingError) {
                // Nothing to do
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

#Preview {
    LoginView()
}
