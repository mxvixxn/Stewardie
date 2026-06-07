import Combine
import Foundation

@MainActor
final class MenuBarItemStore: ObservableObject {
    @Published private(set) var items: [MenuBarItem]
    @Published private(set) var hiddenSectionItems: [MenuBarItem] = []
    @Published private(set) var hiddenSectionStatusMessage: String = "보관함을 열면 현재 들어 있는 항목을 찾아볼게요."
    @Published private(set) var statusMessage: String
    @Published private(set) var hasAccessibilityPermission: Bool
    @Published private(set) var hasMenuBarDiscovery: Bool
    @Published private(set) var hasLiveMenuBarControl: Bool

    private let defaults: UserDefaults
    private let service: MenuBarIconProviding

    init(
        defaults: UserDefaults = .standard,
        service: MenuBarIconProviding = MenuBarIconService(),
        initialItems: [MenuBarItem]? = nil
    ) {
        self.defaults = defaults
        self.service = service
        self.statusMessage = "Stewardie 보관함으로 메뉴바 항목을 정리할 수 있어요."
        self.hasAccessibilityPermission = AccessibilityPermissionService.isTrusted
        self.hasMenuBarDiscovery = service.supportsDiscovery
        self.hasLiveMenuBarControl = service.supportsLiveControl

        if let initialItems {
            self.items = initialItems.sorted { $0.order < $1.order }
        } else {
            self.items = Self.loadItems(from: defaults)
        }

        if items.isEmpty {
            items = MenuBarItem.sampleItems
        }
    }

    var accessibilityPermissionTarget: String {
        AccessibilityPermissionService.permissionTargetDescription
    }

    func refreshAccessibilityPermission() {
        let hadPermission = hasAccessibilityPermission
        hasAccessibilityPermission = AccessibilityPermissionService.isTrusted

        if hasAccessibilityPermission, !hadPermission {
            statusMessage = "Accessibility 권한이 확인됐어요. 이제 새로고침으로 메뉴바 후보를 찾을 수 있습니다."
        } else if !hasAccessibilityPermission {
            statusMessage = "권한 목록에서 현재 Stewardie.app을 허용했는지 확인해 주세요."
        }
    }

    func requestAccessibilityPermission() {
        AccessibilityPermissionService.requestAccess()
        refreshAccessibilityPermission()
    }

    func openAccessibilitySettings() {
        AccessibilityPermissionService.openSystemSettings()
    }

    func refreshAvailableItems() {
        refreshAccessibilityPermission()
        hasMenuBarDiscovery = service.supportsDiscovery
        hasLiveMenuBarControl = service.supportsLiveControl

        guard hasAccessibilityPermission else {
            statusMessage = "Accessibility 권한을 허용하면 실제 메뉴바 항목 탐색을 시작할 수 있어요."
            return
        }

        guard hasMenuBarDiscovery else {
            statusMessage = "메뉴바 항목 탐색 백엔드가 아직 연결되지 않았어요."
            return
        }

        do {
            let discoveredItems = try service.availableItems()
            merge(discoveredItems)
            statusMessage = "\(discoveredItems.count)개 메뉴바 후보를 감지했어요. 눌러보기로 실제 조작 가능 여부를 확인할 수 있습니다."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    /// 보관함(구분선 왼쪽)에 현재 들어 있는 항목을 찾아 `hiddenSectionItems`에 채운다.
    /// `boundaryX`는 구분선이 표준 크기일 때의 좌측 경계 좌표.
    func refreshHiddenSectionItems(boundaryX: CGFloat?) {
        refreshAccessibilityPermission()

        guard hasAccessibilityPermission else {
            hiddenSectionItems = []
            hiddenSectionStatusMessage = "Accessibility 권한을 허용하면 보관함 안의 항목을 찾아볼 수 있어요."
            return
        }

        guard let boundaryX else {
            hiddenSectionItems = []
            hiddenSectionStatusMessage = "구분선 위치를 아직 확인하지 못했어요. 항목을 한 번 숨겼다 꺼내면 위치가 기억돼요."
            return
        }

        do {
            let found = try service.hiddenItems(leftOf: boundaryX)
            hiddenSectionItems = found
            hiddenSectionStatusMessage = found.isEmpty
                ? "보관함 안에서 찾은 항목이 없어요. 구분선 왼쪽에 아이콘을 옮겨뒀는지 확인해 보세요."
                : "보관함 안에서 \(found.count)개 항목을 찾았어요."
        } catch {
            hiddenSectionItems = []
            hiddenSectionStatusMessage = error.localizedDescription
        }
    }

    private func merge(_ discoveredItems: [MenuBarItem]) {
        let storedByIdentity = Dictionary(
            items.map { ($0.identityKey, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        items = discoveredItems.enumerated().map { offset, discovered in
            guard let stored = storedByIdentity[discovered.identityKey] else {
                var item = discovered
                item.order = offset
                return item
            }

            var item = discovered
            item.visibility = stored.visibility
            item.order = stored.order
            return item
        }
        .sorted { $0.order < $1.order }

        saveItems()
    }

    private func saveItems() {
        do {
            let data = try JSONEncoder().encode(items)
            defaults.set(data, forKey: StewardieConstants.storedItemsKey)
        } catch {
            statusMessage = "Unable to save menu bar state."
        }
    }

    private static func loadItems(from defaults: UserDefaults) -> [MenuBarItem] {
        guard let data = defaults.data(forKey: StewardieConstants.storedItemsKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([MenuBarItem].self, from: data)
        } catch {
            return []
        }
    }
}
