//
//  RobustAsyncImage.swift
//  ShelfSmart
//
//  Created by Claude Code on 10/7/25.
//

import SwiftUI

/// A robust async image loader with automatic retry logic and better error handling
/// Replaces SimpleAsyncImage to fix automatic "Image unavailable" issues
struct RobustAsyncImage<Content: View>: View {
    let urlString: String?
    let content: (Image) -> Content
    let maxRetries: Int = 3

    @State private var loadedImage: UIImage?
    @State private var isLoading: Bool = false
    @State private var retryCount: Int = 0
    @State private var hasFailed: Bool = false

    init(url: String?, @ViewBuilder content: @escaping (Image) -> Content) {
        self.urlString = url
        self.content = content
    }

    var body: some View {
        Group {
            if let uiImage = loadedImage {
                // Success state - show loaded image
                content(Image(uiImage: uiImage))
            } else if isLoading || (hasFailed && retryCount < maxRetries) {
                // Loading state (includes active retry attempts)
                Rectangle()
                    .fill(.gray.opacity(0.2))
                    .overlay {
                        VStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.8)
                            if retryCount > 0 {
                                Text("Retry \(retryCount)/\(maxRetries)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
            } else {
                // Final error state (only after all retries exhausted)
                Rectangle()
                    .fill(.gray.opacity(0.2))
                    .overlay {
                        VStack(spacing: 4) {
                            Image(systemName: "photo.badge.exclamationmark")
                                .font(.title2)
                                .foregroundColor(.orange)
                            Text("Image unavailable")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: urlString) { oldValue, newValue in
            // Reset and reload if URL changes
            if oldValue != newValue {
                resetState()
                loadImage()
            }
        }
    }

    private func resetState() {
        loadedImage = nil
        isLoading = false
        retryCount = 0
        hasFailed = false
    }

    private func loadImage() {
        guard loadedImage == nil else { return } // Don't reload if already loaded
        guard let urlString = urlString else {
            print("⚠️ RobustAsyncImage: URL string is nil")
            hasFailed = true
            return
        }

        isLoading = true

        Task {
            await performLoad(urlString: urlString)
        }
    }

    private func performLoad(urlString: String) async {
        // Create URL with our robust URL creation logic
        guard let url = createURL(from: urlString) else {
            await MainActor.run {
                isLoading = false
                hasFailed = true
            }
            return
        }

        do {
            // Configure URLRequest with appropriate timeout and cache policy
            var request = URLRequest(url: url)
            request.timeoutInterval = retryCount == 0 ? 10.0 : 15.0 // Longer timeout for retries
            request.cachePolicy = retryCount > 0 ? .reloadIgnoringLocalCacheData : .returnCacheDataElseLoad

            print("🖼️ RobustAsyncImage: Loading image (attempt \(retryCount + 1)/\(maxRetries)): \(url.absoluteString)")

            // Load image data using URLSession
            let (data, response) = try await URLSession.shared.data(for: request)

            // Validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ RobustAsyncImage: HTTP \(httpResponse.statusCode) for \(url.absoluteString)")
                throw URLError(.badServerResponse)
            }

            // Create UIImage from data
            guard let uiImage = UIImage(data: data) else {
                print("❌ RobustAsyncImage: Invalid image data for \(url.absoluteString)")
                throw URLError(.cannotDecodeContentData)
            }

            // Success! Update UI on main thread
            await MainActor.run {
                self.loadedImage = uiImage
                self.isLoading = false
                self.hasFailed = false
                print("✅ RobustAsyncImage: Successfully loaded \(url.absoluteString)")
            }

        } catch {
            print("❌ RobustAsyncImage: Attempt \(retryCount + 1) failed: \(error.localizedDescription)")

            await MainActor.run {
                self.hasFailed = true
                self.retryCount += 1

                if self.retryCount < maxRetries {
                    // Schedule retry with exponential backoff
                    print("🔄 RobustAsyncImage: Scheduling retry \(self.retryCount + 1) of \(maxRetries)")
                    Task {
                        // Exponential backoff: 0.5s, 1s, 2s
                        let delay = 0.5 * pow(2.0, Double(self.retryCount - 1))
                        try? await Task.sleep(for: .seconds(delay))
                        await performLoad(urlString: urlString)
                    }
                } else {
                    // All retries exhausted - show final error state
                    self.isLoading = false
                    print("❌ RobustAsyncImage: All \(maxRetries) retries exhausted for \(urlString)")
                }
            }
        }
    }

    /// Creates a valid URL from string with comprehensive encoding handling
    private func createURL(from urlString: String) -> URL? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            print("⚠️ RobustAsyncImage: Empty URL string")
            return nil
        }

        // Convert HTTP to HTTPS for App Transport Security
        let secureUrlString = trimmed.hasPrefix("http://")
            ? trimmed.replacingOccurrences(of: "http://", with: "https://")
            : trimmed

        // First try direct URL creation (works for properly formatted URLs)
        if let url = URL(string: secureUrlString) {
            return url
        }

        print("⚠️ RobustAsyncImage: Direct URL creation failed, attempting encoding fix")

        // Handle URLs that are already partially encoded
        if secureUrlString.contains("%") {
            if let decodedString = secureUrlString.removingPercentEncoding,
               let cleanEncodedString = decodedString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: cleanEncodedString) {
                print("✅ RobustAsyncImage: Created URL with decode-recode")
                return url
            }
        }

        // Try encoding for URLs with unencoded special characters
        if let encodedString = secureUrlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: encodedString) {
            print("✅ RobustAsyncImage: Created URL with encoding")
            return url
        }

        print("❌ RobustAsyncImage: Failed to create valid URL from: '\(secureUrlString)'")
        return nil
    }
}

#Preview {
    VStack(spacing: 20) {
        // Test with valid URL
        RobustAsyncImage(url: "https://spoonacular.com/recipeImages/715538-556x370.jpg") { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
        .frame(width: 200, height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 12))

        // Test with invalid URL (will show loading then error after retries)
        RobustAsyncImage(url: "https://invalid-domain-that-does-not-exist.com/image.jpg") { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
        .frame(width: 200, height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding()
}
