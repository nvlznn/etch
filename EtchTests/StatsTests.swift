import Testing
@testable import Etch

struct StatsTests {
    let today = Day(20261011)

    /// Days relative to today: `days(0, -1)` is today and yesterday.
    func days(_ offsets: Int...) -> [Day] {
        offsets.map { today.adding(days: $0) }
    }

    // MARK: Current streak

    @Test func currentStreakIncludesToday() {
        #expect(Stats(days: days(0, -1, -2), today: today).currentStreak == 3)
    }

    @Test func currentStreakSurvivesUntilTodayIsOver() {
        // Today isn't checked yet, but yesterday was: the streak is still alive.
        #expect(Stats(days: days(-1, -2), today: today).currentStreak == 2)
    }

    @Test func currentStreakResetsAfterAMissedDay() {
        #expect(Stats(days: days(-2, -3, -4), today: today).currentStreak == 0)
        #expect(Stats(days: days(0, -2, -3), today: today).currentStreak == 1)
    }

    @Test func currentStreakCrossesMonthsAndYears() {
        let newYear = Day(20270102)
        let days = [Day(20261230), Day(20261231), Day(20270101), Day(20270102)]
        #expect(Stats(days: days, today: newYear).currentStreak == 4)
    }

    // MARK: Longest streak

    @Test func longestStreakAcrossABreak() {
        let stats = Stats(days: days(-10, -9, -8, -5, -4, -1, 0), today: today)
        #expect(stats.longestStreak == 3)
        #expect(stats.currentStreak == 2)
    }

    @Test func longestStreakOfOneDay() {
        #expect(Stats(days: days(-30), today: today).longestStreak == 1)
    }

    @Test func noCheckIns() {
        let stats = Stats(days: [Day](), today: today)
        #expect(stats == Stats(days: [], today: today))
        #expect(stats.currentStreak == 0)
        #expect(stats.longestStreak == 0)
        #expect(stats.total == 0)
    }

    @Test func longestStreakAcrossALeapDay() {
        let days = [Day(20280227), Day(20280228), Day(20280229), Day(20280301)]
        #expect(Stats(days: days, today: Day(20280310)).longestStreak == 4)
    }

    // MARK: Total

    @Test func totalCountsEachDayOnce() {
        #expect(Stats(days: days(0, -3, -7, -100), today: today).total == 4)
        #expect(Stats(days: days(0, 0, -1), today: today).total == 2)
    }

    // MARK: Backfilling

    @Test @MainActor func backfillingJoinsStreaks() throws {
        try withHabit { habit in
            for offset in [0, -2, -3] {
                habit.setDone(true, on: today.adding(days: offset))
            }
            var stats = Stats(days: habit.doneDays, today: today)
            #expect(stats.currentStreak == 1)
            #expect(stats.longestStreak == 2)
            #expect(stats.total == 3)

            // The user remembers they did it yesterday after all.
            habit.setDone(true, on: today.adding(days: -1))
            stats = Stats(days: habit.doneDays, today: today)
            #expect(stats.currentStreak == 4)
            #expect(stats.longestStreak == 4)
            #expect(stats.total == 4)

            // …and then un-marks a day in the middle.
            habit.setDone(false, on: today.adding(days: -2))
            stats = Stats(days: habit.doneDays, today: today)
            #expect(stats.currentStreak == 2)
            #expect(stats.longestStreak == 2)
            #expect(stats.total == 3)
        }
    }
}
