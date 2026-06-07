import SwiftUI

struct StewardieSettingsView: View {
    @ObservedObject var store: MenuBarItemStore
    @State private var launchAtLogin = LaunchAtLoginService.isEnabled
    @State private var launchAtLoginErrorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    permissionCard
                    generalCard
                    aboutCard
                    developerCard
                }
                .padding(18)
            }
        }
        .frame(minWidth: 520, minHeight: 460)
        .onAppear {
            store.refreshAccessibilityPermission()
        }
    }

    // MARK: - Permission

    private var permissionCard: some View {
        HStack(spacing: 14) {
            Image(systemName: store.hasAccessibilityPermission ? "checkmark.shield" : "shield.lefthalf.filled.badge.checkmark")
                .font(.title2)
                .foregroundStyle(store.hasAccessibilityPermission ? .green : .secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(store.hasAccessibilityPermission ? "손쉬운 사용 권한이 허용되어 있어요" : "손쉬운 사용 권한이 필요해요")
                    .font(.headline)

                Text(store.hasAccessibilityPermission
                     ? "보관함에서 현재 숨겨진 항목을 찾아볼 수 있어요."
                     : "보관함이 현재 숨겨진 메뉴바 항목을 찾으려면 권한 허용이 필요해요.")
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

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("설정")
                .font(.title2.weight(.semibold))

            Text("Stewardie의 동작 방식을 조정해요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(20)
    }

    // MARK: - General

    private var generalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle("일반", systemImage: "gearshape")

            Toggle(isOn: Binding(
                get: { launchAtLogin },
                set: { newValue in
                    let succeeded = LaunchAtLoginService.setEnabled(newValue)
                    if succeeded {
                        launchAtLogin = newValue
                        launchAtLoginErrorMessage = nil
                    } else {
                        launchAtLoginErrorMessage = "변경할 수 없었어요. 시스템 설정 > 일반 > 로그인 항목에서 직접 확인해 주세요."
                        launchAtLogin = LaunchAtLoginService.isEnabled
                    }
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("로그인 시 Stewardie 자동 실행")
                    Text("macOS 로그인 항목에 Stewardie를 등록해요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let launchAtLoginErrorMessage {
                Text(launchAtLoginErrorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - About / Update

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle("정보 및 업데이트", systemImage: "info.circle")

            HStack {
                Text("현재 버전")
                Spacer()
                Text(Self.versionString)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .font(.subheadline)

            Text("자동 업데이트 확인 기능은 아직 준비 중이에요. 새 버전은 GitHub 릴리스 페이지에서 직접 내려받아 설치해 주세요.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Developer

    private var developerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle("개발자", systemImage: "hammer")

            VStack(alignment: .leading, spacing: 4) {
                Text("Stewardie")
                    .font(.subheadline.weight(.semibold))
                Text("mxvixxn 제작")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("번들 식별자: \(StewardieConstants.bundleIdentifier)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Helpers

    private func cardTitle(_ text: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 28)

            Text(text)
                .font(.headline)
        }
    }

    private static var versionString: String {
        let bundle = Bundle.main
        let shortVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let buildVersion = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        if let buildVersion, buildVersion != shortVersion {
            return "\(shortVersion) (\(buildVersion))"
        }
        return shortVersion
    }
}
