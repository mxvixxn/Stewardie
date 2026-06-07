import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let store = MenuBarItemStore()
    private var coverService: MenuBarCoverService?
    private var statusItem: NSStatusItem?
    private var controlPanelController: NSWindowController?
    private var keyEventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureApplicationMenu()
        configureKeyboardShortcuts()
        configureStatusItem()
        coverService = MenuBarCoverService(store: store)
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        store.refreshAccessibilityPermission()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let keyEventMonitor {
            NSEvent.removeMonitor(keyEventMonitor)
        }
        coverService?.close()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

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

    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: 24)

        if let button = statusItem.button {
            button.toolTip = StewardieConstants.appName
            button.title = ""
            button.image = StewardieMenuBarIcon.image()
            button.imagePosition = .imageOnly
        }

        statusItem.menu = makeMenu()
        self.statusItem = statusItem
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        populateMenu(menu)
        return menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        populateMenu(menu)
    }

    private func populateMenu(_ menu: NSMenu) {
        menu.removeAllItems()

        let hiddenMenuItem = NSMenuItem(title: "숨김 보관함", action: nil, keyEquivalent: "")
        hiddenMenuItem.submenu = makeHiddenItemsMenu()
        menu.addItem(hiddenMenuItem)

        menu.addItem(NSMenuItem(
            title: "모두 표시 목록으로",
            action: #selector(revealHiddenItems),
            keyEquivalent: ""
        ))

        menu.addItem(NSMenuItem(
            title: "관리 패널 열기",
            action: #selector(openControlPanel),
            keyEquivalent: ","
        ))

        menu.addItem(NSMenuItem(
            title: "항목 새로고침",
            action: #selector(refreshItems),
            keyEquivalent: "r"
        ))

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(
            title: "Stewardie 종료",
            action: #selector(quitStewardie),
            keyEquivalent: "q"
        ))

        for item in menu.items {
            item.target = self
        }
    }

    private func makeHiddenItemsMenu() -> NSMenu {
        let menu = NSMenu()
        let hiddenItems = store.hiddenItems

        guard !hiddenItems.isEmpty else {
            let emptyItem = NSMenuItem(title: "숨김 항목 없음", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
            return menu
        }

        for item in hiddenItems {
            let menuItem = NSMenuItem(
                title: item.title,
                action: #selector(activateMenuBarItemFromMenu(_:)),
                keyEquivalent: ""
            )
            menuItem.target = self
            menuItem.representedObject = item.id.uuidString
            menuItem.isEnabled = item.discoverySource == "Accessibility"
            menuItem.toolTip = item.detailText.isEmpty ? nil : item.detailText
            menu.addItem(menuItem)
        }

        return menu
    }

    @objc private func activateMenuBarItemFromMenu(_ sender: NSMenuItem) {
        guard
            let idString = sender.representedObject as? String,
            let id = UUID(uuidString: idString),
            let item = store.items.first(where: { $0.id == id })
        else {
            return
        }

        store.activate(item)
    }

    @objc private func revealHiddenItems() {
        store.revealHiddenItems()
        showControlPanel()
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
