import AppKit
import Combine
import CursorMovingCore
import SwiftUI

/// 환경설정 창에서 전역 단축키를 바꿀 때 쓰는 동작
struct ShortcutActions {
    /// 입력 창이 떠 있는 동안 기존 단축키가 가로채지 않도록 잠시 해제
    let suspend: () -> Void
    /// 저장된 단축키를 다시 등록
    let resume: () -> Void
    /// 새 조합을 등록하고 저장한다. 다른 앱이 쓰고 있으면 false
    let apply: (KeyCombo) -> Bool
}

@MainActor
final class PreferencesWindowController {
    private let settings: Settings
    private let shortcuts: ShortcutActions
    private var window: NSWindow?
    private var titleSubscription: AnyCancellable?

    init(settings: Settings, shortcuts: ShortcutActions) {
        self.settings = settings
        self.shortcuts = shortcuts
    }

    func show() {
        let window = window ?? makeWindow()
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let hosting = NSHostingController(rootView: PreferencesView(settings: settings, shortcuts: shortcuts))
        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        titleSubscription = settings.$language.sink { [weak window] language in
            window?.title = Strings(language: language).settingsTitle
        }
        return window
    }
}

struct PreferencesView: View {
    @ObservedObject var settings: Settings
    let shortcuts: ShortcutActions

    @State private var launchAtLogin = LoginItem.isEnabled
    @State private var loginItemMessage: String?
    @State private var isRecordingShortcut = false
    @State private var shortcutConflict = false

    var body: some View {
        let strings = settings.strings

        Form {
            Section(strings.general) {
                Toggle(strings.launchAtLogin, isOn: launchAtLoginBinding)
                if let loginItemMessage {
                    Text(loginItemMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Toggle(strings.startMovingOnLaunch, isOn: $settings.startMovingOnLaunch)
            }

            Section(strings.languageLabel) {
                Picker(strings.languageLabel, selection: $settings.language) {
                    ForEach(Language.allCases, id: \.self) { language in
                        Text(language.displayName).tag(language)
                    }
                }
            }

            Section(strings.shortcut) {
                LabeledContent(strings.toggleShortcut) {
                    HStack {
                        Text(settings.toggleHotKey.displayString)
                            .monospaced()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(RoundedRectangle(cornerRadius: 5).fill(.quaternary))
                        Button(strings.change) {
                            shortcutConflict = false
                            isRecordingShortcut = true
                        }
                        Button(strings.resetToDefault) {
                            shortcutConflict = !shortcuts.apply(.defaultToggle)
                        }
                        .disabled(settings.toggleHotKey == .defaultToggle)
                    }
                }
                if shortcutConflict {
                    Text(strings.recorderConflict)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
        .sheet(isPresented: $isRecordingShortcut) {
            ShortcutRecorderView(strings: strings) { combo in
                guard shortcuts.apply(combo) else { return false }
                isRecordingShortcut = false
                return true
            } onCancel: {
                isRecordingShortcut = false
            }
            .onAppear(perform: shortcuts.suspend)
            .onDisappear(perform: shortcuts.resume)
        }
        .onAppear(perform: refreshLoginItem)
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding {
            launchAtLogin
        } set: { enabled in
            do {
                try LoginItem.setEnabled(enabled)
                refreshLoginItem()
            } catch {
                refreshLoginItem()
                loginItemMessage = settings.strings.loginItemFailed(error.localizedDescription)
            }
        }
    }

    private func refreshLoginItem() {
        launchAtLogin = LoginItem.isEnabled
        loginItemMessage = LoginItem.needsApproval ? settings.strings.loginItemNeedsApproval : nil
    }
}

/// 키 조합을 직접 눌러 입력받고, 확인을 눌러야 적용하는 작은 창
struct ShortcutRecorderView: View {
    private static let escapeKeyCode: UInt16 = 53
    private static let returnKeyCode: UInt16 = 36

    let strings: Strings
    /// 등록에 실패하면 false 를 돌려받아 창을 유지한다
    let onConfirm: (KeyCombo) -> Bool
    let onCancel: () -> Void

    @State private var captured: KeyCombo?
    @State private var heldModifiers: KeyModifiers = []
    @State private var conflict = false
    @State private var monitor: Any?

    var body: some View {
        VStack(spacing: 14) {
            Text(strings.recorderTitle)
                .font(.headline)

            Text(preview)
                .font(.system(size: 26, weight: .medium, design: .rounded))
                .foregroundStyle(captured == nil && heldModifiers.isEmpty ? .secondary : .primary)
                .frame(minWidth: 220, minHeight: 56)
                .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))

            Text(message)
                .font(.caption)
                .foregroundStyle(isError ? .red : .secondary)
                .multilineTextAlignment(.center)

            HStack {
                Button(strings.cancel, action: onCancel)
                Button(strings.confirm, action: confirm)
                    .disabled(captured?.isValid != true)
            }
        }
        .padding(20)
        .frame(width: 320)
        .onAppear(perform: startMonitoring)
        .onDisappear(perform: stopMonitoring)
    }

    private var preview: String {
        if let captured { return captured.displayString }
        return heldModifiers.isEmpty ? strings.recorderWaiting : heldModifiers.displayString
    }

    private var isError: Bool {
        conflict || captured?.isValid == false
    }

    private var message: String {
        if conflict { return strings.recorderConflict }
        if captured?.isValid == false { return strings.recorderNeedsModifier }
        return strings.recorderHint
    }

    private func confirm() {
        guard let captured, captured.isValid else { return }
        conflict = !onConfirm(captured)
    }

    /// 입력 창이 키 입력을 모두 받아 다른 컨트롤이나 단축키로 새지 않게 한다
    private func startMonitoring() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            if event.type == .flagsChanged {
                heldModifiers = KeyModifiers(event.modifierFlags)
                return event
            }
            handleKeyDown(event)
            return nil
        }
    }

    private func stopMonitoring() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }

    private func handleKeyDown(_ event: NSEvent) {
        if KeyModifiers(event.modifierFlags).isEmpty {
            switch event.keyCode {
            case Self.escapeKeyCode:
                onCancel()
                return
            case Self.returnKeyCode where captured?.isValid == true:
                confirm()
                return
            default:
                break
            }
        }
        captured = KeyCombo(event: event)
        conflict = false
    }
}
