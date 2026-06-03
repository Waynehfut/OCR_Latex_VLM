import AppKit
import CoreGraphics
import Foundation

@MainActor
final class ScreenCapturePermissionService {
    func currentState() -> ScreenCapturePermissionState {
        CGPreflightScreenCaptureAccess() ? .authorized : .missing
    }

    func requestAccess() -> ScreenCapturePermissionState {
        if CGPreflightScreenCaptureAccess() {
            return .authorized
        }

        return CGRequestScreenCaptureAccess() ? .authorized : .missing
    }

    func openSystemSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenRecording"
        ]

        for candidate in candidates {
            guard let url = URL(string: candidate) else {
                continue
            }
            if NSWorkspace.shared.open(url) {
                return
            }
        }

        if let fallbackURL = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
            NSWorkspace.shared.open(fallbackURL)
        }
    }
}
