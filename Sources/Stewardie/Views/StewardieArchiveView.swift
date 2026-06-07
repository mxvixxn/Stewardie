import SwiftUI

/// 보관함: 현재 구분선 왼쪽(숨김 영역)에 놓인 메뉴바 항목들을 한눈에 다루는 화면.
///
/// 주의: macOS는 다른 앱이 소유한 메뉴바 아이콘을 "눌러서 조작"하는 것은
/// 안정적으로 보장하지 않아요 (그게 가능했다면 "눌러보기"도 모든 앱에서 동작했겠죠).
/// 그래서 개별 항목을 하나씩 골라 꺼내는 조작 기능은 넣지 않았고,
/// 구분선 자체를 확실하게 여닫는 전체 토글만 제공해요.
/// 다만 "지금 뭐가 들어 있는지 보기"는 위치 정보만으로 가능한 읽기 전용 작업이라
/// 아래에 목록으로 보여줘요 (일부 앱은 인식 방식 차이로 빠질 수 있어요).
struct StewardieArchiveView: View {
    @ObservedObject var divider: StewardieDivider
    @ObservedObject var store: MenuBarItemStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    statusCard
                    contentsCard
                    howToCard
                }
                .padding(18)
            }
        }
        .frame(minWidth: 560, minHeight: 520)
        .onAppear {
            store.refreshHiddenSectionItems(boundaryX: divider.boundaryScreenX)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("보관함")
                .font(.title2.weight(.semibold))

            Text("구분선 왼쪽에 놓인 메뉴바 항목을 모아두는 공간이에요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(20)
    }

    // MARK: - Status

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(systemName: divider.isHiding ? "archivebox.fill" : "tray.and.arrow.up.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(divider.isHiding ? .blue : .secondary)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(divider.isHiding ? "지금 항목이 보관함에 들어 있어요" : "지금 보관함이 비어 있어요")
                        .font(.headline)

                    Text(divider.isHiding
                         ? "구분선 왼쪽의 아이콘들이 화면 밖으로 숨겨진 상태예요."
                         : "구분선 왼쪽의 아이콘들이 모두 메뉴바에 보이는 상태예요.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Button {
                divider.toggle()
            } label: {
                Label(
                    divider.isHiding ? "보관함 항목 모두 꺼내기" : "선택한 항목 보관함에 넣기",
                    systemImage: divider.isHiding ? "tray.and.arrow.up" : "tray.and.arrow.down"
                )
                .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Contents

    private var contentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.title3)
                        .foregroundStyle(.blue)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("지금 보관함 안에 있는 항목")
                            .font(.headline)

                        Text(store.hiddenSectionStatusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if store.hasAccessibilityPermission {
                    Button {
                        store.refreshHiddenSectionItems(boundaryX: divider.boundaryScreenX)
                    } label: {
                        Label("새로고침", systemImage: "arrow.clockwise")
                    }
                }
            }

            // 권한이 없으면: 명확한 경고
            if !store.hasAccessibilityPermission {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "lock.shield")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text("손쉬운 사용 권한이 필요해요")
                            .font(.headline)
                        Text("위의 설정 카드에서 \"권한 요청\" 또는 \"설정 열기\"를 눌러 권한을 허용해 주세요.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button {
                            store.openAccessibilitySettings()
                        } label: {
                            Label("설정 열기", systemImage: "gearshape")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
            }
            // 권한은 있지만 항목이 없으면: 빈 상태
            else if store.hiddenSectionItems.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "tray")
                            .font(.largeTitle)
                            .foregroundStyle(.quaternary)
                        Text("표시할 항목이 없어요.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
            }
            // 권한 있고 항목도 있으면: 목록 표시
            else {
                LazyVStack(spacing: 8) {
                    ForEach(store.hiddenSectionItems) { item in
                        HiddenItemRow(item: item)
                    }
                }
            }

            if store.hasAccessibilityPermission {
                Text("이 목록은 위치 정보만으로 추정한 결과라 일부 앱은 표시되지 않을 수 있어요. 항목을 직접 조작하는 기능은 아니고, 참고용으로만 봐 주세요.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - How To

    private var howToCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "questionmark.circle")
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 28)

                Text("보관함에 항목 넣고 빼기")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                stepLabel(number: "1", text: "메뉴바에서 Stewardie 아이콘 왼쪽의 구분선(｜)을 찾으세요.")
                stepLabel(number: "2", text: "⌘-드래그로 보관하고 싶은 아이콘을 구분선 왼쪽으로 옮기세요. 꺼내고 싶다면 반대로 오른쪽으로 옮기면 돼요.")
                stepLabel(number: "3", text: "Stewardie 아이콘을 클릭하거나 위 버튼을 누르면, 구분선 왼쪽의 모든 항목이 한 번에 숨겨지거나 다시 나타나요.")
            }
            .padding(.leading, 38)

            Text("개별 항목을 하나씩 골라 꺼내는 기능은 넣지 않았어요. macOS가 다른 앱의 메뉴바 아이콘을 앱 단위로 정확히 짚어주지 않기 때문에, 그런 기능은 일부 앱에서만 동작하는 반쪽짜리가 될 수밖에 없거든요. 대신 항상 100% 동작하는 전체 토글로 같은 결과를 얻을 수 있어요.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 38)
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
}

// MARK: - Hidden Item Row

private struct HiddenItemRow: View {
    let item: MenuBarItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "app.dashed")
                .foregroundStyle(.secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.body.weight(.medium))

                Text(item.ownerName ?? item.detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 16)

            Image(systemName: "eye.slash")
                .foregroundStyle(.tertiary)
                .help("현재 화면 밖으로 숨겨져 있어요")
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.separator.opacity(0.45), lineWidth: 1)
        }
    }
}
