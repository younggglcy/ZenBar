import AppKit

final class MenuBarItemMover {
    enum MoveDestination {
        case leftOfSeparator(separatorFrame: CGRect)
        case rightOfSeparator(separatorFrame: CGRect)
    }

    private let maxAttempts = 3
    private let stepDelay: UInt32 = 30_000 // microseconds (30ms)

    /// Move a menu bar item to the given destination using synthetic CGEvent Cmd+drag.
    /// Returns true if the move was posted successfully.
    @discardableResult
    func move(item: MenuBarItem, to destination: MoveDestination) -> Bool {
        guard let itemPosition = item.position else {
            return false
        }

        let targetPoint = destinationPoint(for: destination)

        for attempt in 0..<maxAttempts {
            if attempt > 0 {
                usleep(50_000) // 50ms between retries
            }
            if performMove(from: itemPosition, to: targetPoint, itemWindowID: item.windowID) {
                return true
            }
        }
        return false
    }

    private func destinationPoint(for destination: MoveDestination) -> CGPoint {
        switch destination {
        case .leftOfSeparator(let frame):
            // Place item to the left of the separator (in the hidden zone)
            return CGPoint(x: frame.minX - 20, y: frame.midY)
        case .rightOfSeparator(let frame):
            // Place item to the right of the separator (in the visible zone)
            return CGPoint(x: frame.maxX + 20, y: frame.midY)
        }
    }

    private func performMove(from source: CGPoint, to target: CGPoint, itemWindowID: CGWindowID?) -> Bool {
        guard let eventSource = CGEventSource(stateID: .hidSystemState) else {
            return false
        }

        // Allow our synthetic events even when event suppression is active
        eventSource.localEventsSuppressionInterval = 0

        // Save current cursor position
        let savedCursorPos = NSEvent.mouseLocation
        let savedCGPos = CGPoint(
            x: savedCursorPos.x,
            y: (NSScreen.main?.frame.height ?? 0) - savedCursorPos.y
        )

        // Hide cursor during move
        CGDisplayHideCursor(CGMainDisplayID())
        defer { CGDisplayShowCursor(CGMainDisplayID()) }

        // 1. Mouse down with Cmd at source (item position)
        guard let mouseDown = CGEvent(
            mouseEventSource: eventSource,
            mouseType: .leftMouseDown,
            mouseCursorPosition: source,
            mouseButton: .left
        ) else {
            return false
        }
        mouseDown.flags = .maskCommand

        // Target the specific item window if we know it
        if let windowID = itemWindowID {
            mouseDown.setIntegerValueField(.mouseEventWindowUnderMousePointer, value: Int64(windowID))
        }

        mouseDown.post(tap: .cghidEventTap)
        usleep(stepDelay)

        // 2. Mouse dragged to destination (still holding Cmd)
        guard let mouseDrag = CGEvent(
            mouseEventSource: eventSource,
            mouseType: .leftMouseDragged,
            mouseCursorPosition: target,
            mouseButton: .left
        ) else {
            return false
        }
        mouseDrag.flags = .maskCommand
        mouseDrag.post(tap: .cghidEventTap)
        usleep(stepDelay)

        // 3. Mouse up at destination
        guard let mouseUp = CGEvent(
            mouseEventSource: eventSource,
            mouseType: .leftMouseUp,
            mouseCursorPosition: target,
            mouseButton: .left
        ) else {
            return false
        }
        mouseUp.post(tap: .cghidEventTap)
        usleep(stepDelay)

        // 4. Restore cursor position
        CGWarpMouseCursorPosition(savedCGPos)

        return true
    }
}
