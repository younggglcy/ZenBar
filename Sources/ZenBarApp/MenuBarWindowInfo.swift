import AppKit

enum MenuBarWindowInfo {
    struct ItemWindow {
        let windowID: CGWindowID
        let frame: CGRect
        let pid: pid_t
    }

    /// Returns all menu bar item windows (layer 25) currently on screen.
    static func getMenuBarItemWindows() -> [ItemWindow] {
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[CFString: Any]] else {
            return []
        }
        var results: [ItemWindow] = []
        for info in windowList {
            guard let layer = info[kCGWindowLayer] as? Int, layer == 25 else {
                continue
            }
            guard let windowID = info[kCGWindowNumber] as? CGWindowID,
                  let pid = info[kCGWindowOwnerPID] as? pid_t else {
                continue
            }
            guard let bounds = info[kCGWindowBounds] as? [String: CGFloat],
                  let x = bounds["X"], let y = bounds["Y"],
                  let w = bounds["Width"], let h = bounds["Height"] else {
                continue
            }
            let frame = CGRect(x: x, y: y, width: w, height: h)
            results.append(ItemWindow(windowID: windowID, frame: frame, pid: pid))
        }
        return results
    }

    /// Find a window ID matching the given PID and nearest to the given AX position.
    static func windowID(forPID pid: pid_t, near axPosition: CGPoint, tolerance: CGFloat = 20) -> CGWindowID? {
        let windows = getMenuBarItemWindows().filter { $0.pid == pid }
        var bestMatch: CGWindowID?
        var bestDistance: CGFloat = .greatestFiniteMagnitude
        for window in windows {
            let dx = window.frame.origin.x - axPosition.x
            let dy = window.frame.origin.y - axPosition.y
            let distance = hypot(dx, dy)
            if distance < bestDistance && distance < tolerance {
                bestDistance = distance
                bestMatch = window.windowID
            }
        }
        return bestMatch
    }
}
