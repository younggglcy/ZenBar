import Foundation

final class HiddenItemsStore {
    private let baseURL: URL
    private let fileManager: FileManager

    init(baseURL: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let baseURL {
            self.baseURL = baseURL
        } else {
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            self.baseURL = appSupport?.appendingPathComponent("ZenBar", isDirectory: true) ?? fileManager.temporaryDirectory
        }
    }

    private var fileURL: URL {
        baseURL.appendingPathComponent("hidden_items.json")
    }

    func load() -> [HiddenItem] {
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([HiddenItem].self, from: data)
        } catch {
            return []
        }
    }

    func save(_ items: [HiddenItem]) {
        do {
            try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            return
        }
    }
}
