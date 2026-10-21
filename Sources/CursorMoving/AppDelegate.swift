import AppKit
import Carbon
import CursorMovingCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private enum HotKey {
        static let modifiers = controlKey | optionKey | cmdKey
        static let menuModifiers: NSEvent.ModifierFlags = [.control, .option, .command]
        static let toggleJiggle: UInt32 = 1
        static let toggleJiggleLabel = "⌃⌥⌘M"
    }

    private let settings = Settings()
    private let jiggler = Jiggler()

    private var statusItem: NSStatusItem!
    private var hotKeyFailed = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        jiggler.idleThreshold = settings.idleThreshold
        jiggler.shape = settings.shape

        hotKeyFailed = !HotKeyManager.shared.register(
            id: HotKey.toggleJiggle,
            keyCode: kVK_ANSI_M,
            modifiers: HotKey.modifiers
        ) { [weak self] in self?.toggleJiggle() }
        Permissions.promptAccessibilityIfNeeded()
        refreshStatusIcon()
    }

    // MARK: - 동작

    private func toggleJiggle() {
        if jiggler.isRunning {
            jiggler.stop()
        } else {
            guard Permissions.ensureAccessibility() else { return }
            jiggler.start()
        }
        refreshStatusIcon()
    }

    // MARK: - 상태 아이콘

    private func refreshStatusIcon() {
        guard let button = statusItem?.button else { return }
        let symbol: String
        let tint: NSColor?
        let tooltip: String

        if jiggler.isRunning {
            (symbol, tint, tooltip) = ("cursorarrow.motionlines", .systemGreen, "커서 이동 켜짐")
        } else {
            (symbol, tint, tooltip) = ("cursorarrow", nil, "커서 이동 꺼짐")
        }

        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: tooltip)
        image?.isTemplate = true
        button.image = image
        button.contentTintColor = tint
        button.appearsDisabled = !jiggler.isRunning
        button.toolTip = tooltip
    }

    // MARK: - 메뉴

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        menu.addItem(.disabled(statusText))
        if hotKeyFailed {
            menu.addItem(.disabled("⚠️ 단축키 충돌: \(HotKey.toggleJiggleLabel)"))
        }
        if !AXIsProcessTrusted() {
            menu.addItem(ClosureMenuItem(title: "⚠️ 손쉬운 사용 권한 허용하기…") {
                Permissions.openAccessibilitySettings()
            })
        }
        menu.addItem(.separator())

        menu.addItem(ClosureMenuItem(
            title: jiggler.isRunning ? "커서 이동 끄기" : "커서 이동 켜기",
            key: "m",
            modifiers: HotKey.menuModifiers
        ) { [weak self] in self?.toggleJiggle() })
        menu.addItem(submenu("유휴 감지: \(Settings.durationTitle(settings.idleThreshold))", items: Settings.idleThresholdOptions.map { seconds in
            ClosureMenuItem(title: Settings.durationTitle(seconds), checked: settings.idleThreshold == seconds) { [weak self] in
                self?.settings.idleThreshold = seconds
                self?.jiggler.idleThreshold = seconds
            }
        }))
        menu.addItem(submenu("모양: \(settings.shape.title)", items: JiggleShape.allCases.map { shape in
            ClosureMenuItem(title: shape.title, checked: settings.shape == shape) { [weak self] in
                self?.settings.shape = shape
                self?.jiggler.shape = shape
            }
        }))
        menu.addItem(.separator())

        menu.addItem(ClosureMenuItem(title: "종료", key: "q", modifiers: .command) {
            NSApp.terminate(nil)
        })
    }

    private var statusText: String {
        guard jiggler.isRunning else { return "커서 이동 꺼짐" }
        return "커서 이동 켜짐 · \(Settings.durationTitle(settings.idleThreshold)) 유휴 시 \(settings.shape.title)"
    }

    private func submenu(_ title: String, items: [NSMenuItem]) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: title)
        items.forEach(submenu.addItem)
        item.submenu = submenu
        return item
    }
}

/// 클로저로 동작하는 메뉴 항목
final class ClosureMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(
        title: String,
        key: String = "",
        modifiers: NSEvent.ModifierFlags = [],
        checked: Bool = false,
        handler: @escaping () -> Void
    ) {
        self.handler = handler
        super.init(title: title, action: #selector(fire), keyEquivalent: key)
        keyEquivalentModifierMask = modifiers
        state = checked ? .on : .off
        target = self
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    @objc private func fire() {
        handler()
    }
}

private extension NSMenuItem {
    static func disabled(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }
}
