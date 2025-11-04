//
//  BarcodeScannerView.swift
//  ShelfSmart
//
//  Created by Claude Code on 10/26/25.
//

import SwiftUI
import SwiftData
import VisionKit
import Vision
import AVFoundation

@available(iOS 16, *)
struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var dataScannerManager = DataScannerManager()
    @State private var cameraPermissionManager = CameraPermissionManager()
    @State private var showUnsupportedAlert = false
    @State private var isCheckingPermission = true

    let viewModel: AddProductViewViewModel
    let modelContext: ModelContext

    var body: some View {
        ZStack {
            // Show loading while checking permission
            if isCheckingPermission {
                ProgressView("Checking camera access...")
                    .tint(.green)
            }
            // Permission Denied or Restricted - Check this FIRST before device support
            else if cameraPermissionManager.permissionStatus == .denied ||
                    cameraPermissionManager.permissionStatus == .restricted {
                CameraPermissionDeniedView(
                    permissionStatus: cameraPermissionManager.permissionStatus,
                    onOpenSettings: {
                        cameraPermissionManager.openSettings()
                    },
                    onDismiss: { dismiss() }
                )
            }
            // Device/OS doesn't support DataScanner
            else if !DataScannerManager.isSupported {
                // Unsupported device fallback
                CameraUnavailableView(
                    title: "Camera Scanner Unavailable",
                    message: "Barcode scanning is not supported on this device or iOS version. Please enter the barcode manually.",
                    icon: "camera.fill",
                    onDismiss: { dismiss() }
                )
            }
            // Permission Authorized - Show Scanner
            else if cameraPermissionManager.permissionStatus == .authorized {
                DataScannerViewControllerRepresentable(
                    dataScannerManager: dataScannerManager
                )
                .ignoresSafeArea()
                .onAppear {
                    // Set up callback for when barcode is scanned
                    dataScannerManager.onBarcodeScanned = { barcodeValue in
                        handleScannedBarcode(barcodeValue)
                    }
                }

                // Viewfinder Overlay with Square Cutout
                if !dataScannerManager.isSearching {
                    ViewfinderOverlay()
                }
            }
            // Fallback for any other state
            else {
                CameraUnavailableView(
                    title: "Camera Access Required",
                    message: "Please grant camera permission to scan barcodes.",
                    icon: "camera.fill",
                    onDismiss: { dismiss() }
                )
            }

            // Loading Overlay
            if dataScannerManager.isSearching {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)

                    Text("Searching for product...")
                        .foregroundStyle(.white)
                        .font(.headline)
                }
            }

            // Close Button (top-left)
            if !dataScannerManager.isSearching {
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding()

                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .alert("Scanner Error", isPresented: .constant(dataScannerManager.dataScannerFailure != nil)) {
            Button("OK") {
                dataScannerManager.dataScannerFailure = nil
                dismiss()
            }
        } message: {
            if let failure = dataScannerManager.dataScannerFailure {
                Text("Scanner became unavailable: \(failure.localizedDescription)")
            }
        }
        .task {
            // Check and request permission when view appears
            await checkAndRequestPermission()
        }
    }

    // MARK: - Check and Request Permission
    private func checkAndRequestPermission() async {
        print("📷 Checking camera permission...")
        isCheckingPermission = true

        // Check current permission status
        cameraPermissionManager.checkPermissionStatus()

        // If not determined, request permission
        if cameraPermissionManager.permissionStatus == .notDetermined {
            print("📷 Permission not determined, requesting...")
            _ = await cameraPermissionManager.requestPermission()
        }

        // Done checking
        await MainActor.run {
            isCheckingPermission = false
        }
    }

    // MARK: - Handle Scanned Barcode
    private func handleScannedBarcode(_ barcodeValue: String) {
        print("📷 Processing scanned barcode: \(barcodeValue)")

        // Show loading indicator
        dataScannerManager.isSearching = true

        // Trigger the search in the view model
        Task {
            await viewModel.handleScannedBarcode(barcodeValue, modelContext: modelContext)

            // Dismiss scanner after search completes
            await MainActor.run {
                dataScannerManager.isSearching = false
                dismiss()
            }
        }
    }
}

// MARK: - DataScannerViewController Wrapper
@available(iOS 16, *)
struct DataScannerViewControllerRepresentable: UIViewControllerRepresentable {
    let dataScannerManager: DataScannerManager

    func makeUIViewController(context: Context) -> DataScannerViewController {
        // Configure DataScannerViewController for barcode scanning
        let dataScannerViewController = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean13, .upce])],
            qualityLevel: .fast,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )

        // Set delegate
        dataScannerViewController.delegate = dataScannerManager

        return dataScannerViewController
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // Start scanning when view appears
        if !uiViewController.isScanning {
            do {
                try uiViewController.startScanning()
                print("📷 Started barcode scanning")
            } catch {
                print("❌ Failed to start scanning: \(error.localizedDescription)")
                // Note: Errors will be handled by the delegate's becameUnavailableWithError method
            }
        }
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: ()) {
        // Stop scanning when view disappears
        if uiViewController.isScanning {
            uiViewController.stopScanning()
            print("📷 Stopped barcode scanning")
        }
    }
}

// MARK: - Viewfinder Overlay
struct ViewfinderOverlay: View {
    let squareSize: CGFloat = 250

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let centerX = screenWidth / 2
            let centerY = screenHeight / 2

            ZStack {
                // Semi-transparent dark overlay with cutout
                ViewfinderShape(
                    cutoutRect: CGRect(
                        x: centerX - squareSize / 2,
                        y: centerY - squareSize / 2,
                        width: squareSize,
                        height: squareSize
                    )
                )
                .fill(Color.black.opacity(0.5), style: .init(eoFill: true))
                .ignoresSafeArea()

                // Guidance text
                VStack {
                    Spacer()
                        .frame(height: centerY + squareSize / 2 + 30)

                    Text("Position barcode within frame")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.7))
                        )
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

                    Spacer()
                }
            }
        }
    }
}

// MARK: - Viewfinder Shape with Cutout
struct ViewfinderShape: Shape {
    let cutoutRect: CGRect

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Add the full rectangle
        path.addRect(rect)

        // Subtract the rounded rectangle cutout (using even-odd fill rule)
        let cutoutPath = Path(roundedRect: cutoutRect, cornerRadius: 20)
        path.addPath(cutoutPath)

        return path
    }
}

// MARK: - Camera Permission Denied View
struct CameraPermissionDeniedView: View {
    let permissionStatus: AVAuthorizationStatus
    let onOpenSettings: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(.red.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: permissionStatus == .restricted ? "lock.fill" : "camera.fill.badge.ellipsis")
                    .font(.system(size: 40))
                    .foregroundStyle(.red)
            }

            // Title
            Text(permissionStatus == .restricted ? "Camera Restricted" : "Camera Access Denied")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            // Message
            Text(permissionStatus == .restricted ?
                 "Camera access is restricted by parental controls or device management. Please check your device settings." :
                 "ShelfSmart needs camera access to scan product barcodes. Please enable camera access in Settings to use this feature.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Buttons
            VStack(spacing: 12) {
                if permissionStatus == .denied {
                    Button {
                        onOpenSettings()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "gear")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Open Settings")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                }

                Button {
                    onDismiss()
                } label: {
                    Text("Use Manual Entry")
                        .font(.headline)
                        .foregroundStyle(permissionStatus == .denied ? .green : .white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(permissionStatus == .denied ? Color.clear : Color.green)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(permissionStatus == .denied ? Color.green : Color.clear, lineWidth: 2)
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }
        }
        .padding()
    }
}

// MARK: - Camera Unavailable View
struct CameraUnavailableView: View {
    let title: String
    let message: String
    let icon: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(.gray.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(.gray)
            }

            // Title
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            // Message
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Button
            Button {
                onDismiss()
            } label: {
                Text("Use Manual Entry")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
}

// MARK: - Preview
#Preview {
    let container = try! ModelContainer(for: Product.self)
    return BarcodeScannerView(
        viewModel: AddProductViewViewModel(),
        modelContext: container.mainContext
    )
}
