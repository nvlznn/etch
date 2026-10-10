/// Streaks and totals for one habit. Always computed from the check-ins, never stored.
nonisolated struct Stats: Equatable, Sendable {
    /// Consecutive days ending today, or ending yesterday if today isn't checked yet —
    /// the streak isn't broken until a whole day has gone by.
    let currentStreak: Int
    let longestStreak: Int
    let total: Int

    init(days: some Sequence<Day>, today: Day) {
        let serials = Set(days.lazy.map(\.serial))
        total = serials.count

        var longest = 0
        var run = 0
        var previous: Int?
        for serial in serials.sorted() {
            run = previous == serial - 1 ? run + 1 : 1
            longest = max(longest, run)
            previous = serial
        }
        longestStreak = longest

        var cursor = serials.contains(today.serial) ? today.serial : today.serial - 1
        var current = 0
        while serials.contains(cursor) {
            current += 1
            cursor -= 1
        }
        currentStreak = current
    }
}
