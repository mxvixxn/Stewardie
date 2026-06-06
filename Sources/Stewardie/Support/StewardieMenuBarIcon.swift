import AppKit

enum StewardieMenuBarIcon {
    static func image() -> NSImage {
        let image = Bundle.module.url(
            forResource: "StewardieMenuBarIcon",
            withExtension: "png"
        )
        .flatMap(NSImage.init(contentsOf:)) ?? fallbackImage()

        image.size = NSSize(width: 22, height: 22)
        image.isTemplate = true
        return image
    }

    private static func fallbackImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 22, height: 22))
        image.lockFocus()
        NSColor.black.setFill()
        NSBezierPath(ovalIn: NSRect(x: 5, y: 5, width: 12, height: 12)).fill()
        image.unlockFocus()
        return image
    }
}
