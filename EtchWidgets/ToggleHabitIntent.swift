import AppIntents
import SwiftData
import WidgetKit

/// Marks a habit done or not done on a day, from a widget. Runs in the widget extension, writing
/// straight to the shared store; WidgetKit reloads the widget afterwards.
struct ToggleHabitIntent: AppIntent {
    static let title: LocalizedStringResource = "Check In"
    static let isDiscoverable = false

    @Parameter(title: "Habit")
    var habitID: String

    /// `yyyyMMdd`, as stored. See `Day`.
    @Parameter(title: "Day")
    var day: Int

    init() {}

    init(habitID: String, day: Day) {
        self.habitID = habitID
        self.day = day.yyyyMMdd
    }

    func perform() async throws -> some IntentResult {
        guard let id = HabitID.decode(habitID), let target = Day(yyyyMMdd: day) else { return .result() }
        let context = ModelContext(try Store.makeContainer())
        var match = FetchDescriptor<Habit>(predicate: #Predicate { $0.persistentModelID == id })
        match.fetchLimit = 1
        guard let habit = try context.fetch(match).first else { return .result() }

        habit.toggle(on: target)
        try context.save()
        Store.noteWidgetEdit()
        return .result()
    }
}
