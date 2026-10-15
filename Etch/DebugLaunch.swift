#if DEBUG
import Foundation
import SwiftData

/// Launch arguments for development, performance checks and screenshots. None of this ships.
///
///     -EtchInMemory       start from a throwaway, empty store
///     -EtchSeed <n>       add n habits with up to a year of history (only into an empty store)
///     -EtchScreenshots    add the nine App Store screenshot habits, named in the app's language
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
        if arguments.contains("-EtchScreenshots"), (try? context.fetchCount(FetchDescriptor<Habit>())) == 0 {
            seedShowcase(into: context)
            return
        }
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
                habit.checkIns = (habit.checkIns ?? []) + [CheckIn(day: firstDay.adding(days: offset))]
            }
        }
        try? context.save()
    }
}

extension DebugLaunch {
    private struct Showcase {
        let name: (en: String, zh: String)
        var note: (en: String, zh: String) = ("", "")
        /// Share of days done.
        let rate: Double
        /// Weekdays (1 = Sunday) the habit is planned for; nil for every day.
        var weekdays: Set<Int>? = nil
        var age = 400
        /// The last seven days, oldest first and ending today ("1" = done), so the 7-day Log looks deliberate.
        let week: String
    }

    private static let showcase: [Showcase] = [
        Showcase(name: ("Read 20 pages", "閱讀 20 頁"),
                 note: ("Before bed, paper books only. Currently: The Remains of the Day.", "睡前讀，只讀紙本書。正在讀：《長日將盡》。"),
                 rate: 0.86, week: "1111111"),
        Showcase(name: ("Meditate", "冥想"), note: ("10 minutes after waking up.", "起床後 10 分鐘。"),
                 rate: 0.8, week: "1100111"),
        Showcase(name: ("Run", "跑步"), note: ("5 km along the river.", "河濱 5 公里。"),
                 rate: 0.85, weekdays: [2, 5, 7], week: "0101010"),
        Showcase(name: ("Drink water", "喝水"), note: ("2 liters.", "2000 毫升。"), rate: 0.9, week: "1111011"),
        Showcase(name: ("Stretch", "伸展"), rate: 0.72, week: "1110110"),
        Showcase(name: ("Journal", "寫日記"), rate: 0.76, week: "1011101"),
        Showcase(name: ("Practice piano", "練鋼琴"), note: ("Scales first, then the Chopin nocturne.", "先練音階，再練蕭邦夜曲。"),
                 rate: 0.66, week: "0110100"),
        Showcase(name: ("Learn Japanese", "學日文"), rate: 0.84, age: 52, week: "1111011"),
        Showcase(name: ("Lights out by 11", "11 點前睡覺"), rate: 0.7, week: "1011110"),
    ]

    /// Streaky, believable histories for the App Store screenshots: a done day is usually followed by another.
    static func seedShowcase(into context: ModelContext) {
        let chinese = Locale.preferredLanguages.first?.hasPrefix("zh") == true
        var random = SeededRandom(seed: 11)
        let today = Day.today()
        let calendar = Calendar.current
        for (index, item) in showcase.enumerated() {
            let firstDay = today.adding(days: -item.age)
            let habit = Habit(
                name: chinese ? item.name.zh : item.name.en,
                sortOrder: index,
                createdAt: firstDay.date().addingTimeInterval(9 * 3600)
            )
            habit.notes = chinese ? item.note.zh : item.note.en
            context.insert(habit)

            // Two-state chain: stay done with `keep`; start again at the rate that makes `rate` the long-run share.
            let keep = 0.9
            let start = item.rate * (1 - keep) / (1 - item.rate)
            var done = false
            for offset in 0..<item.age - 6 {
                let day = firstDay.adding(days: offset)
                if let weekdays = item.weekdays {
                    done = weekdays.contains(calendar.component(.weekday, from: day.date()))
                        ? random.unit() < item.rate
                        : random.unit() < 0.04
                } else {
                    done = random.unit() < (done ? keep : start)
                }
                if done { habit.checkIns = (habit.checkIns ?? []) + [CheckIn(day: day)] }
            }
            for (offset, mark) in item.week.enumerated() where mark == "1" {
                habit.checkIns = (habit.checkIns ?? []) + [CheckIn(day: today.adding(days: offset - 6))]
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
