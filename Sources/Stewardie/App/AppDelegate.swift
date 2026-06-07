import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = MenuBarItemStore()
    private var controlItem: ControlItem?
    private var statusItem: NSStatusItem?
    private var controlPanelController: NSWindowController?
    private var keyEventMonitor: Any?

    // MARK: - App Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureApplicationMenu()
        configureKeyboardShortcuts()
        configureStatusItem()
        controlItem = ControlItem(autosaveName: "Stewardie.HiddenSectionDivider")
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
            controlItem?.toggle()
        }
    }

    private func showStatusMenu() {
        guard let button = statusItem?.button else { return }
        let menu = makeStatusMenu()
        menu.popUp(
            positioning: nil,
            at: NSPoint(x: 0, y: button.bounds.height + 5),
            in: button
        )
    }

    // MARK: - Status Menu

    private func makeStatusMenu() -> NSMenu {
        let menu = NSMenu()

        let isHiding = controlItem?.isHiding ?? false

        // 토글 항목
        let toggleItem = NSMenuItem(
            title: isHiding ? "숨긴 항목 보이기" : "항목 숨기기",
            action: #selector(toggleHiddenSection),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        // 관리 패널
        let panelItem = NSMenuItem(
            title: "관리 패널 열기",
            action: #selector(openControlPanel),
            keyEquivalent: ","
        )
        panelItem.target = self
        menu.addItem(panelItem)

        // 새로고침
        let refreshItem = NSMenuItem(
            title: "메뉴바 항목 새로고침",
            action: #selector(refreshItems),
            keyEquivalent: "r"
        )
        refreshItem.target = self
        menu.addItem(refreshItem)

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

    @objc private func toggleHiddenSection() {
        controlItem?.toggle()
    }

    @objc private func openControlPanel() {
        showControlPanel()
    }

    @objc private func refreshItems() {
        store.refreshAvailableItems()
        showControlPanel()
    }

    @objc private func quitStewardie() {
        NSApp.terminate(nil)
    }

    @objc private func closeKeyWindow() {
        if let window = NSApp.keyWindow ?? controlPanelController?.window {
            window.performClose(nil)
        }
    }

    // MARK: - Control Panel

    private func showControlPanel() {
        store.refreshAccessibilityPermission()

        if controlPanelController == nil {
            let rootView = StewardieControlPanel(store: store)
            let hostingController = NSHostingController(rootView: rootView)
            let window = NSWindow(contentViewController: hostingController)

            window.title = StewardieConstants.appName
            window.setContentSize(NSSize(width: 760, height: 540))
            window.minSize = NSSize(width: 640, height: 460)
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.isReleasedWhenClosed = false
            window.center()

            controlPanelController = NSWindowController(window: window)
        }

        NSApp.activate(ignoringOtherApps: true)
        controlPanelController?.showWindow(nil)
        controlPanelController?.window?.makeKeyAndOrderFront(nil)
    }
}
