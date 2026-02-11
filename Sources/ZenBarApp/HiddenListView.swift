import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct HiddenListView: View {
    @ObservedObject var model: HiddenItemsModel
    let onItemPressed: (HiddenItem) -> Void
    let onUnhide: (HiddenItem) -> Void
    @State private var draggingId: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !model.hasAccessibilityPermission {
                permissionBanner
            }

            if model.items.isEmpty {
                emptyState
            } else {
                listView
            }
        }
        .padding(10)
        .frame(width: 220)
    }

    private var permissionBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Accessibility permission required")
                .font(.system(size: 12, weight: .semibold))
            Text("Enable it to detect and control menu bar items.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Button("Open Accessibility Settings") {
                AXPermissions.openAccessibilitySettings()
            }
            .buttonStyle(.link)
            .font(.system(size: 11))
        }
        .padding(8)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.6))
        .cornerRadius(8)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Drag menu bar icons onto ZenBar")
                .font(.system(size: 12, weight: .semibold))
            Text("Hold Command while dragging, then drop on ZenBar.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.4))
        .cornerRadius(8)
    }

    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(model.items) { item in
                    HStack {
                        Image(nsImage: item.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .help(item.displayName)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 6)
                    .contentShape(Rectangle())
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.2))
                    .cornerRadius(6)
                    .onTapGesture {
                        onItemPressed(item)
                    }
                    .contextMenu {
                        Button("Unhide") {
                            onUnhide(item)
                        }
                    }
                    .onDrag {
                        draggingId = item.id
                        return NSItemProvider(object: item.id as NSString)
                    }
                    .onDrop(of: [UTType.text], delegate: HiddenItemDropDelegate(
                        target: item,
                        model: model,
                        draggingId: $draggingId
                    ))
                }
            }
            .padding(.vertical, 2)
        }
        .frame(height: min(CGFloat(model.items.count) * 36.0 + 8.0, 260))
    }
}

private struct HiddenItemDropDelegate: DropDelegate {
    let target: HiddenItem
    let model: HiddenItemsModel
    @Binding var draggingId: String?

    func validateDrop(info: DropInfo) -> Bool {
        draggingId != nil
    }

    func dropEntered(info: DropInfo) {
        guard let draggingId, draggingId != target.id else {
            return
        }
        guard let sourceIndex = model.items.firstIndex(where: { $0.id == draggingId }),
              let destinationIndex = model.items.firstIndex(where: { $0.id == target.id }) else {
            return
        }
        model.move(from: sourceIndex, to: destinationIndex)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingId = nil
        return true
    }
}
