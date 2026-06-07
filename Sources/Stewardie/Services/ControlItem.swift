import AppKit

/// 메뉴바 섹션 구분자.
///
/// `NSStatusItem`의 `length`를 10,000으로 확장하면
/// 이 아이템 왼쪽에 있는 메뉴바 아이콘들이 화면 밖으로 밀려나 숨겨진다.
/// 다시 원래 크기로 줄이면 아이콘들이 되돌아온다.
///
/// 사용자가 ⌘-드래그로 메뉴바 아이콘을 이 구분자의 왼쪽에 배치하면
/// Stewardie 아이콘 클릭 한 번으로 해당 아이콘들을 숨기거나 보여줄 수 있다.
@MainActor
final class ControlItem {

    // MARK: - Types

    enum State: String {
        case showItems
        case hideItems
    }

    // MARK: - Constants

    private enum Length {
        static let standard: CGFloat = 13
        static let expanded: CGFloat = 10_000
    }

    private static let stateKey = "Stewardie.ControlItem.State"

    // MARK: - Properties

    let statusItem: NSStatusItem

    private(set) var state: State {
        didSet {
            applyState()
            persistState()
        }
    }

    // MARK: - Initialization

    init(autosaveName: String) {
        let saved = UserDefaults.standard.string(forKey: Self.stateKey)
        self.state = State(rawValue: saved ?? "") ?? .showItems

        let initialLength = (state == .hideItems) ? Length.expanded : Length.standard
        self.statusItem = NSStatusBar.system.statusItem(withLength: initialLength)
        self.statusItem.autosaveName = autosaveName

        applyState()
    }

    // MARK: - Public

    var isHiding: Bool { state == .hideItems }

    func toggle() {
        state = isHiding ? .showItems : .hideItems
    }

    func show() {
        guard isHiding else { return }
        state = .showItems
    }

    func hide() {
        guard !isHiding else { return }
        state = .hideItems
    }

    // MARK: - Private

    private func applyState() {
        switch state {
        case .showItems:
            statusItem.length = Length.standard
            updateButton(dividerVisible: true)
        case .hideItems:
            statusItem.length = Length.expanded
            updateButton(dividerVisible: false)
        }
    }

    private func updateButton(dividerVisible: Bool) {
        guard let button = statusItem.button else { return }
        if dividerVisible {
            button.image = Self.makeDividerImage()
            button.imagePosition = .imageOnly
        } else {
            // 확장 상태에서는 대부분 화면 밖이므로 표시 불필요
            button.image = nil
            button.title = ""
        }
    }

    private func persistState() {
        UserDefaults.standard.set(state.rawValue, forKey: Self.stateKey)
    }

    // MARK: - Divider Image

    /// 얇은 세로 구분선 이미지 (template 모드로 라이트/다크 자동 대응)
    private static func makeDividerImage() -> NSImage {
        let size = NSSize(width: 6, height: 16)
        let image = NSImage(size: size, flipped: false) { rect in
            let lineRect = NSRect(
                x: (rect.width - 1) / 2,
                y: 3,
                width: 1,
                height: rect.height - 6
            )
            NSColor.tertiaryLabelColor.setFill()
            NSBezierPath(roundedRect: lineRect, xRadius: 0.5, yRadius: 0.5).fill()
            return true
        }
        image.isTemplate = true
        return image
    }
}
