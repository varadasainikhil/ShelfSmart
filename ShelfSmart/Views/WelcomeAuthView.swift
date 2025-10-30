//
//  WelcomeAuthView.swift
//  ShelfSmart
//
//  Created by Claude on 10/27/25.
//

import SwiftUI
import AuthenticationServices

struct WelcomeAuthView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var viewModel = WelcomeAuthViewModel()
    @State private var currentPhraseIndex = 0

    let phrases = [
        "waste food",
        "forget expiry dates",
        "run out of recipe ideas"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header - App Logo and Name
                    HStack(spacing: 12) {
                        Image("SplashLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                        Text("ShelfSmart")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.primary)

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    Spacer()

                    // Top Section - Animated Tagline
                    VStack(spacing: 32) {
                        // Animated Tagline
                        VStack(spacing: 10) {
                            Text("Never")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(.primary)

                            VStack(spacing: 0) {
                                Text(phrases[currentPhraseIndex])
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundStyle(.green)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .id(currentPhraseIndex)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .move(edge: .top).combined(with: .opacity)
                                    ))
                            }
                            .frame(height: 44)
                            .clipped()

                            Text("again")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .onAppear {
                            // Start animation timer
                            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    currentPhraseIndex = (currentPhraseIndex + 1) % phrases.count
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 40)

                    Spacer()

                    // Bottom Card - Authentication
                    VStack(spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Get Started")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("Enter your email to continue")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Email Field
                        CompactTextField(
                            title: "Email",
                            placeholder: "Enter your email",
                            text: $viewModel.emailAddress,
                            keyboardType: .emailAddress,
                            capitalization: .never
                        )

                        // Next Button
                        CompactButton(
                            title: "Next",
                            isLoading: viewModel.isCheckingUser,
                            isEnabled: viewModel.isEmailValid,
                            action: {
                                Task {
                                    await viewModel.checkUserAndProceed()
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
                                    await viewModel.handleAppleSignIn(authorization)
                                }
                            case .failure:
                                break
                            }
                        }
                        .frame(maxWidth: 375)
                        .frame(height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                        .id(colorScheme)
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
                    .padding(.bottom, 40)
                }
            }
            .navigationDestination(isPresented: $viewModel.shouldNavigateToPassword) {
                PasswordAuthView(
                    email: viewModel.emailAddress,
                    isSignUpMode: viewModel.isSignUpMode
                )
                .onDisappear {
                    // Reset navigation state when user navigates back
                    viewModel.shouldNavigateToPassword = false
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

// MARK: - Feature Highlight Component
struct FeatureHighlight: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    WelcomeAuthView()
}
