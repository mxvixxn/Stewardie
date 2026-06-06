import Combine
import Foundation

@MainActor
final class MenuBarItemStore: ObservableObject {
    @Published private(set) var items: [MenuBarItem]
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

    var hiddenCount: Int {
        items.filter { $0.visibility == .hidden }.count
    }

    var removedCount: Int {
        items.filter { $0.visibility == .removed }.count
    }

    var visibleCount: Int {
        items.filter { $0.visibility == .visible }.count
    }

    var totalCount: Int {
        items.count
    }

    var hiddenItems: [MenuBarItem] {
        items.filter { $0.visibility == .hidden }
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

    func testPress(_ item: MenuBarItem) {
        activate(item)
    }

    func activate(_ item: MenuBarItem) {
        refreshAccessibilityPermission()

        guard hasAccessibilityPermission else {
            statusMessage = "Accessibility 권한을 먼저 허용해 주세요."
            return
        }

        do {
            try service.press(item)
            statusMessage = "'\(item.title)' 항목에 누르기 동작을 보냈어요."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func toggleHidden(for item: MenuBarItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        switch items[index].visibility {
        case .visible:
            items[index].visibility = .hidden
            statusMessage = "'\(items[index].title)' 항목을 Stewardie 보관함에 숨겼어요."
        case .hidden:
            items[index].visibility = .visible
            statusMessage = "'\(items[index].title)' 항목을 표시 목록으로 되돌렸어요."
        case .removed:
            items[index].visibility = .visible
            statusMessage = "'\(items[index].title)' 항목을 복원했어요."
        }

        saveItems()
    }

    func remove(_ item: MenuBarItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        items[index].visibility = .removed
        statusMessage = "'\(items[index].title)' 항목을 제거 목록으로 옮겼어요."
        saveItems()
    }

    func restore(_ item: MenuBarItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        items[index].visibility = .visible
        statusMessage = "'\(items[index].title)' 항목을 복원했어요."
        saveItems()
    }

    func revealHiddenItems() {
        let hiddenIndices = items.indices.filter { items[$0].visibility == .hidden }
        guard !hiddenIndices.isEmpty else {
            statusMessage = "숨김 보관함에 들어 있는 항목이 없어요."
            return
        }

        for index in hiddenIndices {
            items[index].visibility = .visible
        }

        statusMessage = "\(hiddenIndices.count)개 숨김 항목을 표시 목록으로 되돌렸어요."
        saveItems()
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
