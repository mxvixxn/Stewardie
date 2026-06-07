import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

protocol MenuBarIconProviding {
    var supportsDiscovery: Bool { get }
    var supportsLiveControl: Bool { get }

    func availableItems() throws -> [MenuBarItem]
    func press(_ item: MenuBarItem) throws

    /// 현재 화면상에서 `boundaryX`보다 왼쪽(메뉴바 영역)에 위치한 항목들을 찾는다.
    /// Stewardie의 구분선이 확장되어 항목들을 화면 밖으로 밀어냈을 때,
    /// "지금 보관함에 들어 있는 항목"을 보여주기 위한 읽기 전용 탐색이다.
    func hiddenItems(leftOf boundaryX: CGFloat) throws -> [MenuBarItem]
}

enum MenuBarIconServiceError: LocalizedError {
    case accessibilityPermissionMissing
    case privateAPINotConnected
    case noItemsFound
    case itemNotActionable
    case itemNotFound
    case actionNotAvailable
    case actionFailed(String)

    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionMissing:
            "Accessibility 권한을 허용해야 실제 메뉴바 항목을 탐색할 수 있어요."
        case .privateAPINotConnected:
            "실제 숨김/재배치 백엔드는 아직 연결되지 않았어요."
        case .noItemsFound:
            "접근 가능한 메뉴바 항목을 찾지 못했어요."
        case .itemNotActionable:
            "이 항목은 Accessibility 조작 대상이 아니에요."
        case .itemNotFound:
            "해당 메뉴바 항목을 다시 찾지 못했어요. 새로고침 후 다시 시도해 주세요."
        case .actionNotAvailable:
            "이 항목은 Accessibility 누르기 동작을 지원하지 않아요."
        case .actionFailed(let message):
            "메뉴바 항목 누르기에 실패했어요. \(message)"
        }
    }
}

final class MenuBarIconService: MenuBarIconProviding {
    var supportsDiscovery: Bool {
        true
    }

    var supportsLiveControl: Bool {
        false
    }

    func availableItems() throws -> [MenuBarItem] {
        guard AccessibilityPermissionService.isTrusted else {
            throw MenuBarIconServiceError.accessibilityPermissionMissing
        }

        let accessibilityItems = discoverAccessibilityMenuItems()
        let windowItems = discoverMenuWindows(startingAt: accessibilityItems.count)
        let items = merge(accessibilityItems + windowItems)

        guard !items.isEmpty else {
            throw MenuBarIconServiceError.noItemsFound
        }

        return items.enumerated().map { index, item in
            var orderedItem = item
            orderedItem.order = index
            return orderedItem
        }
    }

    func hiddenItems(leftOf boundaryX: CGFloat) throws -> [MenuBarItem] {
        guard AccessibilityPermissionService.isTrusted else {
            throw MenuBarIconServiceError.accessibilityPermissionMissing
        }

        // 메뉴바 영역(화면 위쪽 ~30pt)에 있으면서, 구분선 경계보다 왼쪽에 있는
        // 항목만 골라낸다. AX는 화면 밖으로 밀려난 요소의 위치도 그대로 알려주므로
        // (렌더링 여부와 무관하게 좌표를 보고하므로) 이 방식이 성립한다.
        let menuBarYRange: ClosedRange<CGFloat> = -4...32
        let ownBundleID = Bundle.main.bundleIdentifier

        let candidateApps = NSWorkspace.shared.runningApplications.filter { app in
            guard let bundleID = app.bundleIdentifier?.lowercased(), bundleID != ownBundleID?.lowercased() else {
                return false
            }
            // 메뉴바 부가 아이콘은 보통 accessory 정책 앱이거나, 시스템 메뉴바 호스트들이 갖고 있다.
            return app.activationPolicy == .accessory
            || ["com.apple.systemuiserver", "com.apple.controlcenter"].contains(bundleID)
        }

        var results: [MenuBarItem] = []

        for app in candidateApps {
            guard results.count < 60 else { break }

            let root = AXUIElementCreateApplication(app.processIdentifier)
            var visited = Set<AXElementKey>()
            collectHiddenCandidates(
                in: root,
                app: app,
                depth: 0,
                boundaryX: boundaryX,
                yRange: menuBarYRange,
                visited: &visited,
                results: &results
            )
        }

        return merge(results).enumerated().map { index, item in
            var ordered = item
            ordered.order = index
            return ordered
        }
    }

    private func collectHiddenCandidates(
        in element: AXUIElement,
        app: NSRunningApplication,
        depth: Int,
        boundaryX: CGFloat,
        yRange: ClosedRange<CGFloat>,
        visited: inout Set<AXElementKey>,
        results: inout [MenuBarItem]
    ) {
        guard depth <= 6, results.count < 60 else {
            return
        }

        let key = AXElementKey(element)
        guard visited.insert(key).inserted else {
            return
        }

        if let position = pointAttribute(kAXPositionAttribute, from: element),
           yRange.contains(position.y),
           position.x < boundaryX,
           let candidate = menuItem(from: element, app: app, fallbackOrder: results.count) {
            results.append(candidate)
        }

        for child in childElements(of: element) {
            collectHiddenCandidates(
                in: child,
                app: app,
                depth: depth + 1,
                boundaryX: boundaryX,
                yRange: yRange,
                visited: &visited,
                results: &results
            )
        }
    }

    func press(_ item: MenuBarItem) throws {
        guard AccessibilityPermissionService.isTrusted else {
            throw MenuBarIconServiceError.accessibilityPermissionMissing
        }

        guard item.discoverySource == "Accessibility" else {
            throw MenuBarIconServiceError.itemNotActionable
        }

        guard let element = findAccessibilityElement(matching: item) else {
            throw MenuBarIconServiceError.itemNotFound
        }

        guard actionNames(of: element).contains(kAXPressAction as String) else {
            throw MenuBarIconServiceError.actionNotAvailable
        }

        let result = AXUIElementPerformAction(element, kAXPressAction as CFString)
        guard result == .success else {
            throw MenuBarIconServiceError.actionFailed(String(describing: result))
        }
    }

    private func discoverAccessibilityMenuItems() -> [MenuBarItem] {
        let targetApps = NSWorkspace.shared.runningApplications.filter { app in
            [
                "com.apple.systemuiserver",
                "com.apple.controlcenter"
            ].contains(app.bundleIdentifier?.lowercased() ?? "")
        }

        return targetApps.flatMap { app in
            discoverAccessibilityMenuItems(in: app)
        }
    }

    private func discoverAccessibilityMenuItems(in app: NSRunningApplication) -> [MenuBarItem] {
        let root = AXUIElementCreateApplication(app.processIdentifier)
        var visited = Set<AXElementKey>()
        var results: [MenuBarItem] = []
        traverse(
            root,
            app: app,
            depth: 0,
            visited: &visited,
            results: &results
        )
        return results
    }

    private func findAccessibilityElement(matching item: MenuBarItem) -> AXUIElement? {
        let targetApps = NSWorkspace.shared.runningApplications.filter { app in
            app.bundleIdentifier == item.bundleIdentifier
        }

        for app in targetApps {
            let root = AXUIElementCreateApplication(app.processIdentifier)
            var visited = Set<AXElementKey>()
            if let element = findAccessibilityElement(
                in: root,
                app: app,
                matching: item,
                depth: 0,
                visited: &visited
            ) {
                return element
            }
        }

        return nil
    }

    private func findAccessibilityElement(
        in element: AXUIElement,
        app: NSRunningApplication,
        matching item: MenuBarItem,
        depth: Int,
        visited: inout Set<AXElementKey>
    ) -> AXUIElement? {
        guard depth <= 7 else {
            return nil
        }

        let key = AXElementKey(element)
        guard visited.insert(key).inserted else {
            return nil
        }

        if let candidate = menuItem(from: element, app: app, fallbackOrder: item.order),
           candidate.identityKey == item.identityKey {
            return element
        }

        for child in childElements(of: element) {
            if let match = findAccessibilityElement(
                in: child,
                app: app,
                matching: item,
                depth: depth + 1,
                visited: &visited
            ) {
                return match
            }
        }

        return nil
    }

    private func traverse(
        _ element: AXUIElement,
        app: NSRunningApplication,
        depth: Int,
        visited: inout Set<AXElementKey>,
        results: inout [MenuBarItem]
    ) {
        guard depth <= 7, results.count < 80 else {
            return
        }

        let key = AXElementKey(element)
        guard visited.insert(key).inserted else {
            return
        }

        if let item = menuItem(from: element, app: app, fallbackOrder: results.count) {
            results.append(item)
        }

        for child in childElements(of: element) {
            traverse(
                child,
                app: app,
                depth: depth + 1,
                visited: &visited,
                results: &results
            )
        }
    }

    private func menuItem(
        from element: AXUIElement,
        app: NSRunningApplication,
        fallbackOrder: Int
    ) -> MenuBarItem? {
        let role = stringAttribute(kAXRoleAttribute, from: element) ?? ""
        let subrole = stringAttribute(kAXSubroleAttribute, from: element) ?? ""
        let title = firstMeaningfulText(from: element)
        let ownerName = app.localizedName ?? app.bundleIdentifier ?? "Unknown"
        let frame = frameDescription(from: element)

        let isMenuLike = role == kAXMenuBarItemRole as String
        || role.localizedCaseInsensitiveContains("MenuBar")
        || subrole.localizedCaseInsensitiveContains("Menu")
        || subrole.localizedCaseInsensitiveContains("Extra")

        let isStatusButton = role == kAXButtonRole as String
        && frame != nil
        && (app.bundleIdentifier?.lowercased() == "com.apple.controlcenter"
            || app.bundleIdentifier?.lowercased() == "com.apple.systemuiserver")

        guard isMenuLike || isStatusButton else {
            return nil
        }

        let resolvedTitle = title
        ?? stringAttribute("AXIdentifier", from: element)
        ?? role
        let discoveryIdentifier = [
            "AX",
            app.bundleIdentifier ?? ownerName,
            role,
            subrole,
            resolvedTitle,
            frame ?? ""
        ].joined(separator: "|")

        return MenuBarItem(
            title: resolvedTitle,
            bundleIdentifier: app.bundleIdentifier,
            discoveryIdentifier: discoveryIdentifier,
            ownerName: ownerName,
            frameDescription: frame,
            discoverySource: "Accessibility",
            isSystemItem: true,
            visibility: .visible,
            order: fallbackOrder
        )
    }

    private func childElements(of element: AXUIElement) -> [AXUIElement] {
        var children: [AXUIElement] = []

        for attribute in childAttributeNames(of: element) {
            guard let value = copyAttribute(attribute, from: element) else {
                continue
            }

            if CFGetTypeID(value) == AXUIElementGetTypeID() {
                children.append(value as! AXUIElement)
            } else if let array = value as? [Any] {
                children.append(contentsOf: array.compactMap { item in
                    guard CFGetTypeID(item as CFTypeRef) == AXUIElementGetTypeID() else {
                        return nil
                    }
                    return (item as! AXUIElement)
                })
            }
        }

        return children
    }

    private func childAttributeNames(of element: AXUIElement) -> [String] {
        var rawNames: CFArray?
        guard AXUIElementCopyAttributeNames(element, &rawNames) == .success,
              let names = rawNames as? [String] else {
            return [kAXChildrenAttribute]
        }

        return names
            .filter { name in
                name.localizedCaseInsensitiveContains("Children")
                || name.localizedCaseInsensitiveContains("MenuBar")
                || name.localizedCaseInsensitiveContains("Contents")
            }
    }

    private func discoverMenuWindows(startingAt offset: Int) -> [MenuBarItem] {
        guard let rawWindows = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return []
        }

        return rawWindows.compactMap { windowInfo in
            guard let owner = windowInfo[kCGWindowOwnerName as String] as? String,
                  ["SystemUIServer", "Control Center"].contains(owner),
                  let bounds = windowInfo[kCGWindowBounds as String] as? [String: Any],
                  let x = bounds["X"] as? CGFloat,
                  let y = bounds["Y"] as? CGFloat,
                  let width = bounds["Width"] as? CGFloat,
                  let height = bounds["Height"] as? CGFloat,
                  y <= 30,
                  height <= 60,
                  width > 2 else {
                return nil
            }

            let title = windowInfo[kCGWindowName as String] as? String
            let windowNumber = windowInfo[kCGWindowNumber as String] as? Int ?? 0
            let bundleIdentifier = owner == "Control Center" ? "com.apple.controlcenter" : "com.apple.systemuiserver"
            let frame = "x:\(Int(x)) y:\(Int(y)) w:\(Int(width)) h:\(Int(height))"

            return MenuBarItem(
                title: title?.isEmpty == false ? title! : "\(owner) 항목",
                bundleIdentifier: bundleIdentifier,
                discoveryIdentifier: "CGWindow|\(owner)|\(windowNumber)|\(frame)",
                ownerName: owner,
                frameDescription: frame,
                discoverySource: "CGWindow",
                isSystemItem: true,
                visibility: .visible,
                order: offset + windowNumber
            )
        }
    }

    private func merge(_ items: [MenuBarItem]) -> [MenuBarItem] {
        var seen = Set<String>()

        return items.filter { item in
            let key = item.identityKey
            guard !seen.contains(key) else {
                return false
            }
            seen.insert(key)
            return true
        }
    }

    private func firstMeaningfulText(from element: AXUIElement) -> String? {
        [
            kAXTitleAttribute,
            kAXDescriptionAttribute,
            kAXHelpAttribute,
            "AXIdentifier",
            kAXValueAttribute
        ]
        .compactMap { stringAttribute($0, from: element) }
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .first { !$0.isEmpty }
    }

    private func frameDescription(from element: AXUIElement) -> String? {
        guard let position = pointAttribute(kAXPositionAttribute, from: element),
              let size = sizeAttribute(kAXSizeAttribute, from: element) else {
            return nil
        }

        return "x:\(Int(position.x)) y:\(Int(position.y)) w:\(Int(size.width)) h:\(Int(size.height))"
    }

    private func stringAttribute(_ attribute: String, from element: AXUIElement) -> String? {
        guard let value = copyAttribute(attribute, from: element) else {
            return nil
        }

        if let string = value as? String {
            return string
        }

        if let attributedString = value as? NSAttributedString {
            return attributedString.string
        }

        return nil
    }

    private func pointAttribute(_ attribute: String, from element: AXUIElement) -> CGPoint? {
        guard let value = copyAttribute(attribute, from: element),
              CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        var point = CGPoint.zero
        guard AXValueGetValue(value as! AXValue, .cgPoint, &point) else {
            return nil
        }

        return point
    }

    private func sizeAttribute(_ attribute: String, from element: AXUIElement) -> CGSize? {
        guard let value = copyAttribute(attribute, from: element),
              CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        var size = CGSize.zero
        guard AXValueGetValue(value as! AXValue, .cgSize, &size) else {
            return nil
        }

        return size
    }

    private func copyAttribute(_ attribute: String, from element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
            return nil
        }
        return value
    }

    private func actionNames(of element: AXUIElement) -> [String] {
        var rawNames: CFArray?
        guard AXUIElementCopyActionNames(element, &rawNames) == .success,
              let names = rawNames as? [String] else {
            return []
        }

        return names
    }
}

private struct AXElementKey: Hashable {
    private let rawValue: ObjectIdentifier

    init(_ element: AXUIElement) {
        rawValue = ObjectIdentifier(element)
    }
}
