import Foundation
import SwiftData
import WidgetKit

/// A habit as a widget needs it: plain values, read once from the store.
struct HabitSnapshot: Identifiable, Hashable {
    /// The habit's `PersistentIdentifier`, encoded so an intent can carry it. See `ToggleHabitIntent`.
    let id: String
    let name: String
    let done: Set<Day>
}

struct HabitsEntry: TimelineEntry {
    let date: Date
    let today: Day
    let habits: [HabitSnapshot]
}

struct HabitsProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitsEntry {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitsEntry) -> Void) {
        let entry = Self.load()
        // The widget gallery shows a made-up example until there is something real to show.
        completion(context.isPreview && entry.habits.isEmpty ? .sample : entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitsEntry>) -> Void) {
        let entry = Self.load()
        // Nothing changes on its own until the day does. Check-ins reload the timeline themselves.
        let midnight = entry.today.adding(days: 1).date()
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    static func load() -> HabitsEntry {
        let today = Day.today()
        let habits: [Habit] = (try? Store.makeContainer()).flatMap { container in
            let all = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)])
            return try? ModelContext(container).fetch(all)
        } ?? []
        let snapshots = habits.compactMap { habit in
            HabitID.encode(habit.persistentModelID).map {
                HabitSnapshot(id: $0, name: habit.name, done: habit.doneDays)
            }
        }
        return HabitsEntry(date: .now, today: today, habits: snapshots)
    }
}

/// Turns a habit's `PersistentIdentifier` into a string an intent parameter can hold, and back.
enum HabitID {
    static func encode(_ id: PersistentIdentifier) -> String? {
        (try? JSONEncoder().encode(id)).flatMap { String(data: $0, encoding: .utf8) }
    }

    static func decode(_ string: String) -> PersistentIdentifier? {
        try? JSONDecoder().decode(PersistentIdentifier.self, from: Data(string.utf8))
    }
}

extension HabitsEntry {
    /// For the widget gallery and placeholders.
    static var sample: HabitsEntry {
        let today = Day.today()
        let names = ["Read 20 pages", "Meditate", "Run", "Journal"]
        let habits = names.enumerated().map { index, name in
            let done = (0..<210).filter { ($0 * (index + 3)) % 7 < 4 }.map { today.adding(days: -$0) }
            return HabitSnapshot(id: "sample-\(index)", name: name, done: Set(done))
        }
        return HabitsEntry(date: .now, today: today, habits: habits)
    }
}
