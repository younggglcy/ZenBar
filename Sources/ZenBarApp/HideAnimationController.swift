import AppKit

enum HideAnimationController {
    /// Animate a menu bar item shrinking and fading toward the ZenBar anchor.
    ///
    /// Creates a transparent overlay window at the item's screen position,
    /// then animates it toward the anchor with shrink + fade over 0.3s.
    static func animateHide(of item: MenuBarItem, toward anchor: CGRect, completion: @escaping () -> Void = {}) {
        guard let image = item.image,
              let axPosition = item.position,
              let screen = NSScreen.main else {
            completion()
            return
        }

        // AX positions use top-left origin; convert to NSWindow bottom-left origin
        let screenHeight = screen.frame.height
        let origin = CGPoint(
            x: axPosition.x,
            y: screenHeight - axPosition.y - image.size.height
        )

        let overlayWindow = NSWindow(
            contentRect: NSRect(origin: origin, size: image.size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        overlayWindow.isOpaque = false
        overlayWindow.backgroundColor = .clear
        overlayWindow.level = .screenSaver
        overlayWindow.ignoresMouseEvents = true
        overlayWindow.hasShadow = false

        let imageView = NSImageView(frame: NSRect(origin: .zero, size: image.size))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        overlayWindow.contentView = imageView

        overlayWindow.orderFrontRegardless()

        let targetX = anchor.midX - image.size.width / 4
        let targetY = anchor.midY - image.size.height / 4
        let targetSize = NSSize(width: image.size.width * 0.5, height: image.size.height * 0.5)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            overlayWindow.animator().setFrame(
                NSRect(origin: CGPoint(x: targetX, y: targetY), size: targetSize),
                display: true
            )
            overlayWindow.animator().alphaValue = 0
        }, completionHandler: {
            overlayWindow.orderOut(nil)
            completion()
        })
    }
}
