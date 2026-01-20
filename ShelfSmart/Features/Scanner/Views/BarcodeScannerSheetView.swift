//
//  BarcodeScannerSheetView.swift
//  ShelfSmart
//
//  Created by Sai Nikhil Varada on 1/19/26.
//

import SwiftUI
import VisionKit
import AVFoundation

/// Half-screen sheet view for quick barcode scanning and product preview
/// Displays camera viewfinder, then shows product info after successful scan
struct BarcodeScannerSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @Bindable var viewModel: ProductCompareViewModel
    
    @State private var dataScannerManager = DataScannerManager()
    @State private var cameraPermissionManager = CameraPermissionManager()
    @State private var isCheckingPermission = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                if isCheckingPermission {
                    loadingView
                } else if let product = viewModel.scannedProduct {
                    // Show product info after successful scan
                    productInfoView(product: product)
                } else if viewModel.isLoading {
                    searchingView
                } else if cameraPermissionManager.permissionStatus == .denied ||
                            cameraPermissionManager.permissionStatus == .restricted {
                    permissionDeniedView
                } else if !DataScannerManager.isSupported {
                    unsupportedDeviceView
                } else if cameraPermissionManager.permissionStatus == .authorized {
                    scannerView
                } else {
                    permissionDeniedView
                }
            }
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.dismissScanner()
                        dismiss()
                    } label: {
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.gray)
                        
                    }
                }
            }
            .task {
                await checkAndRequestPermission()
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.green)
            Text("Checking camera access...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Searching View
    
    private var searchingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.green)
            
            Text("Searching for product...")
                .font(.headline)
                .foregroundStyle(.primary)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Scanner View
    
    private var scannerView: some View {
        ZStack {
            DataScannerViewControllerRepresentable(
                dataScannerManager: dataScannerManager
            )
            .ignoresSafeArea()
            .onAppear {
                dataScannerManager.onBarcodeScanned = { barcodeValue in
                    handleScannedBarcode(barcodeValue)
                }
            }
            
            // Viewfinder overlay
            ViewfinderOverlay()
            
            // Error message overlay
            if viewModel.productAlreadyExists {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Product already in comparison")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.2), radius: 8)
                    )
                    .padding(.bottom, 100)
                }
            }
            
            if let error = viewModel.errorMessage, !viewModel.productAlreadyExists {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Button {
                            withAnimation {
                                viewModel.errorMessage = nil
                                dataScannerManager.reset()
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                                .padding(8)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.2), radius: 8)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onTapGesture {
                        withAnimation {
                            viewModel.errorMessage = nil
                            dataScannerManager.reset()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Product Info View
    
    private func productInfoView(product: CompareProduct) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Product Image
                productImageView(product: product)
                
                // Product Name & Brand
                productHeaderView(product: product)
                
                // Labels
                if !product.formattedLabels.isEmpty {
                    labelsView(product: product)
                }
                
                // Allergens
                if !product.formattedAllergens.isEmpty {
                    allergensView(product: product)
                }
                
                // Positives & Negatives
                positivesNegativesView(product: product)
                
                // Quick Stats (Calories)
                quickStatsView(product: product)
                
                // Summary Scores
                summaryScoresView(product: product)
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.addToComparison()
                    dismiss()
                } label: {
                    Text("Add")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .disabled(!viewModel.canAddToComparison)
            }
        }
    }
    
    // MARK: - Product Image
    
    private func productImageView(product: CompareProduct) -> some View {
        ZStack {
            if let imageURL = product.images.front, !imageURL.isEmpty {
                RobustAsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                }
            } else {
                Image("placeholder")
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Product Header
    
    private func productHeaderView(product: CompareProduct) -> some View {
        VStack(spacing: 6) {
            Text(product.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
            
            if let brand = product.brand, !brand.isEmpty {
                Text("by \(brand)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Quick Stats
    
    private func quickStatsView(product: CompareProduct) -> some View {
        VStack(spacing: 4) {
            Text("Calories")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if let calories = product.nutrition.calories {
                    Text("\(Int(calories))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                } else {
                    Text("N/A")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
                
                Text("kcal per 100g")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Summary Scores
    
    private func summaryScoresView(product: CompareProduct) -> some View {
        HStack(spacing: 12) {
            ScoreBadgeCompact(
                grade: product.nutriscoreGradeDisplay,
                title: "Nutri-Score",
                color: product.nutriscoreColor
            )
            
            ScoreBadgeCompact(
                grade: product.ecoscoreGradeDisplay,
                title: "Eco-Score",
                color: product.ecoscoreColor
            )
            
            ScoreBadgeCompact(
                grade: product.processingLevelGrade,
                title: "Processing",
                color: product.processingLevelColor
            )
        }
    }
    
    // MARK: - Positives & Negatives
    
    private func positivesNegativesView(product: CompareProduct) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Positives
            VStack(alignment: .leading, spacing: 8) {
                Text("Positives")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
                
                if let positives = product.metadata.positives, !positives.isEmpty {
                    ForEach(positives.prefix(3), id: \.self) { item in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                            Text(item)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("N/A")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemBackground))
            )
            
            // Negatives
            VStack(alignment: .leading, spacing: 8) {
                Text("Negatives")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.red)
                
                if let negatives = product.metadata.negatives, !negatives.isEmpty {
                    ForEach(negatives.prefix(3), id: \.self) { item in
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.red)
                            Text(item)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("N/A")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - Allergens View
    
    private func allergensView(product: CompareProduct) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Text("Allergens")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .padding(.trailing, 4)
                
                ForEach(product.formattedAllergens, id: \.self) { allergen in
                    Text(allergen)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.15))
                        )
                        .foregroundStyle(.orange)
                }
            }
        }
    }
    
    // MARK: - Labels View
    
    private func labelsView(product: CompareProduct) -> some View {
        HStack(spacing: 8) {
            ForEach(product.formattedLabels, id: \.text) { label in
                HStack(spacing: 4) {
                    Image(systemName: label.icon)
                        .font(.caption2)
                    Text(label.text)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(label.color.opacity(0.15))
                )
                .foregroundStyle(label.color)
            }
        }
    }
    
    // MARK: - Add to Compare Button
    
    
    
    // MARK: - Permission Denied View
    
    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill.badge.ellipsis")
                .font(.system(size: 60))
                .foregroundStyle(.red)
            
            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Please enable camera access in Settings to scan barcodes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                cameraPermissionManager.openSettings()
            } label: {
                Text("Open Settings")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Unsupported Device View
    
    private var unsupportedDeviceView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("Scanner Unavailable")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Barcode scanning is not supported on this device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkAndRequestPermission() async {
        isCheckingPermission = true
        cameraPermissionManager.checkPermissionStatus()
        
        if cameraPermissionManager.permissionStatus == .notDetermined {
            _ = await cameraPermissionManager.requestPermission()
        }
        
        await MainActor.run {
            isCheckingPermission = false
        }
    }
    
    private func handleScannedBarcode(_ barcodeValue: String) {
        print("📷 [QuickScan] Scanned barcode: \(barcodeValue)")
        
        Task {
            await viewModel.scanBarcode(barcodeValue)
        }
    }
}

// MARK: - Supporting Views

struct ScoreBadgeCompact: View {
    let grade: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Text(grade)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }
            
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Simple flow layout for tags
struct ScannerFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalHeight = currentY + lineHeight
        }
        
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

// MARK: - Preview

#Preview {
    BarcodeScannerSheetView(viewModel: ProductCompareViewModel())
}
