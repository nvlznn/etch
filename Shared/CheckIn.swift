import SwiftData

@Model
final class CheckIn {
    /// The user's local calendar day as `yyyyMMdd`, e.g. `20261011`. See `Day`.
    var day: Int
    var habit: Habit?

    init(day: Day) {
        self.day = day.yyyyMMdd
    }
}
