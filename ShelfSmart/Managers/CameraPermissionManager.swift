//
//  CameraPermissionManager.swift
//  ShelfSmart
//
//  Created by Claude Code on 10/26/25.
//

import AVFoundation
import SwiftUI

@Observable
final class CameraPermissionManager {
    // MARK: - Published Properties
    var permissionStatus: AVAuthorizationStatus = .notDetermined
    var showPermissionDeniedAlert: Bool = false

    // MARK: - Initialization
    init() {
        checkPermissionStatus()
    }

    // MARK: - Permission Status Check
    /// Checks the current camera permission status
    func checkPermissionStatus() {
        permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        print("📷 Camera permission status: \(permissionStatus.description)")
    }

    // MARK: - Request Permission
    /// Requests camera permission from the user
    /// - Returns: Bool indicating if permission was granted
    @MainActor
    func requestPermission() async -> Bool {
        // Check current status
        checkPermissionStatus()

        // If already authorized, return true
        if permissionStatus == .authorized {
            print("✅ Camera permission already authorized")
            return true
        }

        // If restricted or denied, cannot request again
        if permissionStatus == .restricted || permissionStatus == .denied {
            print("❌ Camera permission restricted or denied - cannot request")
            showPermissionDeniedAlert = true
            return false
        }

        // Request permission
        print("📷 Requesting camera permission...")
        let granted = await AVCaptureDevice.requestAccess(for: .video)

        // Update status after request
        checkPermissionStatus()

        if granted {
            print("✅ Camera permission granted")
        } else {
            print("❌ Camera permission denied by user")
            showPermissionDeniedAlert = true
        }

        return granted
    }

    // MARK: - Check if Can Use Camera
    /// Checks if camera can be used (permission granted and device supported)
    func canUseCamera() -> Bool {
        checkPermissionStatus()
        return permissionStatus == .authorized
    }

    // MARK: - Open Settings
    /// Opens the app's settings page in the Settings app
    func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL)
                print("📱 Opening Settings app")
            }
        }
    }

    // MARK: - Permission Status Description
    var statusDescription: String {
        switch permissionStatus {
        case .authorized:
            return "Camera access is authorized"
        case .denied:
            return "Camera access is denied. Please enable it in Settings."
        case .restricted:
            return "Camera access is restricted by parental controls or device management."
        case .notDetermined:
            return "Camera permission has not been requested yet."
        @unknown default:
            return "Unknown camera permission status"
        }
    }
}

// MARK: - AVAuthorizationStatus Extension
extension AVAuthorizationStatus {
    var description: String {
        switch self {
        case .authorized:
            return "authorized"
        case .denied:
            return "denied"
        case .restricted:
            return "restricted"
        case .notDetermined:
            return "notDetermined"
        @unknown default:
            return "unknown"
        }
    }
}
