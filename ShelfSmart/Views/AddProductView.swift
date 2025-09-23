//
//  AddProductView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 8/26/25.
//

import SwiftData
import SwiftUI

struct AddProductView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @State var viewModel: AddProductViewViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Add New")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                Text("Product")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                            }
                            
                            Text("Scan a barcode or enter product details manually")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Barcode Search Section
                        VStack(spacing: 16) {
                            ModernSearchCard(
                                barcode: $viewModel.barcode,
                                isLoading: viewModel.isLoading,
                                isDisabled: viewModel.isSearchButtonDisabled,
                                errorMessage: viewModel.errorMessage,
                                searchSuccess: viewModel.searchSuccess,
                                onSearch: {
                                    Task {
                                        try await viewModel.searchProduct(modelContext: modelContext)
                                    }
                                }
                            )
                            
                            // Product Preview Card
                            if viewModel.searchSuccess {
                                ModernProductPreviewCard(
                                    name: viewModel.name,
                                    description: viewModel.productDescription,
                                    barcode: viewModel.barcode,
                                    imageLink: viewModel.imageLink
                                )
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .opacity
                                ))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Manual Entry Section
                        VStack(spacing: 16) {
                            ModernManualEntryCard(
                                name: $viewModel.name,
                                description: $viewModel.productDescription,
                                expirationDate: $viewModel.expirationDate,
                                errorMessage: viewModel.errorMessage
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100) // Space for floating button
                    }
                }
                
                // Floating Save Button
                VStack {
                    Spacer()
                    ModernSaveButton(
                        searchSuccess: viewModel.searchSuccess,
                        hasApiResponse: viewModel.apiResponse != nil,
                        isSaving: viewModel.isSaving,
                        isDisabled: viewModel.isSaveButtonDisabled,
                        onSave: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            if viewModel.searchSuccess, let apiResponse = viewModel.apiResponse {
                                // For API response, we need to handle reset after async completion (same as manual entry)
                                Task {
                                    await viewModel.createProductFromAPIResponse(apiResponse: apiResponse, modelContext: modelContext)
                                    
                                    await MainActor.run {
                                        if viewModel.errorMessage == nil {
                                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                                viewModel.resetAllFields()
                                                dismiss()
                                            }
                                        }
                                    }
                                }
                            } else {
                                // For manual entry, we need to handle reset after async completion
                                Task {
                                    await viewModel.createManualProduct(modelContext: modelContext)
                                    
                                    await MainActor.run {
                                        if viewModel.errorMessage == nil {
                                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                                viewModel.resetAllFields()
                                                dismiss()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    )
                    .padding(.bottom, 34)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .onAppear {
                viewModel.resetAllFields()
            }
        }
    }
}

// MARK: - Modern Search Card
struct ModernSearchCard: View {
    @Binding var barcode: String
    let isLoading: Bool
    let isDisabled: Bool
    let errorMessage: String?
    let searchSuccess: Bool
    let onSearch: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Barcode Search")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("Scan or enter a product barcode")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Circle()
                    .fill(.green.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.green)
                    }
            }
            
            // Barcode Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Barcode")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                HStack {
                    TextField("Enter product barcode", text: $barcode)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    
                    Button(action: onSearch) {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            Text(isLoading ? "Searching..." : "Search")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isDisabled ? Color(.systemGray4) : .green)
                        )
                    }
                    .disabled(isDisabled)
                }
            }
            
            // Status Messages
            if let errorMessage = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.red.opacity(0.1))
                )
            } else if searchSuccess {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text("Product found and loaded")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.green.opacity(0.1))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Modern Product Preview Card
struct ModernProductPreviewCard: View {
    let name: String
    let description: String
    let barcode: String
    let imageLink: String
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Product Preview")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("Found product details")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Circle()
                    .fill(.green.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.green)
                    }
            }
            
            HStack(spacing: 16) {
                // Product Image
                Group {
                    if !imageLink.isEmpty {
                        let secureImageLink = imageLink.hasPrefix("http://") ? 
                            imageLink.replacingOccurrences(of: "http://", with: "https://") : 
                            imageLink
                        
                        AsyncImage(url: URL(string: secureImageLink)) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                            } else if phase.error != nil {
                                Image(systemName: "photo")
                                    .foregroundStyle(.gray)
                            } else {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    } else {
                        Image(systemName: "photo")
                            .foregroundStyle(.gray)
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                    
                    if !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                    
                    Text("Barcode: \(barcode)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.systemGray6))
                        )
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Modern Manual Entry Card
struct ModernManualEntryCard: View {
    @Binding var name: String
    @Binding var description: String
    @Binding var expirationDate: Date
    let errorMessage: String?
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Manual Entry")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("Enter product details manually")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Circle()
                    .fill(.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "pencil")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.blue)
                    }
            }
            
            VStack(spacing: 16) {
                // Product Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Product Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    TextField("Enter product name", text: $name)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                }
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    TextField("Enter product description", text: $description, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .lineLimit(3...6)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                }
                
                // Expiration Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Expiration Date")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    DatePicker(
                        "Select expiration date",
                        selection: $expirationDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
            }
            
            // Error Message
            if let errorMessage = errorMessage, 
               !errorMessage.contains("API key") && 
               !errorMessage.contains("Network") && 
               !errorMessage.contains("products found") {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.red.opacity(0.1))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Modern Save Button
struct ModernSaveButton: View {
    let searchSuccess: Bool
    let hasApiResponse: Bool
    let isSaving: Bool
    let isDisabled: Bool
    let onSave: () -> Void
    
    var body: some View {
        Button(action: onSave) {
            HStack(spacing: 10) {
                if isSaving {
                    ProgressView()
                        .scaleEffect(0.9)
                        .tint(.white)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                }
                Text(isSaving ? "Saving..." : (searchSuccess ? "Save Product" : "Add Product"))
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isDisabled ? Color(.systemGray4) : .green)
                    .shadow(color: isDisabled ? .clear : .green.opacity(0.4), radius: 12, x: 0, y: 6)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .scaleEffect(searchSuccess ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: searchSuccess)
        .padding(.horizontal, 20)
    }
}


#Preview {
    AddProductView(viewModel: AddProductViewViewModel())
}
