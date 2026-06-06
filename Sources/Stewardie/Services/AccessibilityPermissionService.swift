import AppKit
import ApplicationServices

enum AccessibilityPermissionService {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    static var permissionTargetDescription: String {
        Bundle.main.bundleURL.standardizedFileURL.path
    }

    static func requestAccess() {
        let options = [
            "AXTrustedCheckOptionPrompt": true
        ] as CFDictionary

        AXIsProcessTrustedWithOptions(options)
    }

    static func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}
