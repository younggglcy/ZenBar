import SwiftUI
import AppKit

struct HiddenListView: View {
    @ObservedObject var model: HiddenItemsModel
    let onItemPressed: (HiddenItem) -> Void
    let onUnhide: (HiddenItem) -> Void
    @State private var draggedItem: HiddenItem?
    @State private var dragOffset: CGSize = .zero
    @State private var isDraggedOutside: Bool = false

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
            Text("If already enabled, remove ZenBar from the list and add it again.")
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
            Text("Drag any status bar icon and drop it on the ZenBar icon to hide it.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.4))
        .cornerRadius(8)
    }

    private var listView: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(model.items) { item in
                        itemRow(for: item, in: geometry)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .frame(height: min(CGFloat(model.items.count) * 36.0 + 8.0, 260))
        .coordinateSpace(name: "listArea")
    }

    private func itemRow(for item: HiddenItem, in geometry: GeometryProxy) -> some View {
        let isDragging = draggedItem?.id == item.id

        return HStack {
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
        .opacity(isDragging ? (isDraggedOutside ? 0.3 : 0.6) : 1.0)
        .offset(isDragging ? dragOffset : .zero)
        .animation(.interactiveSpring(), value: isDragging)
        .gesture(
            DragGesture(minimumDistance: 8, coordinateSpace: .named("listArea"))
                .onChanged { value in
                    if draggedItem == nil {
                        draggedItem = item
                    }
                    dragOffset = value.translation
                    let listBounds = geometry.frame(in: .named("listArea"))
                    let loc = value.location
                    isDraggedOutside = loc.x < listBounds.minX || loc.x > listBounds.maxX
                        || loc.y < listBounds.minY || loc.y > listBounds.maxY
                }
                .onEnded { _ in
                    if isDraggedOutside, let dragged = draggedItem {
                        onUnhide(dragged)
                    }
                    draggedItem = nil
                    dragOffset = .zero
                    isDraggedOutside = false
                }
        )
        .simultaneousGesture(
            TapGesture().onEnded {
                if draggedItem == nil {
                    onItemPressed(item)
                }
            }
        )
        .contextMenu {
            Button("Unhide") {
                onUnhide(item)
            }
        }
    }
}
