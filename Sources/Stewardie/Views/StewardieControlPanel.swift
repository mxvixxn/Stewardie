import SwiftUI

struct StewardieControlPanel: View {
    @ObservedObject var store: MenuBarItemStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    howToUseCard
                    permissionCard
                    discoveredItemList
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

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Stewardie")
                    .font(.title2.weight(.semibold))

                Text("메뉴바 항목을 구분선 기준으로 숨기고 관리해요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            StatusSummary(count: store.totalCount, title: "감지됨")
        }
        .padding(20)
    }

    // MARK: - How to Use

    private var howToUseCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "menubar.arrow.up.rectangle")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 32)

                Text("메뉴바 항목 숨기기")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                stepLabel(number: "1", text: "메뉴바에서 구분선(|)을 찾으세요. Stewardie 아이콘 왼쪽에 있어요.")
                stepLabel(number: "2", text: "⌘-드래그로 숨기고 싶은 아이콘을 구분선 왼쪽으로 옮기세요.")
                stepLabel(number: "3", text: "Stewardie 아이콘을 클릭하면 구분선 왼쪽 항목이 숨겨지거나 나타나요.")
            }
            .padding(.leading, 42)

            Text("우클릭 또는 ⌥-클릭으로 설정 메뉴를 열 수 있어요.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 42)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func stepLabel(number: String, text: String) -> some View {
        Label {
            Text(text)
                .font(.subheadline)
        } icon: {
            Text(number)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(Circle().fill(.blue))
        }
    }

    // MARK: - Permission Card

    private var permissionCard: some View {
        HStack(spacing: 14) {
            Image(systemName: store.hasAccessibilityPermission ? "checkmark.shield" : "shield.lefthalf.filled.badge.checkmark")
                .font(.title2)
                .foregroundStyle(store.hasAccessibilityPermission ? .green : .secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(store.hasAccessibilityPermission ? "Accessibility 권한이 허용되어 있어요" : "Accessibility 권한이 필요해요")
                    .font(.headline)

                Text(store.hasAccessibilityPermission
                     ? "메뉴바 항목 탐색과 눌러보기가 가능해요."
                     : "다른 앱의 메뉴바 항목을 탐색하려면 권한 허용이 필요해요.")
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

    // MARK: - Discovered Items

    private var discoveredItemList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("감지된 메뉴바 항목")
                        .font(.headline)

                    Text("Accessibility로 탐색된 항목이에요. 눌러보기로 동작을 확인할 수 있어요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(store.totalCount)개")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if store.items.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "menubar.rectangle")
                            .font(.largeTitle)
                            .foregroundStyle(.quaternary)
                        Text("새로고침을 눌러 메뉴바 항목을 탐색하세요.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 32)
                    Spacer()
                }
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(store.items) { item in
                        DiscoveredItemRow(
                            item: item,
                            onTestPress: {
                                store.testPress(item)
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Footer

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
        }
        .padding(16)
    }
}

// MARK: - Supporting Views

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

private struct DiscoveredItemRow: View {
    let item: MenuBarItem
    let onTestPress: () -> Void

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

            if let source = item.discoverySource {
                Text(source)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(.quaternary.opacity(0.5))
                    )
            }

            Button {
                onTestPress()
            } label: {
                Label("눌러보기", systemImage: "cursorarrow.click")
            }
            .disabled(item.discoverySource != "Accessibility")
            .help(item.discoverySource == "Accessibility"
                  ? "이 항목에 클릭 동작을 보냅니다"
                  : "Accessibility로 감지된 항목만 눌러볼 수 있어요")
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.separator.opacity(0.45), lineWidth: 1)
        }
    }
}
