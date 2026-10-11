import Foundation
import SwiftData

/// The habit store, shared by the app and its widgets through an App Group.
nonisolated enum Store {
    static let appGroup = "group.dev.noky.etch"

    static let schema = Schema([Habit.self, CheckIn.self])

    /// Opens the shared store. On this device only: no CloudKit, no network.
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = if inMemory {
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        } else {
            ModelConfiguration(schema: schema, groupContainer: .identifier(appGroup), cloudKitDatabase: .none)
        }
        return try ModelContainer(for: schema, configurations: configuration)
    }

    /// Before widgets, the store lived in the app's own container, where widgets can't reach it.
    /// Copies it into the App Group once, if the shared store doesn't exist yet. App only.
    static func moveIntoAppGroupIfNeeded() {
        let files = FileManager.default
        guard let shared = files.containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appending(path: "Library/Application Support", directoryHint: .isDirectory)
        else { return }
        let old = URL.applicationSupportDirectory
        let name = "default.store"
        guard files.fileExists(atPath: old.appending(path: name).path()),
              !files.fileExists(atPath: shared.appending(path: name).path())
        else { return }

        try? files.createDirectory(at: shared, withIntermediateDirectories: true)
        // The SQLite database and its journal files travel together.
        for suffix in ["", "-shm", "-wal"] {
            let source = old.appending(path: name + suffix)
            guard files.fileExists(atPath: source.path()) else { continue }
            try? files.copyItem(at: source, to: shared.appending(path: name + suffix))
        }
    }

    // MARK: Edits from widgets

    private static let widgetEditKey = "widgetEdit"
    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    /// Called by a widget after it changes the store, so the app knows its in-memory copy is stale.
    static func noteWidgetEdit() {
        defaults?.set(UUID().uuidString, forKey: widgetEditKey)
    }

    /// Changes whenever a widget edits the store.
    static var widgetEdit: String? {
        defaults?.string(forKey: widgetEditKey)
    }
}
