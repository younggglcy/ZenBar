import AppKit
import Combine

final class HiddenItemsModel: ObservableObject {
    @Published private(set) var items: [HiddenItem]
    @Published private(set) var hasAccessibilityPermission: Bool

    let inspector: MenuBarInspector
    private let store: HiddenItemsStore
    private var permissionPollTimer: Timer?

    init(store: HiddenItemsStore, inspector: MenuBarInspector) {
        self.store = store
        self.inspector = inspector
        self.items = store.load().sorted { $0.hiddenOrder < $1.hiddenOrder }
        self.hasAccessibilityPermission = AXPermissions.isTrusted()
    }

    func refreshPermissions(prompt: Bool = false) {
        let wasTrusted = hasAccessibilityPermission
        hasAccessibilityPermission = AXPermissions.isTrusted(prompt: prompt)
        if hasAccessibilityPermission {
            stopPollingPermission()
        } else if !wasTrusted {
            startPollingPermission()
        }
    }

    func startPollingPermission() {
        guard permissionPollTimer == nil else { return }
        permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            let wasTrusted = self.hasAccessibilityPermission
            let trusted = AXPermissions.isTrusted()
            if trusted != wasTrusted {
                self.hasAccessibilityPermission = trusted
            }
            if trusted {
                self.stopPollingPermission()
            }
        }
    }

    private func stopPollingPermission() {
        permissionPollTimer?.invalidate()
        permissionPollTimer = nil
    }

    func addHiddenItem(from menuBarItem: MenuBarItem) {
        guard let bundleId = menuBarItem.bundleId ?? menuBarItem.title else {
            return
        }
        let itemTitle = menuBarItem.title

        // Dedup: match by bundleId + title. If existing item has nil title (old format), update it.
        if let index = items.firstIndex(where: {
            $0.bundleId == bundleId && ($0.title == itemTitle || $0.title == nil)
        }) {
            items[index].lastSeen = Date()
            if items[index].title == nil && itemTitle != nil {
                items[index].title = itemTitle
            }
            if items[index].iconData == nil, let icon = menuBarItem.image {
                items[index].iconData = icon.pngData()
            }
            if items[index].originalX == nil, let position = menuBarItem.position {
                items[index].originalX = Double(position.x)
                items[index].originalY = Double(position.y)
            }
            persist()
            return
        }

        let compoundId = itemTitle.map { "\(bundleId):\($0)" } ?? bundleId
        let displayName = menuBarItem.title ?? bundleId
        let iconData = menuBarItem.image?.pngData()
        let newItem = HiddenItem(
            id: compoundId,
            bundleId: bundleId,
            displayName: displayName,
            title: itemTitle,
            iconData: iconData,
            hiddenOrder: items.count,
            lastSeen: Date(),
            originalX: menuBarItem.position.map { Double($0.x) },
            originalY: menuBarItem.position.map { Double($0.y) }
        )
        items.append(newItem)
        persist()
    }

    func removeHiddenItem(_ item: HiddenItem) {
        items.removeAll { $0.id == item.id }
        reorderItems()
        persist()
    }

    func move(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              items.indices.contains(sourceIndex),
              items.indices.contains(destinationIndex) else {
            return
        }
        var updated = items
        let item = updated.remove(at: sourceIndex)
        let targetIndex = destinationIndex > sourceIndex ? destinationIndex - 1 : destinationIndex
        updated.insert(item, at: max(targetIndex, 0))
        items = updated
        reorderItems()
        persist()
    }

    func persist() {
        store.save(items)
    }

    private func reorderItems() {
        for (index, _) in items.enumerated() {
            items[index].hiddenOrder = index
        }
    }
}

private extension NSImage {
    func pngData() -> Data? {
        guard let tiff = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }
}
