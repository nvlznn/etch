import SwiftData
import SwiftUI
import WidgetKit

@main
struct EtchApp: App {
    @State private var container = EtchApp.makeContainer()
    /// The last widget edit this app has loaded; see `Store.widgetEdit`.
    @State private var seenWidgetEdit = Store.widgetEdit
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                // A fresh container means fresh views: nothing may hold models from the old one.
                .id(ObjectIdentifier(container))
                .preferredColorScheme(.dark)
                .tint(.white)
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                // A check-in made from a widget went straight to the store; reload to see it.
                if Store.widgetEdit != seenWidgetEdit {
                    seenWidgetEdit = Store.widgetEdit
                    container = EtchApp.makeContainer()
                }
            case .background:
                WidgetCenter.shared.reloadAllTimelines()
            default:
                break
            }
        }
    }

    private static func makeContainer() -> ModelContainer {
        var inMemory = false
        #if DEBUG
        inMemory = DebugLaunch.inMemory || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        #endif

        if !inMemory { Store.moveIntoAppGroupIfNeeded() }
        do {
            let container = try Store.makeContainer(inMemory: inMemory)
            #if DEBUG
            DebugLaunch.seedIfRequested(container.mainContext)
            #endif
            return container
        } catch {
            fatalError("Could not open the habit store: \(error)")
        }
    }
}
