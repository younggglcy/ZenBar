import AppKit

final class SeparatorItem {
    enum HidingState {
        case hideItems
        case showItems
    }

    private static let expandedLength: CGFloat = 10_000
    private static let collapsedLength: CGFloat = 0

    let statusItem: NSStatusItem
    private(set) var state: HidingState = .showItems

    init() {
        // Start collapsed — expand only after reconciliation moves items into hidden zone
        statusItem = NSStatusBar.system.statusItem(withLength: Self.collapsedLength)
        statusItem.autosaveName = "ZenBarSeparator"
        // Make the button invisible
        if let button = statusItem.button {
            button.image = nil
            button.title = ""
            button.cell?.isEnabled = false
        }
    }

    func setState(_ newState: HidingState) {
        state = newState
        switch newState {
        case .hideItems:
            statusItem.length = Self.expandedLength
        case .showItems:
            statusItem.length = Self.collapsedLength
        }
    }

    func toggle() {
        switch state {
        case .hideItems:
            setState(.showItems)
        case .showItems:
            setState(.hideItems)
        }
    }

    /// The screen frame of the separator's status item window.
    var windowFrame: CGRect? {
        guard let button = statusItem.button, let window = button.window else {
            return nil
        }
        return window.frame
    }

    /// The CGWindowID of the separator's status item window.
    var windowID: CGWindowID? {
        guard let button = statusItem.button, let window = button.window else {
            return nil
        }
        return CGWindowID(window.windowNumber)
    }
}
