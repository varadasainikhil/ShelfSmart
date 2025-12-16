//
//  QuickScannerView.swift
//  ShelfSmart
//
//  Created by Claude Code on 12/15/25.
//

import SwiftUI
import VisionKit
import AVFoundation

@available(iOS 16, *)
struct QuickScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var dataScannerManager = DataScannerManager()
    @State private var cameraPermissionManager = CameraPermissionManager()
    @State private var isCheckingPermission = true

    @Bindable var viewModel: QuickScanViewModel

    var body: some View {
        ZStack {
            // Show loading while checking permission
            if isCheckingPermission {
                ProgressView("Checking camera access...")
                    .tint(.green)
            }
            // Permission Denied or Restricted
            else if cameraPermissionManager.permissionStatus == .denied ||
                    cameraPermissionManager.permissionStatus == .restricted {
                QuickScanPermissionDeniedView(
                    permissionStatus: cameraPermissionManager.permissionStatus,
                    onOpenSettings: {
                        cameraPermissionManager.openSettings()
                    },
                    onDismiss: { dismiss() }
                )
            }
            // Device/OS doesn't support DataScanner
            else if !DataScannerManager.isSupported {
                QuickScanUnavailableView(
                    title: "Camera Scanner Unavailable",
                    message: "Barcode scanning requires iOS 16+ and compatible hardware.",
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
                    dataScannerManager.onBarcodeScanned = { barcodeValue in
                        handleScannedBarcode(barcodeValue)
                    }
                }

                // Viewfinder Overlay
                if !viewModel.isLoading {
                    QuickScanViewfinderOverlay()
                }
            }
            // Fallback
            else {
                QuickScanUnavailableView(
                    title: "Camera Access Required",
                    message: "Please grant camera permission to scan barcodes.",
                    onDismiss: { dismiss() }
                )
            }

            // Loading Overlay
            if viewModel.isLoading {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)

                    Text("Fetching product info...")
                        .foregroundStyle(.white)
                        .font(.headline)
                }
            }

            // Close Button (top-left)
            if !viewModel.isLoading {
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
        .alert("Error", isPresented: $viewModel.showError) {
            Button("Try Again") {
                dataScannerManager.reset()
            }
            Button("Close", role: .cancel) {
                dismiss()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .task {
            await checkAndRequestPermission()
        }
        .onChange(of: viewModel.showProductSheet) { _, showSheet in
            if showSheet {
                // Dismiss scanner sheet so product sheet can be shown from main view
                dismiss()
            }
        }
    }

    // MARK: - Check and Request Permission
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

    // MARK: - Handle Scanned Barcode
    private func handleScannedBarcode(_ barcodeValue: String) {
        print("Processing scanned barcode: \(barcodeValue)")
        viewModel.fetchProductFromScan(barcodeValue)
    }
}

// MARK: - Viewfinder Overlay
struct QuickScanViewfinderOverlay: View {
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

// MARK: - Permission Denied View
struct QuickScanPermissionDeniedView: View {
    let permissionStatus: AVAuthorizationStatus
    let onOpenSettings: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(.red.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: permissionStatus == .restricted ?
                      "lock.fill" : "camera.fill.badge.ellipsis")
                    .font(.system(size: 40))
                    .foregroundStyle(.red)
            }

            Text(permissionStatus == .restricted ?
                 "Camera Restricted" : "Camera Access Denied")
                .font(.title2)
                .fontWeight(.bold)

            Text(permissionStatus == .restricted ?
                 "Camera access is restricted. Please check your device settings." :
                 "Please enable camera access in Settings to scan barcodes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(spacing: 12) {
                if permissionStatus == .denied {
                    Button {
                        onOpenSettings()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "gear")
                            Text("Open Settings")
                        }
                        .font(.headline)
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
                        .cornerRadius(12)
                        .shadow(color: .green.opacity(0.4), radius: 8, x: 0, y: 4)
                        .shadow(color: .green.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    .padding(.horizontal, 40)
                }

                Button {
                    onDismiss()
                } label: {
                    Text("Close")
                        .font(.headline)
                        .foregroundStyle(permissionStatus == .denied ? .green : .white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background {
                            if permissionStatus == .denied {
                                Color.clear
                            } else {
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(permissionStatus == .denied ?
                                        Color.green : Color.clear, lineWidth: 2)
                        )
                        .cornerRadius(12)
                        .shadow(color: permissionStatus == .denied ? .clear : .green.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .padding(.horizontal, 40)
            }
        }
        .padding()
    }
}

// MARK: - Scanner Unavailable View
struct QuickScanUnavailableView: View {
    let title: String
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(.gray.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "camera.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.gray)
            }

            Text(title)
                .font(.title2)
                .fontWeight(.bold)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                onDismiss()
            } label: {
                Text("Close")
                    .font(.headline)
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
                    .cornerRadius(12)
                    .shadow(color: .green.opacity(0.4), radius: 8, x: 0, y: 4)
                    .shadow(color: .green.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
}

#Preview {
    if #available(iOS 16, *) {
        QuickScannerView(viewModel: QuickScanViewModel())
    }
}
