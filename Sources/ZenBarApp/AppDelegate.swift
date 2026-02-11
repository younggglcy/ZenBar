import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: ZenBarStatusItem?
    private var panelController: ZenBarPanelController?
    private var model: HiddenItemsModel?
    private var coordinator: MenuBarCoordinator?
    private var dragMonitor: DragMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let inspector: MenuBarInspector
        if let privateInspector = PrivateMenuBarInspector() {
            inspector = privateInspector
        } else {
            inspector = AXMenuBarInspector()
        }
        let store = HiddenItemsStore()
        let model = HiddenItemsModel(store: store, inspector: inspector)
        let coordinator = MenuBarCoordinator(model: model, inspector: inspector)
        let panelController = ZenBarPanelController(model: model, coordinator: coordinator)

        self.model = model
        self.coordinator = coordinator
        self.panelController = panelController

        let statusItem = ZenBarStatusItem()
        statusItem.onToggle = { [weak self] in
            self?.togglePanel()
        }
        statusItem.onRightClick = { [weak self] in
            self?.showStatusMenu()
        }
        self.statusItem = statusItem

        dragMonitor = DragMonitor(
            anchorProvider: { [weak statusItem] in
                statusItem?.anchorFrame
            },
            inspector: inspector,
            model: model
        )

        model.refreshPermissions(prompt: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        model?.persist()
    }

    private func togglePanel() {
        model?.refreshPermissions()
        guard let statusItem, let anchor = statusItem.anchorFrame else {
            return
        }
        panelController?.toggle(relativeTo: anchor)
    }

    private func showStatusMenu() {
        guard let statusItem, let model else {
            return
        }
        let menu = NSMenu()

        if model.hasAccessibilityPermission {
            let item = NSMenuItem(title: "Accessibility: Granted", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        } else {
            let item = NSMenuItem(title: "Enable Accessibility", action: #selector(openAccessibilitySettings), keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        }

        if !model.canPhysicallyHide {
            let item = NSMenuItem(title: "Limited mode: icons not physically hidden", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit ZenBar", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.statusItem.menu = menu
        statusItem.statusItem.button?.performClick(nil)
        statusItem.statusItem.menu = nil
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    @objc private func openAccessibilitySettings() {
        AXPermissions.openAccessibilitySettings()
    }
}
