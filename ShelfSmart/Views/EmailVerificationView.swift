//
//  EmailVerificationView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 9/23/25.
//

import SwiftUI

struct EmailVerificationView: View {
    @State var viewModel: EmailVerificationViewModel
    let onVerificationSuccess: (() async -> Void)?

    init(viewModel: EmailVerificationViewModel, onVerificationSuccess: (() async -> Void)? = nil) {
        self.viewModel = viewModel
        self.onVerificationSuccess = onVerificationSuccess
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header Section
                    VStack(spacing: 16) {
                        // Email verification icon
                        Circle()
                            .fill(.blue.opacity(0.1))
                            .frame(width: 80, height: 80)
                            .overlay {
                                Image(systemName: "envelope.badge.shield.half.filled")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundStyle(.blue)
                            }

                        VStack(spacing: 8) {
                            Text("Verify Your Email")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)

                            Text("We've sent a verification link to")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(viewModel.userEmail)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.blue.opacity(0.1))
                                )
                        }
                        .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)

                    // Instructions Card
                    VStack(spacing: 20) {
                        // Instructions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Next Steps:")
                                .font(.headline)
                                .fontWeight(.semibold)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 12) {
                                    Text("1.")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.blue)
                                    Text("Check your email inbox (and spam folder)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                HStack(alignment: .top, spacing: 12) {
                                    Text("2.")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.blue)
                                    Text("Click the verification link in the email")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                HStack(alignment: .top, spacing: 12) {
                                    Text("3.")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.blue)
                                    Text("Return to this app and tap 'I've Verified'")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        // Action Buttons
                        VStack(spacing: 12) {
                            // Check Verification Button
                            CompactButton(
                                title: "I've Verified My Email",
                                isLoading: viewModel.isCheckingVerification,
                                isEnabled: !viewModel.isCheckingVerification,
                                action: {
                                    Task {
                                        await viewModel.checkEmailVerification(onSuccess: onVerificationSuccess)
                                    }
                                }
                            )

                            // Resend Email Button
                            Button(action: {
                                Task {
                                    await viewModel.resendVerificationEmail()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    if viewModel.isResendingEmail {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                            .tint(.blue)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 14, weight: .medium))
                                    }

                                    if viewModel.resendCooldownSeconds > 0 {
                                        Text("Resend in \(viewModel.resendCooldownSeconds)s")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    } else {
                                        Text(viewModel.isResendingEmail ? "Sending..." : "Resend Email")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                }
                                .foregroundStyle(viewModel.canResendEmail ? .blue : .gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(viewModel.canResendEmail ? .blue.opacity(0.1) : Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(viewModel.canResendEmail ? .blue.opacity(0.3) : .clear, lineWidth: 1)
                                        )
                                )
                            }
                            .disabled(!viewModel.canResendEmail)
                            .buttonStyle(PlainButtonStyle())
                        }

                        // Sign Out Option
                        HStack(spacing: 4) {
                            Text("Wrong email?")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Button("Sign Out") {
                                Task {
                                    await viewModel.signOut()
                                }
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
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
            .alert("Success", isPresented: $viewModel.showingSuccess) {
                Button("OK") { }
            } message: {
                Text(viewModel.successMessage)
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onAppear {
                viewModel.startCooldownTimer()
            }
            .onDisappear {
                viewModel.stopCooldownTimer()
            }
        }
    }
}

#Preview {
    EmailVerificationView(viewModel: EmailVerificationViewModel(userEmail: "test@example.com"))
}