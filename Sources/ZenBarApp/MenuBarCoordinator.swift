import AppKit

final class MenuBarCoordinator {
    private let model: HiddenItemsModel

    init(model: HiddenItemsModel) {
        self.model = model
    }

    func press(item: HiddenItem) {
        guard let menuItem = model.inspector.menuBarItem(for: item.bundleId) else {
            return
        }
        model.inspector.press(item: menuItem)
    }

    func unhide(item: HiddenItem) {
        if let menuItem = model.inspector.menuBarItem(for: item.bundleId) {
            _ = model.inspector.show(item: menuItem, restorePosition: item.originalPosition)
        }
        model.removeHiddenItem(item)
    }
}
