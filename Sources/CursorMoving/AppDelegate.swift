import AppKit
import Carbon
import CursorMovingCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private enum HotKey {
        static let modifiers = controlKey | optionKey | cmdKey
        static let menuModifiers: NSEvent.ModifierFlags = [.control, .option, .command]
        static let toggleJiggle: UInt32 = 1
        static let toggleRecording: UInt32 = 2
        static let togglePlayback: UInt32 = 3
    }

    private let settings = Settings()
    private let jiggler = Jiggler()
    private let recorder = EventRecorder()
    private let player = Player()
    private let store = RecordingStore()

    private var statusItem: NSStatusItem!
    private var builder: RecordingBuilder?
    private var recordings: [Recording] = []
    private var failedHotKeys: [String] = []

    private var isRecording: Bool {
        builder != nil
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        jiggler.interval = settings.interval
        jiggler.mode = settings.mode
        jiggler.onlyWhenIdle = settings.onlyWhenIdle
        jiggler.shouldSkip = { [weak self] in
            guard let self else { return true }
            return self.isRecording || self.player.isPlaying
        }

        recorder.onEvent = { [weak self] action, point, clickCount, timestamp in
            self?.builder?.append(action, at: point, clickCount: clickCount, timestamp: timestamp)
        }

        recordings = store.loadAll()
        registerHotKeys()
        Permissions.promptAccessibilityIfNeeded()
        refreshStatusIcon()
    }

    // MARK: - 단축키

    private func registerHotKeys() {
        let hotKeys: [(UInt32, Int, String, () -> Void)] = [
            (HotKey.toggleJiggle, kVK_ANSI_M, "⌃⌥⌘M", { [weak self] in self?.toggleJiggle() }),
            (HotKey.toggleRecording, kVK_ANSI_R, "⌃⌥⌘R", { [weak self] in self?.toggleRecording(fromMenu: false) }),
            (HotKey.togglePlayback, kVK_ANSI_P, "⌃⌥⌘P", { [weak self] in self?.togglePlayback() }),
        ]
        for (id, keyCode, label, handler) in hotKeys {
            let registered = HotKeyManager.shared.register(
                id: id,
                keyCode: keyCode,
                modifiers: HotKey.modifiers,
                handler: handler
            )
            if !registered { failedHotKeys.append(label) }
        }
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

    private func toggleRecording(fromMenu: Bool) {
        if var builder {
            recorder.stop()
            if !fromMenu { builder.clearMenuMark() }
            self.builder = nil
            saveRecording(from: builder)
        } else {
            guard Permissions.ensureInputMonitoring() else { return }
            player.stop()
            guard recorder.start() else {
                Permissions.showInputMonitoringAlert()
                return
            }
            builder = RecordingBuilder(includesMoves: settings.recordMoves)
        }
        refreshStatusIcon()
    }

    private func saveRecording(from builder: RecordingBuilder) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let recording = builder.build(name: "녹화 \(formatter.string(from: Date()))")
        guard !recording.events.isEmpty else { return }
        do {
            try store.save(recording)
            recordings.insert(recording, at: 0)
        } catch {
            Permissions.showAlert(title: "녹화 저장 실패", message: error.localizedDescription)
        }
    }

    private func togglePlayback() {
        if player.isPlaying {
            player.stop()
            refreshStatusIcon()
        } else if let latest = recordings.first {
            play(latest)
        }
    }

    private func play(_ recording: Recording) {
        guard !isRecording, Permissions.ensureAccessibility() else { return }
        player.play(recording, loop: settings.loopPlayback) { [weak self] in
            self?.refreshStatusIcon()
        }
        refreshStatusIcon()
    }

    private func delete(_ recording: Recording) {
        do {
            try store.delete(recording)
            recordings.removeAll { $0.id == recording.id }
        } catch {
            Permissions.showAlert(title: "녹화 삭제 실패", message: error.localizedDescription)
        }
    }

    // MARK: - 상태 아이콘

    private func refreshStatusIcon() {
        guard let button = statusItem?.button else { return }
        let symbol: String
        let tint: NSColor?
        let tooltip: String

        if isRecording {
            (symbol, tint, tooltip) = ("record.circle.fill", .systemRed, "녹화 중 (⌃⌥⌘R 로 중지)")
        } else if player.isPlaying {
            (symbol, tint, tooltip) = ("play.circle.fill", .systemBlue, "재생 중 (⌃⌥⌘P 로 중지)")
        } else if jiggler.isRunning {
            (symbol, tint, tooltip) = ("cursorarrow.motionlines", .systemGreen, "커서 이동 켜짐")
        } else {
            (symbol, tint, tooltip) = ("cursorarrow", nil, "커서 이동 꺼짐")
        }

        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: tooltip)
        image?.isTemplate = true
        button.image = image
        button.contentTintColor = tint
        button.appearsDisabled = !(isRecording || player.isPlaying || jiggler.isRunning)
        button.toolTip = tooltip
    }

    // MARK: - 메뉴

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        menu.addItem(.disabled(statusText))
        if !failedHotKeys.isEmpty {
            menu.addItem(.disabled("⚠️ 단축키 충돌: \(failedHotKeys.joined(separator: ", "))"))
        }
        if !AXIsProcessTrusted() {
            menu.addItem(ClosureMenuItem(title: "⚠️ 손쉬운 사용 권한 허용하기…") {
                Permissions.openAccessibilitySettings()
            })
        }
        menu.addItem(.separator())

        // 커서 이동
        menu.addItem(ClosureMenuItem(
            title: jiggler.isRunning ? "커서 이동 끄기" : "커서 이동 켜기",
            key: "m",
            modifiers: HotKey.menuModifiers
        ) { [weak self] in self?.toggleJiggle() })
        menu.addItem(submenu("이동 주기: \(Settings.intervalTitle(settings.interval))", items: Settings.intervalOptions.map { seconds in
            ClosureMenuItem(title: Settings.intervalTitle(seconds), checked: settings.interval == seconds) { [weak self] in
                self?.settings.interval = seconds
                self?.jiggler.interval = seconds
            }
        }))
        menu.addItem(submenu("이동 방식", items: JiggleMode.allCases.map { mode in
            ClosureMenuItem(title: mode.title, checked: settings.mode == mode) { [weak self] in
                self?.settings.mode = mode
                self?.jiggler.mode = mode
            }
        }))
        menu.addItem(ClosureMenuItem(title: "내가 사용 중일 땐 건너뛰기", checked: settings.onlyWhenIdle) { [weak self] in
            guard let self else { return }
            self.settings.onlyWhenIdle.toggle()
            self.jiggler.onlyWhenIdle = self.settings.onlyWhenIdle
        })
        menu.addItem(.separator())

        // 녹화 / 재생
        menu.addItem(ClosureMenuItem(
            title: isRecording ? "녹화 중지" : "클릭 녹화 시작",
            key: "r",
            modifiers: HotKey.menuModifiers
        ) { [weak self] in self?.toggleRecording(fromMenu: true) })
        let recordMovesItem = ClosureMenuItem(title: "이동 경로도 녹화", checked: settings.recordMoves) { [weak self] in
            self?.settings.recordMoves.toggle()
        }
        recordMovesItem.isEnabled = !isRecording
        menu.addItem(recordMovesItem)

        let playItem = ClosureMenuItem(
            title: player.isPlaying ? "재생 중지" : "최근 녹화 재생",
            key: "p",
            modifiers: HotKey.menuModifiers
        ) { [weak self] in self?.togglePlayback() }
        playItem.isEnabled = player.isPlaying || (!recordings.isEmpty && !isRecording)
        menu.addItem(playItem)
        menu.addItem(ClosureMenuItem(title: "반복 재생", checked: settings.loopPlayback) { [weak self] in
            self?.settings.loopPlayback.toggle()
        })
        menu.addItem(submenu("녹화 목록 (\(recordings.count))", items: recordingItems))
        menu.addItem(.separator())

        menu.addItem(ClosureMenuItem(title: "종료", key: "q", modifiers: .command) {
            NSApp.terminate(nil)
        })
    }

    func menuWillOpen(_ menu: NSMenu) {
        builder?.markMenuOpened()
    }

    func menuDidClose(_ menu: NSMenu) {
        builder?.clearMenuMark()
    }

    private var statusText: String {
        if let builder {
            return "● 녹화 중 — 이벤트 \(builder.events.count)개"
        }
        if player.isPlaying {
            return "▶︎ 재생 중"
        }
        if jiggler.isRunning {
            return "커서 이동 켜짐 · \(Settings.intervalTitle(settings.interval))마다"
        }
        return "커서 이동 꺼짐"
    }

    private var recordingItems: [NSMenuItem] {
        var items: [NSMenuItem] = recordings.map { recording in
            let title = "\(recording.name) · 클릭 \(recording.clickCount)회 · \(String(format: "%.1f", recording.duration))초"
            return submenu(title, items: [
                ClosureMenuItem(title: "재생") { [weak self] in self?.play(recording) },
                ClosureMenuItem(title: "삭제") { [weak self] in self?.delete(recording) },
            ])
        }
        if items.isEmpty {
            items.append(.disabled("녹화 없음"))
        }
        items.append(.separator())
        items.append(ClosureMenuItem(title: "녹화 폴더 열기") { [store] in
            try? FileManager.default.createDirectory(at: store.directory, withIntermediateDirectories: true)
            NSWorkspace.shared.open(store.directory)
        })
        return items
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
