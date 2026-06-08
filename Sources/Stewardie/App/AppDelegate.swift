import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = MenuBarItemStore()
    private let updater = UpdateService()
    private var divider: StewardieDivider?
    private var statusItem: NSStatusItem?
    private var archiveWindowController: NSWindowController?
    private var settingsWindowController: NSWindowController?
    private var keyEventMonitor: Any?

    // MARK: - App Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureApplicationMenu()
        configureKeyboardShortcuts()
        configureStatusItem()
        divider = StewardieDivider(autosaveName: "Stewardie.HiddenSectionDivider")

        // 실행 시 조용히 업데이트 확인 (결과는 설정 화면 / 우클릭 메뉴에 반영)
        Task { await updater.checkForUpdates() }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        store.refreshAccessibilityPermission()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let keyEventMonitor {
            NSEvent.removeMonitor(keyEventMonitor)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - Application Menu (⌘Q, ⌘W)

    private func configureApplicationMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(
            title: "Stewardie 종료",
            action: #selector(quitStewardie),
            keyEquivalent: "q"
        ))
        appMenu.items.forEach { $0.target = self }
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        let closeItem = NSMenuItem(
            title: "창 닫기",
            action: #selector(closeKeyWindow),
            keyEquivalent: "w"
        )
        closeItem.target = self
        windowMenu.addItem(closeItem)
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApp.mainMenu = mainMenu
    }

    // MARK: - Keyboard Shortcuts

    private func configureKeyboardShortcuts() {
        keyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard
                let self,
                event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command),
                let key = event.charactersIgnoringModifiers?.lowercased()
            else {
                return event
            }

            switch key {
            case "w":
                closeKeyWindow()
                return nil
            case "q":
                quitStewardie()
                return nil
            default:
                return event
            }
        }
    }

    // MARK: - Status Item (Menu Bar Icon)

    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: 24)
        statusItem.autosaveName = "Stewardie.MainIcon"

        if let button = statusItem.button {
            button.toolTip = StewardieConstants.appName
            button.image = StewardieMenuBarIcon.image()
            button.imagePosition = .imageOnly
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // menu는 설정하지 않음 — 클릭 동작을 직접 제어
        self.statusItem = statusItem
    }

    // MARK: - Click Handling

    /// 좌클릭 → 숨긴 항목 토글
    /// 우클릭 / ⌥클릭 / ⌃클릭 → 메뉴 표시
    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp
            || event.modifierFlags.contains(.option)
            || event.modifierFlags.contains(.control)
        {
            showStatusMenu()
        } else {
            divider?.toggle()
        }
    }

    /// 메뉴를 직접 좌표 지정으로 popUp하면(menu.popUp(positioning:at:in:))
    /// 메뉴가 화면 경계와 겹치면서 첫 항목이 스크롤 화살표 뒤로 가려지는
    /// 현상이 있었음 (마우스를 올리면 그제서야 스크롤되어 나타남).
    /// `statusItem.menu`에 메뉴를 임시로 연결하고 표준 클릭 경로로 띄우면
    /// AppKit이 메뉴바 기준으로 올바른 위치를 계산해 이 문제가 사라진다.
    private func showStatusMenu() {
        guard let statusItem else { return }
        let menu = makeStatusMenu()
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        // performClick은 동기적으로 메뉴를 띄우고 닫힐 때까지 블록되므로,
        // 닫힌 직후 menu를 해제해 좌클릭이 다시 toggle 동작을 타도록 되돌린다.
        statusItem.menu = nil
    }

    // MARK: - Status Menu

    private func makeStatusMenu() -> NSMenu {
        let menu = NSMenu()

        // 새 버전 알림 (있을 때만 맨 위에 표시)
        if let update = updater.availableUpdate {
            let updateItem = NSMenuItem(
                title: "새 버전 v\(update.version) 다운로드",
                action: #selector(openDownloadPage),
                keyEquivalent: ""
            )
            updateItem.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "업데이트")
            updateItem.target = self
            menu.addItem(updateItem)
            menu.addItem(.separator())
        }

        // 보관함
        let archiveItem = NSMenuItem(
            title: "보관함 열기",
            action: #selector(openArchive),
            keyEquivalent: "a"
        )
        archiveItem.image = NSImage(systemSymbolName: "archivebox", accessibilityDescription: "보관함")
        archiveItem.target = self
        menu.addItem(archiveItem)

        // 설정
        let settingsItem = NSMenuItem(
            title: "설정 열기",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "설정")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        // 종료
        let quitItem = NSMenuItem(
            title: "Stewardie 종료",
            action: #selector(quitStewardie),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    // MARK: - Actions

    @objc private func openDownloadPage() {
        if let update = updater.availableUpdate {
            NSWorkspace.shared.open(update.url)
        }
    }

    @objc private func openArchive() {
        showArchive()
    }

    @objc private func openSettings() {
        showSettings()
    }

    @objc private func quitStewardie() {
        NSApp.terminate(nil)
    }

    @objc private func closeKeyWindow() {
        if let window = NSApp.keyWindow {
            window.performClose(nil)
        }
    }

    // MARK: - Archive Window

    private func showArchive() {
        guard let divider else { return }

        if archiveWindowController == nil {
            let rootView = StewardieArchiveView(divider: divider, store: store)
            let hostingController = NSHostingController(rootView: rootView)
            let window = NSWindow(contentViewController: hostingController)

            window.title = "보관함"
            window.setContentSize(NSSize(width: 620, height: 480))
            window.minSize = NSSize(width: 560, height: 420)
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.isReleasedWhenClosed = false
            window.center()

            archiveWindowController = NSWindowController(window: window)
        }

        presentWindow(of: archiveWindowController)
    }

    // MARK: - Settings Window

    private func showSettings() {
        if settingsWindowController == nil {
            let rootView = StewardieSettingsView(store: store, updater: updater)
            let hostingController = NSHostingController(rootView: rootView)
            let window = NSWindow(contentViewController: hostingController)

            window.title = "설정"
            window.setContentSize(NSSize(width: 560, height: 460))
            window.minSize = NSSize(width: 520, height: 420)
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.isReleasedWhenClosed = false
            window.center()

            settingsWindowController = NSWindowController(window: window)
        }

        presentWindow(of: settingsWindowController)
    }

    private func presentWindow(of controller: NSWindowController?) {
        NSApp.activate(ignoringOtherApps: true)
        controller?.showWindow(nil)
        controller?.window?.makeKeyAndOrderFront(nil)
    }
}
