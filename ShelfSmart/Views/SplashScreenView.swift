//
//  SplashScreenView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 10/27/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var opacity: Double = 0.0
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            // Background color that adapts to light/dark mode
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // App Icon
                Image("SplashLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 26.4)) // iOS app icon corner radius
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                // App Name
                Text("ShelfSmart")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .opacity(opacity)
        }
        .onAppear {
            // Fade in animation
            withAnimation(.easeIn(duration: 0.6)) {
                opacity = 1.0
            }

            // Dismiss after 1.8 seconds total (1.4s visible + 0.4s fade out)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                withAnimation(.easeOut(duration: 0.4)) {
                    opacity = 0.0
                }

                // Call completion handler after fade out
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onComplete()
                }
            }
        }
    }
}

#Preview {
    SplashScreenView(onComplete: {})
}
