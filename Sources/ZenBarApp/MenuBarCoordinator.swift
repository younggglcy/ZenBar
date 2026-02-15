import AppKit

final class MenuBarCoordinator {
    private let model: HiddenItemsModel
    private let mover: MenuBarItemMover
    private let separator: SeparatorItem

    init(model: HiddenItemsModel, mover: MenuBarItemMover, separator: SeparatorItem) {
        self.model = model
        self.mover = mover
        self.separator = separator
    }

    /// Hide a menu bar item by moving it to the left of the separator.
    func hide(menuBarItem: MenuBarItem) {
        // Ensure separator is expanded before moving
        if separator.state != .hideItems {
            separator.setState(.hideItems)
        }
        guard let separatorFrame = separator.windowFrame else {
            return
        }
        mover.move(item: menuBarItem, to: .leftOfSeparator(separatorFrame: separatorFrame))
        model.addHiddenItem(from: menuBarItem)
    }

    /// Press (activate) a hidden item — temporarily collapse separator so item is on-screen.
    func press(item: HiddenItem) {
        guard let menuItem = model.inspector.menuBarItem(for: item.bundleId, title: item.title) else {
            return
        }
        // Temporarily show all items so AXPress can reach the off-screen item
        separator.setState(.showItems)
        // Brief delay for the menu bar to re-layout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            // Re-fetch to get updated position after separator collapse
            if let freshItem = self?.model.inspector.menuBarItem(for: item.bundleId, title: item.title) {
                self?.model.inspector.press(item: freshItem)
            } else {
                self?.model.inspector.press(item: menuItem)
            }
            // Re-expand the separator after a delay to let the menu appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.separator.setState(.hideItems)
            }
        }
    }

    /// Unhide an item by moving it to the right of the separator.
    func unhide(item: HiddenItem) {
        if let menuItem = model.inspector.menuBarItem(for: item.bundleId, title: item.title),
           let separatorFrame = separator.windowFrame {
            mover.move(item: menuItem, to: .rightOfSeparator(separatorFrame: separatorFrame))
        }
        model.removeHiddenItem(item)
    }

    /// On launch, move all persisted hidden items to the left of the separator.
    func reconcileHiddenItemsOnLaunch() {
        guard !model.items.isEmpty else {
            return
        }
        // Expand separator first, then move items into the hidden zone
        separator.setState(.hideItems)
        guard let separatorFrame = separator.windowFrame else {
            return
        }
        for hiddenItem in model.items {
            if let menuItem = model.inspector.menuBarItem(for: hiddenItem.bundleId, title: hiddenItem.title) {
                mover.move(item: menuItem, to: .leftOfSeparator(separatorFrame: separatorFrame))
            }
        }
    }
}
