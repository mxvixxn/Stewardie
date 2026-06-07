import Foundation

struct MenuBarItem: Codable, Equatable, Hashable, Identifiable {
    let id: UUID
    var title: String
    var bundleIdentifier: String?
    var discoveryIdentifier: String?
    var ownerName: String?
    var frameDescription: String?
    var discoverySource: String?
    var isSystemItem: Bool

    init(
        id: UUID = UUID(),
        title: String,
        bundleIdentifier: String? = nil,
        discoveryIdentifier: String? = nil,
        ownerName: String? = nil,
        frameDescription: String? = nil,
        discoverySource: String? = nil,
        isSystemItem: Bool = false
    ) {
        self.id = id
        self.title = title
        self.bundleIdentifier = bundleIdentifier
        self.discoveryIdentifier = discoveryIdentifier
        self.ownerName = ownerName
        self.frameDescription = frameDescription
        self.discoverySource = discoverySource
        self.isSystemItem = isSystemItem
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
