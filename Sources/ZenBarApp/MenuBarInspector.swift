import AppKit
import ApplicationServices

protocol MenuBarInspector {
    func menuBarItem(at point: CGPoint) -> MenuBarItem?
    func menuBarItem(for bundleId: String) -> MenuBarItem?
    func snapshotMenuBarItems() -> [MenuBarItem]
    func press(item: MenuBarItem)
}

final class AXMenuBarInspector: MenuBarInspector {
    private let systemWide = AXUIElementCreateSystemWide()
    private var cacheByBundleId: [String: MenuBarItem] = [:]

    func menuBarItem(at point: CGPoint) -> MenuBarItem? {
        var element: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(systemWide, Float(point.x), Float(point.y), &element)
        guard result == .success, let element else {
            return nil
        }
        guard let menuElement = normalizeMenuBarItem(element) else {
            return nil
        }
        guard let item = makeMenuBarItem(from: menuElement) else {
            return nil
        }
        cache(item)
        return item
    }

    func menuBarItem(for bundleId: String) -> MenuBarItem? {
        if let cached = cacheByBundleId[bundleId] {
            return cached
        }
        let items = snapshotMenuBarItems()
        return items.first { $0.bundleId == bundleId }
    }

    func snapshotMenuBarItems() -> [MenuBarItem] {
        guard let menuBar: AXUIElement = copyAttribute(systemWide, kAXMenuBarAttribute as CFString) else {
            return []
        }
        guard let children: [AXUIElement] = copyAttribute(menuBar, kAXChildrenAttribute as CFString) else {
            return []
        }

        var items: [MenuBarItem] = []
        for child in children {
            guard let menuElement = normalizeMenuBarItem(child) else {
                continue
            }
            guard let item = makeMenuBarItem(from: menuElement) else {
                continue
            }
            cache(item)
            items.append(item)
        }
        return items
    }

    func press(item: MenuBarItem) {
        guard let element = item.axElement else {
            return
        }
        AXUIElementPerformAction(element, kAXPressAction as CFString)
    }

    private func cache(_ item: MenuBarItem) {
        guard let bundleId = item.bundleId else {
            return
        }
        cacheByBundleId[bundleId] = item
    }

    private func normalizeMenuBarItem(_ element: AXUIElement) -> AXUIElement? {
        var current: AXUIElement? = element
        for _ in 0..<6 {
            guard let candidate = current else {
                return nil
            }
            if isMenuBarItem(candidate) {
                return candidate
            }
            current = copyAttribute(candidate, kAXParentAttribute as CFString)
        }
        return nil
    }

    private func isMenuBarItem(_ element: AXUIElement) -> Bool {
        guard let role: String = copyAttribute(element, kAXRoleAttribute as CFString) else {
            return false
        }
        if role == kAXMenuBarItemRole as String {
            return true
        }
        if role == "AXMenuBarItem" || role == "AXStatusItem" {
            return true
        }
        return false
    }

    private func makeMenuBarItem(from element: AXUIElement) -> MenuBarItem? {
        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)
        guard pid != 0 else {
            return nil
        }
        let running = NSRunningApplication(processIdentifier: pid)
        let bundleId = running?.bundleIdentifier
        let displayName = running?.localizedName
        let title: String? = copyAttribute(element, kAXTitleAttribute as CFString)
        let fallbackTitle: String? = copyAttribute(element, kAXDescriptionAttribute as CFString)
        let image = running?.icon
        let position = copyPointAttribute(element, kAXPositionAttribute as CFString)
        let id = bundleId ?? "pid:\(pid)"

        // Match to a CGWindowID for CGEvent targeting
        let windowID: CGWindowID? = position.flatMap { MenuBarWindowInfo.windowID(forPID: pid, near: $0) }

        return MenuBarItem(
            id: id,
            bundleId: bundleId,
            title: title ?? fallbackTitle ?? displayName,
            image: image,
            axElement: element,
            pid: pid,
            position: position,
            windowID: windowID
        )
    }
}

private func copyAttribute<T>(_ element: AXUIElement, _ attribute: CFString) -> T? {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(element, attribute, &value)
    guard result == .success, let unwrapped = value else {
        return nil
    }
    return unwrapped as? T
}

private func copyPointAttribute(_ element: AXUIElement, _ attribute: CFString) -> CGPoint? {
    guard let axValue: AXValue = copyAttribute(element, attribute) else {
        return nil
    }
    guard AXValueGetType(axValue) == .cgPoint else {
        return nil
    }
    var point = CGPoint.zero
    AXValueGetValue(axValue, .cgPoint, &point)
    return point
}
