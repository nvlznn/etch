#if DEBUG
import Foundation
import SwiftData

/// Launch arguments for development, performance checks and screenshots. None of this ships.
///
///     -EtchInMemory       start from a throwaway, empty store
///     -EtchSeed <n>       add n habits with up to a year of history (only into an empty store)
///     -EtchCatalog        show the design-system catalog instead of the app
///     -EtchTab log        start on the Log tab
///     -EtchOpenFirst      on the Log tab, open the first habit's detail page
///     -EtchRenderIcon     write AppIcon.png to the app's Documents folder
enum DebugLaunch {
    private static let arguments = ProcessInfo.processInfo.arguments

    static var inMemory: Bool { arguments.contains("-EtchInMemory") }
    static var showsCatalog: Bool { arguments.contains("-EtchCatalog") }
    static var startsOnLog: Bool { value(after: "-EtchTab") == "log" }
    static var opensFirstHabit: Bool { arguments.contains("-EtchOpenFirst") }
    static var rendersIcon: Bool { arguments.contains("-EtchRenderIcon") }

    private static func value(after flag: String) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }

    static func seedIfRequested(_ context: ModelContext) {
        guard let count = value(after: "-EtchSeed").flatMap(Int.init), count > 0,
              (try? context.fetchCount(FetchDescriptor<Habit>())) == 0
        else { return }
        seed(count, into: context)
    }

    /// Adds `count` habits with deterministic, plausible histories.
    static func seed(_ count: Int, into context: ModelContext) {
        let names = [
            "Read 20 pages", "Meditate", "Run", "Stretch", "Journal", "No sugar", "Floss",
            "Drink water", "Practice piano", "Walk 8k steps", "Learn Japanese", "Cold shower",
            "No phone in bed", "Push-ups", "Cook dinner", "Call family", "Tidy desk",
            "Sketch", "Vitamins", "Lights out by 11",
        ]
        var random = SeededRandom(seed: 2026)
        let today = Day.today()
        for index in 0..<count {
            // Most habits are a year or more old; every fourth is only a few weeks old.
            let age = index % 4 == 3 ? 20 + index : 380 + index * 3
            let firstDay = today.adding(days: -age)
            let habit = Habit(
                name: names[index % names.count],
                sortOrder: index,
                createdAt: firstDay.date().addingTimeInterval(9 * 3600)
            )
            context.insert(habit)
            let rate = 0.5 + Double(index % 5) * 0.1
            for offset in 0...age where random.unit() < rate {
                habit.checkIns.append(CheckIn(day: firstDay.adding(days: offset)))
            }
        }
        try? context.save()
    }
}

/// In-memory stores for SwiftUI previews.
enum PreviewStore {
    static var empty: ModelContainer { make(habits: 0) }
    static var withHabits: ModelContainer { make(habits: 6) }

    static var firstHabit: Habit {
        let context = withHabits.mainContext
        let first = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)])
        return try! context.fetch(first).first!
    }

    private static func make(habits: Int) -> ModelContainer {
        let container = try! ModelContainer(
            for: Habit.self, CheckIn.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        DebugLaunch.seed(habits, into: container.mainContext)
        return container
    }
}

private struct SeededRandom {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func unit() -> Double {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Double(state >> 11) / Double(1 << 53)
    }
}
#endif
