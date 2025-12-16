//
//  QuickScanView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 12/10/25.
//

import SwiftUI

struct QuickScanView: View {
    @State var viewModel = QuickScanViewModel()
    @State private var showScanner = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Scanner Icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 120, height: 120)

                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 50))
                        .foregroundStyle(.green)
                }

                // Title and Description
                VStack(spacing: 8) {
                    Text("Quick Scan")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Scan a product barcode to quickly check its nutritional information")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Scan Button
                Button {
                    showScanner = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20))
                        Text("Scan Barcode")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .green.opacity(0.4), radius: 10, x: 0, y: 4)
                    .shadow(color: .green.opacity(0.2), radius: 2, x: 0, y: 1)
                }
                .padding(.horizontal, 24)

                // Manual Entry Section
                VStack(spacing: 12) {
                    Text("Or enter barcode manually")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        TextField("Enter barcode", text: $viewModel.barcode)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .focused($isTextFieldFocused)
                            .submitLabel(.search)
                            .onSubmit {
                                if !viewModel.barcode.isEmpty {
                                    viewModel.fetchProduct()
                                }
                            }

                        Button {
                            viewModel.fetchProduct()
                            viewModel.barcode = ""
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    viewModel.barcode.isEmpty ?
                                    Color.gray : Color.green
                                )
                                .cornerRadius(10)
                                .shadow(color: viewModel.barcode.isEmpty ? .clear : .green.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .disabled(viewModel.barcode.isEmpty || viewModel.isLoading)
                    }
                }
                .padding(.horizontal, 24)

                // Loading indicator for manual entry
                if viewModel.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Searching...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
                    .frame(height: 40)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isTextFieldFocused = false
            }
            .navigationTitle("Quick Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isTextFieldFocused = false
                    }
                }
            }
            .onAppear {
                // Show scanner immediately when Quick Scan tab is selected
                showScanner = true
            }
            .sheet(isPresented: $showScanner) {
                if #available(iOS 16.4, *) {
                    QuickScannerView(viewModel: viewModel)
                        .presentationDetents([.fraction(0.75)])
                        .presentationDragIndicator(.visible)
                        .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.75)))
                        .interactiveDismissDisabled(false)
                } else if #available(iOS 16, *) {
                    QuickScannerView(viewModel: viewModel)
                        .presentationDetents([.fraction(0.75)])
                        .presentationDragIndicator(.visible)
                } else {
                    // Fallback for older iOS versions
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundStyle(.orange)

                        Text("Scanner Unavailable")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Barcode scanning requires iOS 16 or later.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Close") {
                            showScanner = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .presentationDetents([.fraction(0.75)])
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $viewModel.showProductSheet) {
                QuickScanProductSheet(viewModel: viewModel)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
}

#Preview {
    QuickScanView()
}
