//
//  ForgotPasswordView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/23/25.
//

import SwiftUI

struct ForgotPasswordView: View {
    @State var viewModel: LoginViewViewModel
    @Environment(\.dismiss) private var dismiss
    var onNavigateToSignUp: (() -> Void)?

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
                            Text("Reset")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            Text("Password")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }

                        Text("Enter your email to receive a password reset link")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                    Spacer()

                    // Reset Password Form Card
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Reset Password")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text("We'll send you a reset link")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Circle()
                                .fill(.orange.opacity(0.2))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    Image(systemName: "lock.rotation")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.orange)
                                }
                        }

                        // Email Field
                        CompactTextField(
                            title: "Email",
                            placeholder: "Enter your email address",
                            text: $viewModel.forgotPasswordEmail,
                            keyboardType: .emailAddress
                        )

                        // Send Reset Link Button
                        CompactButton(
                            title: "Send Reset Link",
                            isLoading: viewModel.isResetLoading,
                            isEnabled: viewModel.readyForResetPassword,
                            action: {
                                Task {
                                    await viewModel.resetPassword()
                                }
                            }
                        )

                        // Cancel Button
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .alert("Success", isPresented: $viewModel.showingResetSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(viewModel.resetSuccessMessage)
            }
            .alert("Error", isPresented: $viewModel.showingResetError) {
                if viewModel.shouldShowSignUpOption {
                    Button("Sign Up") {
                        dismiss()
                        onNavigateToSignUp?()
                    }
                    Button("Try Again") { }
                } else if viewModel.shouldShowAppleSignInOptions {
                    Button("Go to Login") {
                        dismiss()
                    }
                    Button("Try Different Email") {
                        viewModel.forgotPasswordEmail = ""
                    }
                } else {
                    Button("Try Again") { }
                }
            } message: {
                Text(viewModel.resetErrorMessage)
            }
        }
    }
}

#Preview {
    ForgotPasswordView(viewModel: LoginViewViewModel(), onNavigateToSignUp: nil)
}
