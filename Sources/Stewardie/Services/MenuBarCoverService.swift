import AppKit
import Combine

// 숨김으로 지정된 메뉴바 항목 위에 메뉴바 배경색과 동일한 NSPanel을 올려서 안 보이게 한다.
// 항목은 실제로 제거되지 않으며, Stewardie 숨김 보관함에서 계속 접근 가능하다.
@MainActor
final class MenuBarCoverService {

    private var panel: NSPanel?
    private var cancellables = Set<AnyCancellable>()

    init(store: MenuBarItemStore) {
        store.$items
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] items in
                self?.update(items: items)
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.update(items: store.items)
            }
            .store(in: &cancellables)

        // 라이트/다크 모드 전환 감지
        DistributedNotificationCenter.default()
            .publisher(for: NSNotification.Name("AppleInterfaceThemeChangedNotification"))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.panel?.backgroundColor = Self.menuBarColor()
                self?.update(items: store.items)
            }
            .store(in: &cancellables)
    }

    func close() {
        panel?.close()
        panel = nil
    }

    // MARK: - Private

    private func update(items: [MenuBarItem]) {
        let hiddenItems = items.filter { $0.visibility == .hidden }
        let rects = hiddenItems
            .compactMap { Self.parseAXFrame($0.frameDescription) }
            .map(Self.toAppKitRect)

        guard !rects.isEmpty else {
            panel?.orderOut(nil)
            return
        }

        // 숨길 항목들을 하나의 사각형으로 합침
        let union = rects.dropFirst().reduce(rects[0]) { $0.union($1) }

        if panel == nil {
            panel = Self.makePanel()
        }

        panel?.setFrame(union, display: true, animate: false)
        panel?.orderFrontRegardless()
    }

    // MARK: - Panel factory

    private static func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        panel.backgroundColor = NSColor.clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.isReleasedWhenClosed = false

        // 마우스 이벤트를 차단하기 위해 투명 NSView 추가
        let blockingView = NSView()
        blockingView.wantsLayer = true
        panel.contentView = blockingView

        return panel
    }

    // MARK: - Helpers

    // 메뉴바 배경색 근사치 (라이트/다크 모드 대응)
    static func menuBarColor() -> NSColor {
        let isDark = NSApp.effectiveAppearance
            .bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        return isDark
            ? NSColor(srgbRed: 0.196, green: 0.196, blue: 0.196, alpha: 1.0)
            : NSColor(srgbRed: 0.937, green: 0.937, blue: 0.937, alpha: 1.0)
    }

    // "x:N y:M w:W h:H" 형식 파싱
    static func parseAXFrame(_ description: String?) -> CGRect? {
        guard let description else { return nil }
        var v: [String: CGFloat] = [:]
        for part in description.split(separator: " ") {
            let kv = part.split(separator: ":", maxSplits: 1)
            if kv.count == 2, let n = Double(kv[1]) {
                v[String(kv[0])] = CGFloat(n)
            }
        }
        guard let x = v["x"], let y = v["y"], let w = v["w"], let h = v["h"] else {
            return nil
        }
        return CGRect(x: x, y: y, width: w, height: h)
    }

    // AX 좌표 → AppKit 좌표: 메뉴바는 항상 화면 상단에 고정
    // AX y=0은 화면 상단, AppKit에서도 y=0은 화면 상단 (메뉴바 기준)
    // 메뉴바 높이는 보통 28픽셀
    static func toAppKitRect(_ axRect: CGRect) -> NSRect {
        let menuBarHeight: CGFloat = 28
        return NSRect(
            x: axRect.origin.x,
            y: 0,
            width: axRect.width,
            height: menuBarHeight
        )
    }
}
