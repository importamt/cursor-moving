import AppKit
import ApplicationServices

@MainActor
enum Permissions {
    /// 앱 시작 시 손쉬운 사용 권한이 없으면 시스템 프롬프트를 띄운다.
    static func promptAccessibilityIfNeeded() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    /// 이벤트 주입(커서 이동)에 필요
    static func ensureAccessibility() -> Bool {
        guard !AXIsProcessTrusted() else { return true }
        showAlert(
            title: "손쉬운 사용 권한이 필요합니다",
            message: "시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용에서 CursorMoving 을 허용해 주세요.",
            openSettings: openAccessibilitySettings
        )
        return false
    }

    static func openAccessibilitySettings() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    static func showAlert(title: String, message: String, openSettings: (() -> Void)? = nil) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        if openSettings != nil {
            alert.addButton(withTitle: "설정 열기")
            alert.addButton(withTitle: "닫기")
        }
        if alert.runModal() == .alertFirstButtonReturn {
            openSettings?()
        }
    }

    private static func open(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
}
