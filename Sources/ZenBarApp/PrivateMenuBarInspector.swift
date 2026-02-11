import AppKit
import ApplicationServices

final class PrivateMenuBarInspector: MenuBarInspector {
    private let ax: AXMenuBarInspector
    let capabilities: MenuBarCapabilities
    private let hiddenAttribute = kAXHiddenAttribute as CFString
    private let positionAttribute = kAXPositionAttribute as CFString

    init?(axInspector: AXMenuBarInspector = AXMenuBarInspector()) {
        self.ax = axInspector
        guard let sample = axInspector.snapshotMenuBarItems().first,
              let element = sample.axElement else {
            return nil
        }

        let canHide = Self.canSetAttribute(element, hiddenAttribute)
        let canReorder = Self.canSetAttribute(element, positionAttribute)
        guard canHide || canReorder else {
            return nil
        }
        self.capabilities = MenuBarCapabilities(canHide: canHide, canReorder: canReorder)
    }

    func menuBarItem(at point: CGPoint) -> MenuBarItem? {
        ax.menuBarItem(at: point)
    }

    func menuBarItem(for bundleId: String) -> MenuBarItem? {
        ax.menuBarItem(for: bundleId)
    }

    func snapshotMenuBarItems() -> [MenuBarItem] {
        ax.snapshotMenuBarItems()
    }

    func press(item: MenuBarItem) {
        ax.press(item: item)
    }

    func hide(item: MenuBarItem) -> Bool {
        if capabilities.canHide, setHidden(true, for: item) {
            return true
        }
        if capabilities.canReorder, moveOffscreen(item) {
            return true
        }
        return false
    }

    func show(item: MenuBarItem, restorePosition: CGPoint?) -> Bool {
        if capabilities.canHide, setHidden(false, for: item) {
            return true
        }
        guard let restorePosition, capabilities.canReorder else {
            return false
        }
        return setPosition(restorePosition, for: item)
    }

    private func setHidden(_ hidden: Bool, for item: MenuBarItem) -> Bool {
        guard let element = item.axElement else {
            return false
        }
        guard Self.canSetAttribute(element, hiddenAttribute) else {
            return false
        }
        let value: CFTypeRef = hidden ? kCFBooleanTrue! : kCFBooleanFalse!
        let result = AXUIElementSetAttributeValue(element, hiddenAttribute, value)
        return result == .success
    }

    private func moveOffscreen(_ item: MenuBarItem) -> Bool {
        guard let position = item.position else {
            return false
        }
        let offscreen = CGPoint(x: -2000, y: position.y)
        return setPosition(offscreen, for: item)
    }

    private func setPosition(_ point: CGPoint, for item: MenuBarItem) -> Bool {
        guard let element = item.axElement else {
            return false
        }
        guard Self.canSetAttribute(element, positionAttribute) else {
            return false
        }
        var mutablePoint = point
        guard let value = AXValueCreate(.cgPoint, &mutablePoint) else {
            return false
        }
        let result = AXUIElementSetAttributeValue(element, positionAttribute, value)
        return result == .success
    }

    private static func canSetAttribute(_ element: AXUIElement, _ attribute: CFString) -> Bool {
        var settable = DarwinBoolean(false)
        let result = AXUIElementIsAttributeSettable(element, attribute, &settable)
        return result == .success && settable.boolValue
    }
}
