import SwiftData

@Model
final class CheckIn {
    /// The user's local calendar day as `yyyyMMdd`, e.g. `20261011`. See `Day`.
    var day: Int = 0
    /// A day the user skipped on purpose instead of doing the habit. It's a rest day for the
    /// streak: it doesn't break it and doesn't count as done.
    var isSkipped: Bool = false
    var habit: Habit?

    init(day: Day, isSkipped: Bool = false) {
        self.day = day.yyyyMMdd
        self.isSkipped = isSkipped
    }
}
