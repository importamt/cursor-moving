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
            guard Permissions.ensureAccessibility(settings.strings) else { return }
            jiggler.start()
        }
        refreshStatusIcon()
    }

    // MARK: - 상태 아이콘

    private func refreshStatusIcon() {
        guard let button = statusItem?.button else { return }
        let strings = settings.strings
        let symbol: String
        let tint: NSColor?
        let tooltip: String

        if jiggler.isRunning {
            (symbol, tint, tooltip) = ("cursorarrow.motionlines", .systemGreen, strings.tooltipOn)
        } else {
            (symbol, tint, tooltip) = ("cursorarrow", nil, strings.tooltipOff)
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
        let strings = settings.strings

        menu.addItem(.disabled(
            jiggler.isRunning ? strings.statusOn(threshold: settings.idleThreshold, shape: settings.shape) : strings.statusOff
        ))
        if hotKeyFailed {
            menu.addItem(.disabled(strings.hotKeyConflict(HotKey.toggleJiggleLabel)))
        }
        if !AXIsProcessTrusted() {
            menu.addItem(ClosureMenuItem(title: strings.grantAccessibility) {
                Permissions.openAccessibilitySettings()
            })
        }
        menu.addItem(.separator())

        menu.addItem(ClosureMenuItem(
            title: jiggler.isRunning ? strings.turnOff : strings.turnOn,
            key: "m",
            modifiers: HotKey.menuModifiers
        ) { [weak self] in self?.toggleJiggle() })
        menu.addItem(submenu(strings.idleMenu(settings.idleThreshold), items: Settings.idleThresholdOptions.map { seconds in
            ClosureMenuItem(title: strings.duration(seconds), checked: settings.idleThreshold == seconds) { [weak self] in
                self?.settings.idleThreshold = seconds
                self?.jiggler.idleThreshold = seconds
            }
        }))
        menu.addItem(submenu(strings.shapeMenu(settings.shape), items: JiggleShape.allCases.map { shape in
            ClosureMenuItem(title: strings.shape(shape), checked: settings.shape == shape) { [weak self] in
                self?.settings.shape = shape
                self?.jiggler.shape = shape
            }
        }))
        menu.addItem(submenu(strings.languageMenu(settings.language), items: LanguagePreference.allCases.map { language in
            ClosureMenuItem(title: strings.languagePreference(language), checked: settings.language == language) { [weak self] in
                self?.settings.language = language
                self?.refreshStatusIcon()
            }
        }))
        menu.addItem(.separator())

        menu.addItem(ClosureMenuItem(title: strings.quit, key: "q", modifiers: .command) {
            NSApp.terminate(nil)
        })
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
