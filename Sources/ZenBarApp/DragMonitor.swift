import AppKit

final class DragMonitor {
    private var monitor: Any?
    private let anchorProvider: () -> CGRect?
    private let inspector: MenuBarInspector
    private let model: HiddenItemsModel

    init(anchorProvider: @escaping () -> CGRect?, inspector: MenuBarInspector, model: HiddenItemsModel) {
        self.anchorProvider = anchorProvider
        self.inspector = inspector
        self.model = model
        start()
    }

    deinit {
        stop()
    }

    private func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] event in
            self?.handleMouseUp(event)
        }
    }

    private func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }

    private func handleMouseUp(_ event: NSEvent) {
        guard event.modifierFlags.contains(.command) else {
            return
        }
        guard let anchor = anchorProvider() else {
            return
        }
        let location = NSEvent.mouseLocation
        let hitArea = anchor.insetBy(dx: -10, dy: -6)
        guard hitArea.contains(location) else {
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
    }
}
