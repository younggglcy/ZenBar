import AppKit

final class MenuBarCoordinator {
    private let model: HiddenItemsModel
    private let inspector: MenuBarInspector

    init(model: HiddenItemsModel, inspector: MenuBarInspector) {
        self.model = model
        self.inspector = inspector
    }

    func press(item: HiddenItem) {
        guard let menuItem = inspector.menuBarItem(for: item.bundleId) else {
            return
        }
        inspector.press(item: menuItem)
    }

    func unhide(item: HiddenItem) {
        if let menuItem = inspector.menuBarItem(for: item.bundleId) {
            _ = inspector.show(item: menuItem, restorePosition: item.originalPosition)
        }
        model.removeHiddenItem(item)
    }
}
