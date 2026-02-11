import AppKit

final class DragMonitor {
    private var monitor: Any?
    private let onDrop: () -> Void
    private let onHoverChanged: (Bool) -> Void
    private let anchorProvider: () -> CGRect?
    private let inspector: MenuBarInspector
    private let model: HiddenItemsModel
    private var dragStartLocation: CGPoint?
    private var isDragging: Bool = false
    private var isHovering: Bool = false
    private let dragThreshold: CGFloat = 5

    init(
        anchorProvider: @escaping () -> CGRect?,
        inspector: MenuBarInspector,
        model: HiddenItemsModel,
        onDrop: @escaping () -> Void = {},
        onHoverChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.anchorProvider = anchorProvider
        self.inspector = inspector
        self.model = model
        self.onDrop = onDrop
        self.onHoverChanged = onHoverChanged
        start()
    }

    deinit {
        stop()
    }

    private func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]) { [weak self] event in
            self?.handle(event)
        }
    }

    private func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }

    private func handle(_ event: NSEvent) {
        let location = NSEvent.mouseLocation

        switch event.type {
        case .leftMouseDown:
            dragStartLocation = location
            isDragging = false
            updateHover(isHovering: false)
        case .leftMouseDragged:
            if let start = dragStartLocation, !isDragging {
                let distance = hypot(location.x - start.x, location.y - start.y)
                if distance > dragThreshold {
                    isDragging = true
                }
            }
            if isDragging {
                updateHover(isHovering: isInsideAnchor(location))
            }
        case .leftMouseUp:
            defer {
                dragStartLocation = nil
                isDragging = false
                updateHover(isHovering: false)
            }

            guard isDragging else {
                return
            }
            guard isInsideAnchor(location) else {
                return
            }
            guard let menuItem = inspector.menuBarItem(at: location) else {
                return
            }
            model.addHiddenItem(from: menuItem)
            let didHide = inspector.hide(item: menuItem)
            if didHide {
                model.setPhysicalHideAvailable(true)
            }
            onDrop()
        default:
            break
        }
    }

    private func isInsideAnchor(_ location: CGPoint) -> Bool {
        guard let anchor = anchorProvider() else {
            return false
        }
        let hitArea = anchor.insetBy(dx: -10, dy: -6)
        return hitArea.contains(location)
    }

    private func updateHover(isHovering: Bool) {
        guard isHovering != self.isHovering else {
            return
        }
        self.isHovering = isHovering
        onHoverChanged(isHovering)
    }
}
