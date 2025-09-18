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
        NavigationStack{
            Form{
                Section{
                    CustomTextFieldWithHeading(heading: "BarCode", textToShow: "Enter the product Barcode", variabletoBind: $viewModel.barcode)
                        .keyboardType(.decimalPad)
                    
                    Button {
                        // search for the product
                        Task{
                            try await viewModel.searchProduct(modelContext: modelContext)
                        }
                        
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Searching...")
                            } else {
                                Text("Search")
                            }
                        }
                    }
                    .disabled(viewModel.isSearchButtonDisabled)
                    
                    // Show error message if exists
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    // Show success message
                    if viewModel.searchSuccess {
                        Text("✅ Product found and loaded")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                // Product Preview Section
                if viewModel.searchSuccess {
                    Section("Product Preview") {
                        HStack {
                            // Product Image Preview
                            VStack {
                                if !viewModel.imageLink.isEmpty {
                                    let secureImageLink = viewModel.imageLink.hasPrefix("http://") ? 
                                        viewModel.imageLink.replacingOccurrences(of: "http://", with: "https://") : 
                                        viewModel.imageLink
                                    
                                    AsyncImage(url: URL(string: secureImageLink)) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } else if phase.error != nil {
                                            Image(systemName: "photo")
                                                .foregroundColor(.gray)
                                        } else {
                                            ProgressView()
                                        }
                                    }
                                } else {
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                }
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewModel.name)
                                    .font(.headline)
                                    .lineLimit(2)
                                
                                if !viewModel.productDescription.isEmpty {
                                    Text(viewModel.productDescription)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(3)
                                }
                                
                                Text("Barcode: \(viewModel.barcode)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section{
                    CustomTextFieldWithHeading(heading: "Product Name", textToShow: "Enter the Product Name", variabletoBind: $viewModel.name)
                    
                    CustomTextFieldWithHeading(heading: "Description", textToShow: "Enter Product Description", variabletoBind: $viewModel.productDescription)
                    
                    DatePicker("Enter the Expiration Date", selection: $viewModel.expirationDate, displayedComponents: [.date])
                        .datePickerStyle(.wheel)
                    
                    // Show error message for product creation if exists
                    if let errorMessage = viewModel.errorMessage, !errorMessage.contains("API key") && !errorMessage.contains("Network") && !errorMessage.contains("products found") {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .listRowSeparator(.hidden)
                
            }
            .navigationTitle("Add a Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if viewModel.searchSuccess, let apiResponse = viewModel.apiResponse {
                            // Product was found via barcode search - save it with user's selected expiration date
                            viewModel.createProductFromAPIResponse(apiResponse: apiResponse, modelContext: modelContext)
                        } else {
                            // No barcode search success - try to create manual product
                            viewModel.createManualProduct(modelContext: modelContext)
                        }

                        // Only dismiss if no error occurred
                        if viewModel.errorMessage == nil {
                            dismiss()
                        }
                        
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    
                }
            }
        }
    }
}

#Preview {
    AddProductView(viewModel: AddProductViewViewModel())
}
