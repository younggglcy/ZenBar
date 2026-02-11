import XCTest
@testable import ZenBarApp

final class HiddenItemsStoreTests: XCTestCase {
    func testRoundTrip() {
        let baseURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = HiddenItemsStore(baseURL: baseURL)
        let item = HiddenItem(
            id: "com.example.test",
            bundleId: "com.example.test",
            displayName: "Test",
            iconData: nil,
            hiddenOrder: 0,
            lastSeen: Date(),
            originalX: nil,
            originalY: nil
        )

        store.save([item])
        let loaded = store.load()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.id, item.id)
        XCTAssertEqual(loaded.first?.bundleId, item.bundleId)
        XCTAssertEqual(loaded.first?.displayName, item.displayName)
        XCTAssertEqual(loaded.first?.hiddenOrder, item.hiddenOrder)
    }
}
