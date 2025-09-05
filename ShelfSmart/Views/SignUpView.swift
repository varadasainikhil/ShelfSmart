//
//  AuthenticationView.swift
//  FreshAlert
//
//  Created by Sai Nikhil Varada on 8/21/25.
//

import AuthenticationServices
import SwiftUI

struct SignUpView: View {
    @State var viewModel : SignUpViewViewModel
    var body: some View {
        NavigationStack{
            VStack{
                
                Spacer()
                
                CustomTextField(textToShow: "Enter your Email", variableToBind: $viewModel.emailAddress)
                
                CustomSecureField(textToShow: "Enter Your Password", variableToBind: $viewModel.password)
                
                CustomSecureField(textToShow: "Confirm Your Password", variableToBind: $viewModel.confirmationPassword)
                
                Spacer()
                
                Button{
                    // Sign up
                    Task{
                        await viewModel.createAccount()
                    }
                } label: {
                    ZStack{
                        RoundedRectangle(cornerRadius: 12)
                            .foregroundStyle(.green)
                            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
                    
                        Text("Sign Up")
                            .foregroundStyle(.white)
                    }
                    
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .shadow(radius: 5)
                    .opacity(viewModel.isButtonActive ? 1.0 : 0.6)
                }
                .disabled(!viewModel.isButtonActive)
                
                Spacer()
                
                VStack(alignment: .leading){
                    HStack{
                        Image(systemName: viewModel.isEmailValidated ? "checkmark.circle" :"circle")
                        Text("Valid Email")
                    }
                    
                    HStack{
                        Image(systemName: viewModel.passwordLengthOk ? "checkmark.circle" :"circle")
                        Text("Password atleast 8 characters long.")
                    }
                    
                    HStack{
                        Image(systemName: viewModel.passwordsMatching ? "checkmark.circle" :"circle")
                        Text("Passwords Match")
                    }
                }
                
                Spacer()
                
                ZStack{
                    Divider()
                    Text("or")
                        .frame(width: 30)
                        .background(.white)
                        .foregroundStyle(.gray)
                        .font(.footnote)
                }
                
                Spacer()
                
                SignInWithAppleButton(.signIn){ request in
                    request.requestedScopes = [.email, .fullName]
                    viewModel.generateNonce()
                    request.nonce = viewModel.hashedNonce
                } onCompletion: { result in
                    switch result {
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
                
                NavigationLink {
                    // Go to Login View
                    LoginView()
                } label: {
                    HStack{
                        Text("Already have an account?")
                        Text("Login")
                            .bold()
                    }
                }

                Spacer()
                                
            }
            .padding()
            .navigationTitle("Create Account")
        }
    }
}

#Preview {
    SignUpView(viewModel: SignUpViewViewModel())
}
