//
//  PasswordAuthView.swift
//  ShelfSmart
//
//  Created by Claude on 10/27/25.
//

import SwiftUI

struct PasswordAuthView: View {
    let email: String
    let isSignUpMode: Bool

    @State private var viewModel: PasswordAuthViewModel
    @State private var showForgotPasswordSheet = false

    init(email: String, isSignUpMode: Bool) {
        self.email = email
        self.isSignUpMode = isSignUpMode
        self._viewModel = State(initialValue: PasswordAuthViewModel(email: email, isSignUpMode: isSignUpMode))
    }

    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Header Section
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text(isSignUpMode ? "Create" : "Welcome")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        Text(isSignUpMode ? "Account" : "Back")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    }

                    Text(isSignUpMode ? "Set up your password to continue" : "Sign in to continue managing your shelf")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                Spacer()

                // Password Form Card
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isSignUpMode ? "Create Password" : "Enter Password")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text(email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Circle()
                            .fill((isSignUpMode ? Color.orange : Color.green).opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay {
                                Image(systemName: isSignUpMode ? "lock.fill" : "key.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(isSignUpMode ? .orange : .green)
                            }
                    }

                    // Name Field (only for sign-up)
                    if isSignUpMode {
                        CompactTextField(
                            title: "Full Name",
                            placeholder: "Enter your full name",
                            text: $viewModel.userName,
                            keyboardType: .default,
                            capitalization: .words
                        )
                    }

                    // Password Fields
                    VStack(spacing: 12) {
                        CompactSecureField(
                            title: "Password",
                            placeholder: "Enter your password",
                            text: $viewModel.password
                        )

                        // Forgot Password link (only for sign-in mode)
                        if !isSignUpMode {
                            HStack {
                                Spacer()
                                Text("Forgot your password?")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .underline()
                                    .onTapGesture {
                                        showForgotPasswordSheet = true
                                    }
                            }
                            .padding(.top, 4)
                        }

                        if isSignUpMode {
                            CompactSecureField(
                                title: "Confirm Password",
                                placeholder: "Confirm your password",
                                text: $viewModel.confirmPassword
                            )
                        }
                    }

                    // Validation Status (only for sign-up)
                    if isSignUpMode {
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: viewModel.userNameValid ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(viewModel.userNameValid ? .green : .secondary)
                                    .font(.system(size: 14, weight: .medium))

                                Text("Valid name")
                                    .font(.caption2)
                                    .foregroundStyle(viewModel.userNameValid ? .green : .secondary)

                                Spacer()
                            }

                            HStack(spacing: 8) {
                                Image(systemName: viewModel.passwordLengthOk ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(viewModel.passwordLengthOk ? .green : .secondary)
                                    .font(.system(size: 14, weight: .medium))

                                Text("8+ characters")
                                    .font(.caption2)
                                    .foregroundStyle(viewModel.passwordLengthOk ? .green : .secondary)

                                Spacer()
                            }

                            HStack(spacing: 8) {
                                Image(systemName: viewModel.passwordsMatching ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(viewModel.passwordsMatching ? .green : .secondary)
                                    .font(.system(size: 14, weight: .medium))

                                Text("Passwords match")
                                    .font(.caption2)
                                    .foregroundStyle(viewModel.passwordsMatching ? .green : .secondary)

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

                    // Action Button
                    CompactButton(
                        title: isSignUpMode ? "Create Account" : "Sign In",
                        isLoading: viewModel.isLoading,
                        isEnabled: viewModel.isButtonActive,
                        action: {
                            Task {
                                if isSignUpMode {
                                    await viewModel.signUp()
                                } else {
                                    await viewModel.signIn()
                                }
                            }
                        }
                    )
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
        .alert("Success", isPresented: $viewModel.showingSuccess) {
            Button("OK") { }
        } message: {
            Text(viewModel.successMessage)
        }
        .sheet(isPresented: $showForgotPasswordSheet) {
            ForgotPasswordView(viewModel: viewModel)
        }
    }
}

#Preview("Sign In") {
    NavigationStack {
        PasswordAuthView(email: "user@example.com", isSignUpMode: false)
    }
}

#Preview("Sign Up") {
    NavigationStack {
        PasswordAuthView(email: "newuser@example.com", isSignUpMode: true)
    }
}
