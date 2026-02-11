import AppKit
import SwiftUI

final class ZenBarPanelController {
    private let panel: NSPanel
    private let model: HiddenItemsModel
    private let coordinator: MenuBarCoordinator

    init(model: HiddenItemsModel, coordinator: MenuBarCoordinator) {
        self.model = model
        self.coordinator = coordinator

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 240),
            styleMask: [.titled, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.transient, .moveToActiveSpace, .fullScreenAuxiliary]
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = false
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false

        let rootView = HiddenListView(
            model: model,
            onItemPressed: { [weak self] item in
                self?.coordinator.press(item: item)
                self?.hide()
            },
            onUnhide: { [weak self] item in
                self?.coordinator.unhide(item: item)
                if self?.model.items.isEmpty == true {
                    self?.hide()
                }
            }
        )
        panel.contentView = NSHostingView(rootView: rootView)
    }

    var isVisible: Bool {
        panel.isVisible
    }

    func show(relativeTo anchor: CGRect) {
        positionPanel(relativeTo: anchor)
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    func toggle(relativeTo anchor: CGRect) {
        if isVisible {
            hide()
        } else {
            show(relativeTo: anchor)
        }
    }

    private func positionPanel(relativeTo anchor: CGRect) {
        let screen = NSScreen.screens.first { $0.frame.contains(anchor.origin) } ?? NSScreen.main
        let screenFrame = screen?.visibleFrame ?? .zero
        let panelSize = panel.frame.size

        var origin = CGPoint(
            x: anchor.midX - panelSize.width / 2,
            y: anchor.minY - panelSize.height - 8
        )

        if origin.x < screenFrame.minX + 8 {
            origin.x = screenFrame.minX + 8
        }
        if origin.x + panelSize.width > screenFrame.maxX - 8 {
            origin.x = screenFrame.maxX - panelSize.width - 8
        }
        if origin.y < screenFrame.minY + 8 {
            origin.y = anchor.maxY + 8
        }

        panel.setFrameOrigin(origin)
    }
}
