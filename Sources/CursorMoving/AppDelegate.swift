import AppKit
import Combine
import CursorMovingCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private static let toggleHotKeyID: UInt32 = 1

    private let settings = Settings()
    private let jiggler = Jiggler()

    private var statusItem: NSStatusItem!
    private var hotKeyFailed = false
    private var subscriptions: Set<AnyCancellable> = []
    private lazy var preferences = PreferencesWindowController(
        settings: settings,
        shortcuts: ShortcutActions(
            suspend: { HotKeyManager.shared.unregister(id: Self.toggleHotKeyID) },
            resume: { [weak self] in self?.registerToggleHotKey() },
            apply: { [weak self] combo in self?.applyToggleHotKey(combo) ?? false }
        )
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        settings.$idleThreshold.sink { [jiggler] in jiggler.idleThreshold = $0 }.store(in: &subscriptions)
        settings.$shape.sink { [jiggler] in jiggler.shape = $0 }.store(in: &subscriptions)
        // @Published 는 값이 바뀌기 직전에 알리므로 다음 런루프에서 새 언어로 갱신한다
        settings.$language
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refreshStatusIcon() }
            .store(in: &subscriptions)

        registerToggleHotKey()
        Permissions.promptAccessibilityIfNeeded()
        if settings.startMovingOnLaunch, AXIsProcessTrusted() {
            jiggler.start()
        }
        refreshStatusIcon()
    }

    // MARK: - 단축키

    private func registerToggleHotKey() {
        hotKeyFailed = !HotKeyManager.shared.register(id: Self.toggleHotKeyID, combo: settings.toggleHotKey) { [weak self] in
            self?.toggleJiggle()
        }
    }

    private func applyToggleHotKey(_ combo: KeyCombo) -> Bool {
        guard HotKeyManager.shared.register(id: Self.toggleHotKeyID, combo: combo, handler: { [weak self] in
            self?.toggleJiggle()
        }) else { return false }
        settings.toggleHotKey = combo
        hotKeyFailed = false
        return true
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
            menu.addItem(.disabled(strings.hotKeyConflict(settings.toggleHotKey.displayString)))
        }
        if !AXIsProcessTrusted() {
            menu.addItem(ClosureMenuItem(title: strings.grantAccessibility) {
                Permissions.openAccessibilitySettings()
            })
        }
        menu.addItem(.separator())

        menu.addItem(ClosureMenuItem(
            title: jiggler.isRunning ? strings.turnOff : strings.turnOn,
            key: settings.toggleHotKey.menuKeyEquivalent,
            modifiers: settings.toggleHotKey.menuModifiers
        ) { [weak self] in self?.toggleJiggle() })
        menu.addItem(submenu(strings.idleMenu(settings.idleThreshold), items: Settings.idleThresholdOptions.map { seconds in
            ClosureMenuItem(title: strings.duration(seconds), checked: settings.idleThreshold == seconds) { [weak self] in
                self?.settings.idleThreshold = seconds
            }
        }))
        menu.addItem(submenu(strings.shapeMenu(settings.shape), items: JiggleShape.allCases.map { shape in
            ClosureMenuItem(title: strings.shape(shape), checked: settings.shape == shape) { [weak self] in
                self?.settings.shape = shape
            }
        }))
        menu.addItem(.separator())

        menu.addItem(ClosureMenuItem(title: strings.settingsMenu, key: ",", modifiers: .command) { [weak self] in
            self?.preferences.show()
        })
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
