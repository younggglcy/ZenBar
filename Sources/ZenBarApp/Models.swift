import AppKit

struct HiddenItem: Identifiable, Codable, Equatable {
    let id: String
    let bundleId: String
    var displayName: String
    var iconData: Data?
    var hiddenOrder: Int
    var lastSeen: Date
    var originalX: Double?
    var originalY: Double?
}

extension HiddenItem {
    var icon: NSImage {
        if let iconData, let image = NSImage(data: iconData) {
            return image
        }
        return NSImage(systemSymbolName: "circle", accessibilityDescription: nil) ?? NSImage()
    }

    var originalPosition: CGPoint? {
        guard let originalX, let originalY else {
            return nil
        }
        return CGPoint(x: CGFloat(originalX), y: CGFloat(originalY))
    }
}

struct MenuBarItem {
    let id: String
    let bundleId: String?
    let title: String?
    let image: NSImage?
    let axElement: AXUIElement?
    let pid: pid_t
    let position: CGPoint?
}

struct MenuBarCapabilities {
    let canHide: Bool
    let canReorder: Bool
}
