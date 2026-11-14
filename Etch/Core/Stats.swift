/// Streaks and totals for one habit. Always computed from the check-ins, never stored.
nonisolated struct Stats: Equatable, Sendable {
    /// Consecutive days ending today, or ending yesterday if today isn't checked yet —
    /// the streak isn't broken until a whole day has gone by.
    let currentStreak: Int
    let longestStreak: Int
    let total: Int

    /// `skipped` days are rest days the user chose: they neither break a streak nor count in it.
    init(days: some Sequence<Day>, skipped: some Sequence<Day> = [Day](), today: Day, weekdays: Int = 127) {
        let serials = Set(days.lazy.map(\.serial))
        let skippedSerials = Set(skipped.lazy.map(\.serial))
        total = serials.count

        func scheduled(_ serial: Int) -> Bool {
            weekdays & (1 << (Day(serial: serial).weekday - 1)) != 0 && !skippedSerials.contains(serial)
        }

        var longest = 0
        var run = 0
        if let first = serials.min(), let last = serials.max() {
            for serial in first...last {
                if serials.contains(serial) {
                    run += 1
                } else if scheduled(serial) {
                    run = 0
                }
                longest = max(longest, run)
            }
        }
        longestStreak = longest

        var current = 0
        if let first = serials.min() {
            var cursor = today.serial
            var maySkipToday = scheduled(today.serial) && !serials.contains(today.serial)
            while cursor >= first {
                if serials.contains(cursor) {
                    current += 1
                    maySkipToday = false
                } else if scheduled(cursor) {
                    if !maySkipToday { break }
                    maySkipToday = false
                }
                cursor -= 1
            }
        }
        currentStreak = current
    }
}
