import AppKit

final class ZenBarStatusItem {
    let statusItem: NSStatusItem
    var onToggle: (() -> Void)?
    var onRightClick: (() -> Void)?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "circle.grid.3x3.circle", accessibilityDescription: "ZenBar")
            button.image?.isTemplate = true
            button.target = self
            button.action = #selector(handleClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    var anchorFrame: CGRect? {
        guard let button = statusItem.button, let window = button.window else {
            return nil
        }
        let frame = button.convert(button.bounds, to: nil)
        return window.convertToScreen(frame)
    }

    @objc private func handleClick() {
        guard let event = NSApp.currentEvent else {
            return
        }
        switch event.type {
        case .rightMouseUp:
            onRightClick?()
        default:
            onToggle?()
        }
    }
}
