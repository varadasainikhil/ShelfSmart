//
//  DataScannerManager.swift
//  ShelfSmart
//
//  Created by Claude Code on 10/26/25.
//

import Foundation
import SwiftUI
import VisionKit

@available(iOS 16, *)
@Observable
final class DataScannerManager: NSObject, DataScannerViewControllerDelegate {
    // MARK: - Published Properties
    var scannedBarcodeString: String = ""
    var hasScannedBarcode: Bool = false
    var isSearching: Bool = false
    var dataScannerFailure: DataScannerViewController.ScanningUnavailable?

    // MARK: - Callback for notifying parent view
    var onBarcodeScanned: ((String) -> Void)?

    // MARK: - Device Capability Check
    /// Checks if the device hardware and OS support DataScanner (independent of camera permissions)
    static var isSupported: Bool {
        // Only check hardware/OS support, not availability (which depends on permissions)
        DataScannerViewController.isSupported
    }

    // MARK: - Reset Method
    func reset() {
        scannedBarcodeString = ""
        hasScannedBarcode = false
        isSearching = false
        dataScannerFailure = nil
    }

    // MARK: - DataScannerViewControllerDelegate Methods

    /// Called when new items are recognized in the camera view
    func dataScanner(
        _ dataScanner: DataScannerViewController,
        didAdd addedItems: [RecognizedItem],
        allItems: [RecognizedItem]
    ) {
        // Only process if we haven't already scanned a barcode
        guard !hasScannedBarcode else { return }

        // Get the first recognized item
        guard let item = addedItems.first else { return }

        // Check if it's a barcode
        switch item {
        case .barcode(let barcode):
            // Extract the barcode value
            guard let barcodeValue = barcode.payloadStringValue else { return }

            print("📷 Barcode detected: \(barcodeValue)")

            // Trigger haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            // Update state
            scannedBarcodeString = barcodeValue
            hasScannedBarcode = true

            // Notify parent view to start API search
            onBarcodeScanned?(barcodeValue)

        default:
            break
        }
    }

    /// Called when items are removed from the camera view
    func dataScanner(
        _ dataScanner: DataScannerViewController,
        didRemove removedItems: [RecognizedItem],
        allItems: [RecognizedItem]
    ) {
        // We don't need to handle removal in this implementation
        // since we capture the barcode immediately
    }

    /// Called when items are updated in the camera view
    func dataScanner(
        _ dataScanner: DataScannerViewController,
        didUpdate updatedItems: [RecognizedItem],
        allItems: [RecognizedItem]
    ) {
        // We don't need to handle updates in this implementation
    }

    /// Called when user taps on a recognized item
    func dataScanner(
        _ dataScanner: DataScannerViewController,
        didTapOn item: RecognizedItem
    ) {
        // Optional: Could be used for manual confirmation of barcode
        // Currently using automatic detection via didAdd
    }

    /// Called when scanner becomes unavailable due to an error
    func dataScanner(
        _ dataScanner: DataScannerViewController,
        becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable
    ) {
        print("❌ Scanner became unavailable: \(error)")
        dataScannerFailure = error
    }
}
