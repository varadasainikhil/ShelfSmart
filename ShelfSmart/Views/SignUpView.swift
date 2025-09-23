//
//  SignUpView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/21/25.
//

import AuthenticationServices
import SwiftUI

struct SignUpView: View {
    @State var viewModel: SignUpViewViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Section
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text("Create")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            Text("Account")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                        
                        Text("Join ShelfSmart to start managing your products")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    
                    // Sign Up Form Card
                    VStack(spacing: 16) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sign Up")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text("Enter your information")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Circle()
                                .fill(.blue.opacity(0.2))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.blue)
                                }
                        }
                        
                        // Form Fields
                        VStack(spacing: 10) {
                            CompactTextField(
                                title: "Full Name",
                                placeholder: "Enter your full name",
                                text: $viewModel.fullName,
                                keyboardType: .default,
                                capitalization: .words
                            )
                            
                            CompactTextField(
                                title: "Email",
                                placeholder: "Enter your email",
                                text: $viewModel.emailAddress,
                                keyboardType: .emailAddress,
                                capitalization: .never
                            )
                            
                            CompactSecureField(
                                title: "Password",
                                placeholder: "Enter your password",
                                text: $viewModel.password
                            )
                            
                            CompactSecureField(
                                title: "Confirm Password",
                                placeholder: "Confirm your password",
                                text: $viewModel.confirmationPassword
                            )
                        }
                        
                        // Validation Status
                        CompactValidationStatus(
                            isEmailValidated: viewModel.isEmailValidated,
                            passwordLengthOk: viewModel.passwordLengthOk,
                            passwordsMatching: viewModel.passwordsMatching
                        )
                        
                        // Sign Up Button
                        CompactButton(
                            title: "Create Account",
                            isLoading: false,
                            isEnabled: viewModel.isButtonActive,
                            action: {
                                Task {
                                    await viewModel.createAccount()
                                }
                            }
                        )
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color(.systemGray4))
                                .frame(height: 1)
                            Text("or")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 12)
                            Rectangle()
                                .fill(Color(.systemGray4))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 8)
                        
                        // Apple Sign In
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.email, .fullName]
                            viewModel.generateNonce()
                            request.nonce = viewModel.hashedNonce
                        } onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                Task {
                                    await viewModel.loginWithFirebase(authorization)
                                }
                            case .failure(_):
                                break
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .signInWithAppleButtonStyle(.black)
                        
                        // Navigation to Login
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            NavigationLink("Sign In") {
                                LoginView()
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                        }
                        .padding(.top, 8)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Success", isPresented: $viewModel.showingSuccess) {
                Button("OK") { }
            } message: {
                Text(viewModel.successMessage)
            }
        }
    }
}

// MARK: - Compact Validation Status
struct CompactValidationStatus: View {
    let isEmailValidated: Bool
    let passwordLengthOk: Bool
    let passwordsMatching: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: isEmailValidated ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isEmailValidated ? .green : .secondary)
                    .font(.system(size: 14, weight: .medium))
                
                Text("Valid email")
                    .font(.caption2)
                    .foregroundStyle(isEmailValidated ? .green : .secondary)
                
                Spacer()
            }
            
            HStack(spacing: 8) {
                Image(systemName: passwordLengthOk ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(passwordLengthOk ? .green : .secondary)
                    .font(.system(size: 14, weight: .medium))
                
                Text("8+ characters")
                    .font(.caption2)
                    .foregroundStyle(passwordLengthOk ? .green : .secondary)
                
                Spacer()
            }
            
            HStack(spacing: 8) {
                Image(systemName: passwordsMatching ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(passwordsMatching ? .green : .secondary)
                    .font(.system(size: 14, weight: .medium))
                
                Text("Passwords match")
                    .font(.caption2)
                    .foregroundStyle(passwordsMatching ? .green : .secondary)
                
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    SignUpView(viewModel: SignUpViewViewModel())
}
