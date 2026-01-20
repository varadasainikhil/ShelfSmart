//
//  SimpleAsyncImage.swift
//  ShelfSmart
//
//  Created by AI Assistant on 9/20/25.
//

import SwiftUI

/// A simple AsyncImage wrapper that handles common issues
struct SimpleAsyncImage<Content: View>: View {
    let urlString: String?
    let content: (Image) -> Content
    
    init(url: String?, @ViewBuilder content: @escaping (Image) -> Content) {
        self.urlString = url
        self.content = content
    }
    
    var body: some View {
        AsyncImage(url: createURL(from: urlString)) { phase in
            switch phase {
            case .success(let image):
                content(image)
            case .failure(_):
                // Simple error state
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
            case .empty:
                // Simple loading state
                Rectangle()
                    .fill(.gray.opacity(0.2))
                    .overlay {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
            @unknown default:
                Rectangle()
                    .fill(.gray.opacity(0.2))
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
            }
        }
        .transaction { $0.animation = nil }
        .id(urlString)
    }
    
    /// Simple helper to create secure URLs with proper encoding
    private func createURL(from urlString: String?) -> URL? {
        guard let urlString = urlString?.trimmingCharacters(in: .whitespacesAndNewlines),
              !urlString.isEmpty else {
            print("⚠️ SimpleAsyncImage: URL string is nil or empty")
            return nil
        }

        // Convert HTTP to HTTPS for App Transport Security
        let secureUrlString = urlString.hasPrefix("http://")
            ? urlString.replacingOccurrences(of: "http://", with: "https://")
            : urlString

        // First try direct URL creation (works for most properly formatted URLs)
        if let url = URL(string: secureUrlString) {
            print("✅ SimpleAsyncImage: Successfully created URL: \(url.absoluteString)")
            return url
        }

        // If direct creation fails, handle encoding more carefully
        print("⚠️ SimpleAsyncImage: Direct URL creation failed, attempting encoding fix for: '\(secureUrlString)'")

        // Check if URL appears to be already partially encoded (contains %)
        if secureUrlString.contains("%") {
            // Try to decode and re-encode cleanly to avoid double-encoding
            if let decodedString = secureUrlString.removingPercentEncoding,
               let cleanEncodedString = decodedString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: cleanEncodedString) {
                print("✅ SimpleAsyncImage: Created URL after decode-recode: \(url.absoluteString)")
                return url
            }
        }

        // For URLs without existing encoding, try encoding with urlQueryAllowed
        // This preserves :, /, and other URL structure while encoding spaces and special chars
        if let encodedString = secureUrlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: encodedString) {
            print("✅ SimpleAsyncImage: Created URL with encoding: \(url.absoluteString)")
            return url
        }

        // If all attempts fail, log the problematic URL for debugging
        print("❌ SimpleAsyncImage: Failed to create URL from: '\(secureUrlString)'")
        return nil
    }
}

#Preview {
    VStack(spacing: 20) {
        SimpleAsyncImage(url: "https://spoonacular.com/recipeImages/715538-556x370.jpg") { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
        .frame(width: 200, height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        
        SimpleAsyncImage(url: "invalid-url") { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
        .frame(width: 200, height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding()
}
