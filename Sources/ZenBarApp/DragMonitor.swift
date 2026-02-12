import AppKit

final class DragMonitor {
    private var monitor: Any?
    private let onDrop: (MenuBarItem) -> Void
    private let onHoverChanged: (Bool) -> Void
    private let anchorProvider: () -> CGRect?
    private let coordinator: MenuBarCoordinator
    private let inspector: MenuBarInspector
    private var dragStartLocation: CGPoint?
    private var isDragging: Bool = false
    private var isHovering: Bool = false
    private let dragThreshold: CGFloat = 5

    init(
        anchorProvider: @escaping () -> CGRect?,
        coordinator: MenuBarCoordinator,
        inspector: MenuBarInspector,
        onDrop: @escaping (MenuBarItem) -> Void = { _ in },
        onHoverChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.anchorProvider = anchorProvider
        self.coordinator = coordinator
        self.inspector = inspector
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
            // Identify the item at the drag start location (where the user picked it up)
            guard let startLocation = dragStartLocation,
                  let menuItem = inspector.menuBarItem(at: convertToAXCoordinates(startLocation)) else {
                return
            }
            coordinator.hide(menuBarItem: menuItem)
            onDrop(menuItem)
        default:
            break
        }
    }

    /// Convert NSEvent screen coordinates (bottom-left origin) to AX coordinates (top-left origin).
    private func convertToAXCoordinates(_ point: CGPoint) -> CGPoint {
        guard let screenHeight = NSScreen.main?.frame.height else {
            return point
        }
        return CGPoint(x: point.x, y: screenHeight - point.y)
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
