import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

protocol MenuBarIconProviding {
    /// 현재 화면상에서 `boundaryX`보다 왼쪽(메뉴바 영역)에 위치한 항목들을 찾는다.
    /// Stewardie의 구분선이 확장되어 항목들을 화면 밖으로 밀어냈을 때,
    /// "지금 보관함에 들어 있는 항목"을 보여주기 위한 읽기 전용 탐색이다.
    func hiddenItems(leftOf boundaryX: CGFloat) throws -> [MenuBarItem]
}

enum MenuBarIconServiceError: LocalizedError {
    case accessibilityPermissionMissing

    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionMissing:
            "Accessibility 권한을 허용해야 실제 메뉴바 항목을 탐색할 수 있어요."
        }
    }
}

final class MenuBarIconService: MenuBarIconProviding {
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

        return merge(results)
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
           let candidate = menuItem(from: element, app: app) {
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

    private func menuItem(
        from element: AXUIElement,
        app: NSRunningApplication
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
            isSystemItem: true
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
}

private struct AXElementKey: Hashable {
    private let rawValue: ObjectIdentifier

    init(_ element: AXUIElement) {
        rawValue = ObjectIdentifier(element)
    }
}
