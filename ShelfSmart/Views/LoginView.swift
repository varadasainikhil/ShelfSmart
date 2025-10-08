//
//  LoginView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/21/25.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State var viewModel = LoginViewViewModel()
    @State var forgotPasswordSheet = false
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Header Section
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text("Welcome")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            Text("Back")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                        
                        Text("Sign in to continue managing your shelf")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    
                    Spacer()
                    
                    // Login Form Card
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sign In")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text("Enter your credentials")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Circle()
                                .fill(.green.opacity(0.2))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    Image(systemName: "person.circle")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.green)
                                }
                        }
                        
                        // Form Fields
                        VStack(spacing: 12) {
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
                            
                            HStack{
                                
                                Spacer()
                                
                                Text("Forgot your password?")
                                    .font(.subheadline)
                                    .underline()
                                    .onTapGesture {
                                        forgotPasswordSheet = true
                                    }
                            }
                        }
                        
                        // Sign In Button
                        CompactButton(
                            title: "Sign In",
                            isLoading: false,
                            isEnabled: viewModel.readyForSignIn,
                            action: {
                                Task {
                                    await viewModel.signIn()
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
                                viewModel.loginWithFirebase(authorization)
                            case .failure(_):
                                break
                            }
                        }
                        .frame(maxWidth: 375)
                        .frame(height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                        .id(colorScheme)
                        
                        // Navigation to Sign Up
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            NavigationLink("Sign Up") {
                                SignUpView(viewModel: SignUpViewViewModel())
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: 400)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.separator), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
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
            .sheet(isPresented: $forgotPasswordSheet) {
                ForgotPasswordView(viewModel: viewModel) {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Compact Text Field
struct CompactTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let capitalization: TextInputAutocapitalization
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .keyboardType(keyboardType)
                .textInputAutocapitalization(capitalization)
                .autocorrectionDisabled()
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
        }
    }
}

// MARK: - Compact Secure Field
struct CompactSecureField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            SecureField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
        }
    }
}

// MARK: - Compact Button
struct CompactButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(isLoading ? "Please wait..." : title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(Color(.systemBackground))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled ? .green : Color(.systemGray4))
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
                    .shadow(color: isEnabled ? .green.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
            )
        }
        .disabled(!isEnabled || isLoading)
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isEnabled ? 1.0 : 0.98)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isEnabled)
    }
}

#Preview {
    LoginView()
}
