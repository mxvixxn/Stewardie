import Foundation

/// GitHub 릴리스를 확인해 새 버전이 있는지 알려주는 서비스.
///
/// "A 방식" 업데이트 알림: 앱 안에서 자동 설치까지 하지 않고,
/// 최신 릴리스 태그를 현재 버전과 비교해 새 버전이 있으면 알려주고
/// 다운로드 페이지로 안내한다. 비공개 API·코드 서명·추가 권한이 필요 없다.
@MainActor
final class UpdateService: ObservableObject {

    enum Status: Equatable {
        case idle
        case checking
        case upToDate(current: String)
        case updateAvailable(latest: String, url: URL)
        case failed(String)
    }

    @Published private(set) var status: Status = .idle

    private let owner = "mxvixxn"
    private let repo = "Stewardie"

    var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    /// 업데이트가 있으면 다운로드 URL을 반환 (메뉴/알림 표시용 편의 프로퍼티)
    var availableUpdate: (version: String, url: URL)? {
        if case let .updateAvailable(latest, url) = status {
            return (latest, url)
        }
        return nil
    }

    func checkForUpdates() async {
        status = .checking
        do {
            let release = try await fetchLatestRelease()
            let latest = Self.normalize(release.tagName)
            if Self.isNewer(latest, than: Self.normalize(currentVersion)),
               let url = URL(string: release.htmlURL) {
                status = .updateAvailable(latest: latest, url: url)
            } else {
                status = .upToDate(current: currentVersion)
            }
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    // MARK: - Networking

    private func fetchLatestRelease() async throws -> GitHubRelease {
        guard let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/releases/latest") else {
            throw UpdateError.badResponse
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Stewardie", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw UpdateError.badResponse
        }

        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }

    // MARK: - Version comparison

    /// "v1.2.3" → "1.2.3"
    private static func normalize(_ tag: String) -> String {
        var t = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("v") || t.hasPrefix("V") {
            t.removeFirst()
        }
        return t
    }

    /// 시맨틱 버전 비교: a가 b보다 새 버전이면 true
    static func isNewer(_ a: String, than b: String) -> Bool {
        func parts(_ s: String) -> [Int] {
            s.split(separator: ".").map { component in
                Int(component.prefix { $0.isNumber }) ?? 0
            }
        }
        let pa = parts(a)
        let pb = parts(b)
        let count = max(pa.count, pb.count)
        for index in 0..<count {
            let x = index < pa.count ? pa[index] : 0
            let y = index < pb.count ? pb[index] : 0
            if x != y { return x > y }
        }
        return false
    }

    // MARK: - Types

    private struct GitHubRelease: Decodable {
        let tagName: String
        let htmlURL: String

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlURL = "html_url"
        }
    }

    enum UpdateError: LocalizedError {
        case badResponse

        var errorDescription: String? {
            switch self {
            case .badResponse:
                "업데이트 정보를 가져오지 못했어요. 잠시 후 다시 시도해 주세요."
            }
        }
    }
}
