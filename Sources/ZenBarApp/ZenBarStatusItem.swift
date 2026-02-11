import AppKit

final class ZenBarStatusItem {
    let statusItem: NSStatusItem
    var onToggle: (() -> Void)?
    var onRightClick: (() -> Void)?
    private let normalImage: NSImage
    private let activeImage: NSImage

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        normalImage = ZenBarIconRenderer.makeImage(size: 18, highlighted: false)
        activeImage = ZenBarIconRenderer.makeImage(size: 18, highlighted: true)
        if let button = statusItem.button {
            button.image = normalImage
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

    func setHighlighted(_ highlighted: Bool) {
        guard let button = statusItem.button else {
            return
        }
        button.image = highlighted ? activeImage : normalImage
        button.image?.isTemplate = true
    }
}
