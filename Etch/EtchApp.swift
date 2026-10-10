import SwiftData
import SwiftUI

@main
struct EtchApp: App {
    private let container = EtchApp.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(.white)
        }
        .modelContainer(container)
    }

    private static func makeContainer() -> ModelContainer {
        var inMemory = false
        #if DEBUG
        inMemory = DebugLaunch.inMemory
        #endif

        let schema = Schema([Habit.self, CheckIn.self])
        // On this device only: no CloudKit, no network.
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)
        do {
            let container = try ModelContainer(for: schema, configurations: configuration)
            #if DEBUG
            DebugLaunch.seedIfRequested(container.mainContext)
            #endif
            return container
        } catch {
            fatalError("Could not open the habit store: \(error)")
        }
    }
}
