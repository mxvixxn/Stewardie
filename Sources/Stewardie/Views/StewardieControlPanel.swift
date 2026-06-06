import SwiftUI

struct StewardieControlPanel: View {
    @ObservedObject var store: MenuBarItemStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    permissionCard
                    liveControlCard
                    itemList
                }
                .padding(18)
            }

            Divider()

            footer
        }
        .frame(minWidth: 640, minHeight: 460)
        .onAppear {
            store.refreshAccessibilityPermission()
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Stewardie")
                    .font(.title2.weight(.semibold))

                Text("메뉴바 항목을 정리하고 숨김 상태를 관리해요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            StatusSummary(count: store.visibleCount, title: "표시")
            StatusSummary(count: store.hiddenCount, title: "숨김")
            StatusSummary(count: store.removedCount, title: "제거")
        }
        .padding(20)
    }

    private var permissionCard: some View {
        HStack(spacing: 14) {
            Image(systemName: store.hasAccessibilityPermission ? "checkmark.shield" : "shield.lefthalf.filled.badge.checkmark")
                .font(.title2)
                .foregroundStyle(store.hasAccessibilityPermission ? .green : .secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(store.hasAccessibilityPermission ? "Accessibility 권한이 허용되어 있어요" : "Accessibility 권한이 필요해요")
                    .font(.headline)

                Text(store.hasAccessibilityPermission ? "다음 단계에서 실제 메뉴바 항목 탐색을 연결할 준비가 됐어요." : "다른 앱과 시스템 메뉴바 항목을 읽고 정리하려면 권한 허용이 필요해요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text("확인 대상: \(store.accessibilityPermissionTarget)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(store.accessibilityPermissionTarget)
            }

            Spacer(minLength: 16)

            if store.hasAccessibilityPermission {
                Button {
                    store.refreshAccessibilityPermission()
                } label: {
                    Label("다시 확인", systemImage: "arrow.clockwise")
                }
            } else {
                Button {
                    store.requestAccessibilityPermission()
                } label: {
                    Label("권한 요청", systemImage: "hand.raised")
                }

                Button {
                    store.openAccessibilitySettings()
                } label: {
                    Label("설정 열기", systemImage: "gearshape")
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var liveControlCard: some View {
        HStack(spacing: 14) {
            Image(systemName: store.hasMenuBarDiscovery ? "dot.viewfinder" : "wrench.and.screwdriver")
                .font(.title2)
                .foregroundStyle(store.hasMenuBarDiscovery ? .green : .secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(store.hasMenuBarDiscovery ? "메뉴바 후보 탐색이 켜져 있어요" : "메뉴바 후보 탐색은 아직 준비 중이에요")
                    .font(.headline)

                Text(store.hasLiveMenuBarControl ? "숨김, 표시, 제거 버튼이 실제 메뉴바 항목에 적용됩니다." : "새로고침하면 실제 후보를 표시합니다. 숨김/제거는 Stewardie 안에서 상태를 저장하고, 숨김 항목은 메뉴바에서 바로 누를 수 있어요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Spacer()
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var itemList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.hasMenuBarDiscovery ? "메뉴바 후보 항목" : "샘플 메뉴바 항목")
                        .font(.headline)

                    Text(store.hasLiveMenuBarControl ? "감지된 항목의 숨김 상태를 관리합니다." : "감지된 항목을 Stewardie 보관함에 숨기거나 제거 목록으로 옮길 수 있습니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(store.totalCount)개")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            LazyVStack(spacing: 8) {
                ForEach(store.items) { item in
                    MenuBarItemRow(
                        item: item,
                        onToggleHidden: {
                            store.toggleHidden(for: item)
                        },
                        onRemove: {
                            store.remove(item)
                        },
                        onRestore: {
                            store.restore(item)
                        },
                        onTestPress: {
                            store.testPress(item)
                        },
                        usesLiveMenuBarControl: store.hasLiveMenuBarControl
                    )
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Label(store.statusMessage, systemImage: "info.circle")
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            Button {
                store.refreshAvailableItems()
            } label: {
                Label("새로고침", systemImage: "arrow.clockwise")
            }

            Button {
                store.revealHiddenItems()
            } label: {
                Label("숨김 보이기", systemImage: "eye")
            }
        }
        .padding(16)
    }
}

private struct StatusSummary: View {
    let count: Int
    let title: String

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(count)")
                .font(.title3.monospacedDigit().weight(.semibold))

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 64, alignment: .trailing)
    }
}

private struct MenuBarItemRow: View {
    let item: MenuBarItem
    let onToggleHidden: () -> Void
    let onRemove: () -> Void
    let onRestore: () -> Void
    let onTestPress: () -> Void
    let usesLiveMenuBarControl: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.isSystemItem ? "gearshape" : "app.dashed")
                .foregroundStyle(.secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.body.weight(.medium))

                Text(item.detailText.isEmpty ? "세부 정보 없음" : item.detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 16)

            Label(item.visibility.label, systemImage: item.visibility.systemImageName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 96, alignment: .leading)
                .help(usesLiveMenuBarControl ? "실제 메뉴바 상태" : "Stewardie 안에 저장된 상태")

            Button {
                onTestPress()
            } label: {
                Label("눌러보기", systemImage: "cursorarrow.click")
            }
            .frame(width: 112)
            .disabled(item.discoverySource != "Accessibility")

            if item.visibility == .removed {
                Button {
                    onRestore()
                } label: {
                    Label("복원", systemImage: "arrow.uturn.backward")
                }
                .frame(width: 104)
            } else {
                Button {
                    onToggleHidden()
                } label: {
                    Label(item.visibility == .hidden ? "표시" : "숨김", systemImage: item.visibility == .hidden ? "eye" : "eye.slash")
                }
                .frame(width: 104)

                Button {
                    onRemove()
                } label: {
                    Label("제거", systemImage: "xmark.circle")
                }
                .frame(width: 104)
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.separator.opacity(0.45), lineWidth: 1)
        }
    }
}
