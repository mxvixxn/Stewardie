import Combine
import Foundation

@MainActor
final class MenuBarItemStore: ObservableObject {
    @Published private(set) var hiddenSectionItems: [MenuBarItem] = []
    @Published private(set) var hiddenSectionStatusMessage: String = "보관함을 열면 현재 들어 있는 항목을 찾아볼게요."
    @Published private(set) var hasAccessibilityPermission: Bool

    private let service: MenuBarIconProviding

    init(service: MenuBarIconProviding = MenuBarIconService()) {
        self.service = service
        self.hasAccessibilityPermission = AccessibilityPermissionService.isTrusted
    }

    var accessibilityPermissionTarget: String {
        AccessibilityPermissionService.permissionTargetDescription
    }

    func refreshAccessibilityPermission() {
        hasAccessibilityPermission = AccessibilityPermissionService.isTrusted
    }

    func requestAccessibilityPermission() {
        AccessibilityPermissionService.requestAccess()
        refreshAccessibilityPermission()
    }

    func openAccessibilitySettings() {
        AccessibilityPermissionService.openSystemSettings()
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
}
