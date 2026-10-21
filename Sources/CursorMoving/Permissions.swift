import AppKit
import ApplicationServices
import CursorMovingCore

@MainActor
enum Permissions {
    /// 앱 시작 시 손쉬운 사용 권한이 없으면 시스템 프롬프트를 띄운다.
    static func promptAccessibilityIfNeeded() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    /// 이벤트 주입(커서 이동)에 필요
    static func ensureAccessibility(_ strings: Strings) -> Bool {
        guard !AXIsProcessTrusted() else { return true }
        showAlert(
            title: strings.accessibilityAlertTitle,
            message: strings.accessibilityAlertMessage,
            buttons: (strings.openSettings, strings.close),
            openSettings: openAccessibilitySettings
        )
        return false
    }

    static func openAccessibilitySettings() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    private static func showAlert(
        title: String,
        message: String,
        buttons: (open: String, close: String),
        openSettings: () -> Void
    ) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: buttons.open)
        alert.addButton(withTitle: buttons.close)
        if alert.runModal() == .alertFirstButtonReturn {
            openSettings()
        }
    }

    private static func open(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
}
