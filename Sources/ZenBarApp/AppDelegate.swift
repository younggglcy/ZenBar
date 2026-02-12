import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: ZenBarStatusItem?
    private var panelController: ZenBarPanelController?
    private var model: HiddenItemsModel?
    private var coordinator: MenuBarCoordinator?
    private var dragMonitor: DragMonitor?
    private var separator: SeparatorItem?
    private var suppressToggleUntil: TimeInterval = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Separator created FIRST — macOS places it leftmost
        let separator = SeparatorItem()
        self.separator = separator

        // 2. Inspector, mover, store, model
        let inspector = AXMenuBarInspector()
        let mover = MenuBarItemMover()
        let store = HiddenItemsStore()
        let model = HiddenItemsModel(store: store, inspector: inspector)
        let coordinator = MenuBarCoordinator(model: model, mover: mover, separator: separator)
        let panelController = ZenBarPanelController(model: model, coordinator: coordinator)

        self.model = model
        self.coordinator = coordinator
        self.panelController = panelController

        // 3. Status item created LAST — macOS places it rightmost
        let statusItem = ZenBarStatusItem()
        statusItem.onToggle = { [weak self] in
            self?.handleToggle()
        }
        statusItem.onRightClick = { [weak self] in
            self?.showStatusMenu()
        }
        self.statusItem = statusItem

        // 4. Drag monitor
        dragMonitor = DragMonitor(
            anchorProvider: { [weak statusItem] in
                statusItem?.anchorFrame
            },
            coordinator: coordinator,
            inspector: inspector,
            onDrop: { [weak self] menuItem in
                self?.suppressToggleUntil = Date.timeIntervalSinceReferenceDate + 0.35
                self?.panelController?.hide()
                if let anchor = self?.statusItem?.anchorFrame {
                    HideAnimationController.animateHide(of: menuItem, toward: anchor)
                }
            },
            onHoverChanged: { [weak statusItem] isHovering in
                statusItem?.setHighlighted(isHovering)
            }
        )

        model.refreshPermissions(prompt: true)

        // 5. Reconcile persisted hidden items after a delay (apps need time to load their status items)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak coordinator] in
            coordinator?.reconcileHiddenItemsOnLaunch()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        model?.persist()
    }

    private func handleToggle() {
        let now = Date.timeIntervalSinceReferenceDate
        guard now >= suppressToggleUntil else {
            return
        }
        togglePanel()
    }

    private func togglePanel() {
        model?.refreshPermissions()
        guard let statusItem, let anchor = statusItem.anchorFrame else {
            return
        }
        if panelController?.isVisible == true {
            panelController?.hide()
        } else if let model, !model.items.isEmpty || !model.hasAccessibilityPermission {
            panelController?.show(relativeTo: anchor)
        }
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
