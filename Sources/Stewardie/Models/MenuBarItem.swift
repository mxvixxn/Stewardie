import Foundation

struct MenuBarItem: Codable, Equatable, Hashable, Identifiable {
    enum Visibility: String, Codable, CaseIterable {
        case visible
        case hidden
        case removed

        var label: String {
            switch self {
            case .visible:
                "표시"
            case .hidden:
                "숨김"
            case .removed:
                "제거"
            }
        }

        var systemImageName: String {
            switch self {
            case .visible:
                "eye"
            case .hidden:
                "eye.slash"
            case .removed:
                "xmark.circle"
            }
        }
    }

    let id: UUID
    var title: String
    var bundleIdentifier: String?
    var discoveryIdentifier: String?
    var ownerName: String?
    var frameDescription: String?
    var discoverySource: String?
    var isSystemItem: Bool
    var visibility: Visibility
    var order: Int

    init(
        id: UUID = UUID(),
        title: String,
        bundleIdentifier: String? = nil,
        discoveryIdentifier: String? = nil,
        ownerName: String? = nil,
        frameDescription: String? = nil,
        discoverySource: String? = nil,
        isSystemItem: Bool = false,
        visibility: Visibility = .visible,
        order: Int
    ) {
        self.id = id
        self.title = title
        self.bundleIdentifier = bundleIdentifier
        self.discoveryIdentifier = discoveryIdentifier
        self.ownerName = ownerName
        self.frameDescription = frameDescription
        self.discoverySource = discoverySource
        self.isSystemItem = isSystemItem
        self.visibility = visibility
        self.order = order
    }

    var identityKey: String {
        discoveryIdentifier
        ?? bundleIdentifier.map { "\($0):\(title)" }
        ?? title
    }

    var detailText: String {
        [
            ownerName,
            bundleIdentifier,
            frameDescription,
            discoverySource
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: " · ")
    }
}

extension MenuBarItem {
    static let sampleItems: [MenuBarItem] = [
        MenuBarItem(
            title: "Wi-Fi",
            bundleIdentifier: "com.apple.controlcenter",
            isSystemItem: true,
            visibility: .visible,
            order: 0
        ),
        MenuBarItem(
            title: "Battery",
            bundleIdentifier: "com.apple.controlcenter",
            isSystemItem: true,
            visibility: .visible,
            order: 1
        ),
        MenuBarItem(
            title: "Focus",
            bundleIdentifier: "com.apple.controlcenter",
            isSystemItem: true,
            visibility: .hidden,
            order: 2
        ),
        MenuBarItem(
            title: "Example App",
            bundleIdentifier: "com.example.MenuBarApp",
            isSystemItem: false,
            visibility: .hidden,
            order: 3
        )
    ]
}
