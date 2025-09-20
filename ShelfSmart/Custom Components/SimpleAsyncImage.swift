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
    }
    
    /// Simple helper to create secure URLs
    private func createURL(from urlString: String?) -> URL? {
        guard let urlString = urlString?.trimmingCharacters(in: .whitespacesAndNewlines),
              !urlString.isEmpty else {
            return nil
        }
        
        // Convert HTTP to HTTPS for App Transport Security
        let secureUrlString = urlString.hasPrefix("http://") 
            ? urlString.replacingOccurrences(of: "http://", with: "https://") 
            : urlString
        
        return URL(string: secureUrlString)
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
