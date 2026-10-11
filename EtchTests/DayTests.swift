import Foundation
import Testing
@testable import Etch

struct DayTests {
    // MARK: yyyyMMdd

    @Test(arguments: [
        (20261011, 20261012), // ordinary day
        (20261031, 20261101), // month boundary
        (20261231, 20270101), // year boundary
        (20280228, 20280229), // into a leap day
        (20280229, 20280301), // out of a leap day
        (20270228, 20270301), // no leap day in 2027
        (20000228, 20000229), // 2000 is a leap year (divisible by 400)
        (21000228, 21000301), // 2100 is not (divisible by 100)
    ])
    func nextDay(from: Int, to: Int) {
        #expect(Day(from).adding(days: 1).yyyyMMdd == to)
        #expect(Day(to).adding(days: -1).yyyyMMdd == from)
    }

    @Test(arguments: [20261011, 19700101, 20000229, 20280229, 20991231, 19691231])
    func roundTrips(_ value: Int) {
        #expect(Day(yyyyMMdd: value)?.yyyyMMdd == value)
    }

    @Test(arguments: [20270229, 21000229, 20261301, 20261000, 20260431, 20261032])
    func rejectsImpossibleDates(_ value: Int) {
        #expect(Day(yyyyMMdd: value) == nil)
    }

    @Test func serialArithmeticSpansYears() {
        #expect(Day(19700101).serial == 0)
        #expect(Day(20280101).serial - Day(20270101).serial == 365)
        #expect(Day(20290101).serial - Day(20280101).serial == 366)
    }

    @Test func ordering() {
        #expect(Day(20261231) < Day(20270101))
        #expect(Day(20261011) == Day(20261011))
    }

    // MARK: Local time

    @Test func dayDependsOnTheLocalClock() {
        // 15:30 UTC is 23:30 in Taipei but already 00:30 the next day in Tokyo.
        let instant = Date("2026-10-11T15:30:00Z")
        #expect(Day(instant, timeZone: .taipei) == Day(20261011))
        #expect(Day(instant, timeZone: .tokyo) == Day(20261012))
    }

    @Test func midnightIsTheBoundary() {
        #expect(Day(Date("2026-10-11T15:59:59Z"), timeZone: .taipei) == Day(20261011))
        #expect(Day(Date("2026-10-11T16:00:00Z"), timeZone: .taipei) == Day(20261012))
    }

    @Test @MainActor func flyingTaipeiToTokyoDoesNotDuplicateADay() throws {
        try withHabit { habit in
            // Morning check-in in Taipei: 09:00 local.
            let morning = Day(Date("2026-10-11T01:00:00Z"), timeZone: .taipei)
            habit.setDone(true, on: morning)

            // Same evening in Tokyo, 20:00 local — still Oct 11 there, so it is the same day.
            let evening = Day(Date("2026-10-11T11:00:00Z"), timeZone: .tokyo)
            #expect(evening == morning)
            #expect(habit.isDone(on: evening))
            habit.setDone(true, on: evening)

            #expect(habit.checkIns.count == 1)
            #expect(habit.checkIns.first?.day == 20261011)
        }
    }

    @Test @MainActor func checkingInTwiceStoresOneRecord() throws {
        try withHabit { habit in
            habit.setDone(true, on: Day(20261011))
            habit.setDone(true, on: Day(20261011))
            #expect(habit.checkIns.count == 1)

            habit.toggle(on: Day(20261011))
            #expect(habit.checkIns.isEmpty)
            #expect(!habit.isDone(on: Day(20261011)))
        }
    }

    @Test func daylightSavingDoesNotSkipOrRepeatDays() {
        // New York springs forward on 2026-03-08 (a 23-hour day) and falls back on 2026-11-01 (25 hours).
        for value in [20260307, 20260308, 20260309, 20261031, 20261101, 20261102] {
            let day = Day(value)
            let midnight = day.date(timeZone: .newYork)
            let nextMidnight = day.adding(days: 1).date(timeZone: .newYork)
            #expect(Day(midnight, timeZone: .newYork) == day)
            #expect(Day(nextMidnight.addingTimeInterval(-1), timeZone: .newYork) == day)
            #expect(Day(nextMidnight, timeZone: .newYork) == day.adding(days: 1))
        }
    }

    // MARK: Weekdays and weeks

    @Test func weekdayMatchesFoundation() {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        for serial in stride(from: -800, through: 25_000, by: 37) {
            let day = Day(serial: serial)
            #expect(day.weekday == utc.component(.weekday, from: day.date(timeZone: utc.timeZone)))
        }
        #expect(Day(20261011).weekday == 1) // a Sunday
    }

    @Test func sundayFirstWeeks() {
        // Wed 2026-10-14 belongs to the week Sun Oct 11 – Sat Oct 17.
        #expect(Day(20261014).startOfWeek(firstWeekday: 1) == Day(20261011))
        #expect(Day(20261011).startOfWeek(firstWeekday: 1) == Day(20261011))
        #expect(Day(20261017).startOfWeek(firstWeekday: 1) == Day(20261011))
        #expect(Day(20261011).row(firstWeekday: 1) == 0)
        #expect(Day(20261017).row(firstWeekday: 1) == 6)
    }

    @Test func mondayFirstWeeks() {
        // With Monday first, Sun Oct 11 is the *last* day of the week that began Mon Oct 5.
        #expect(Day(20261014).startOfWeek(firstWeekday: 2) == Day(20261012))
        #expect(Day(20261011).startOfWeek(firstWeekday: 2) == Day(20261005))
        #expect(Day(20261011).row(firstWeekday: 2) == 6)
        #expect(Day(20261012).row(firstWeekday: 2) == 0)
    }

    @Test(arguments: ["en_US", "zh_TW", "en_GB", "de_DE", "ar_EG"])
    func weeksMatchTheLocale(identifier: String) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: identifier)
        calendar.timeZone = .taipei
        for offset in 0..<21 {
            let day = Day(20261001).adding(days: offset)
            let systemStart = calendar.dateInterval(of: .weekOfYear, for: day.date(timeZone: .taipei))!.start
            #expect(day.startOfWeek(firstWeekday: calendar.firstWeekday) == Day(systemStart, timeZone: .taipei))
        }
    }

    @Test(arguments: [1, 2, 7])
    func gridEndsOnTheWeekContainingToday(firstWeekday: Int) throws {
        let today = Day(20261014)
        let grid = WeekGrid.ending(at: today, weeks: 16, firstWeekday: firstWeekday)

        #expect(grid.start.weekday == firstWeekday)
        #expect(grid.end.serial - grid.start.serial == 16 * 7 - 1)
        let position = try #require(grid.position(of: today))
        #expect(position.column == 15)
        #expect(position.row == today.row(firstWeekday: firstWeekday))
        #expect(grid.day(column: position.column, row: position.row) == today)
        #expect(grid.position(of: grid.end.adding(days: 1)) == nil)
        #expect(grid.position(of: grid.start.adding(days: -1)) == nil)
    }

    @Test func weeksSpanned() {
        // Sun Oct 11 → Wed Oct 14 is one Sunday-first week, but two Monday-first weeks.
        #expect(WeekGrid.weeks(from: Day(20261011), through: Day(20261014), firstWeekday: 1) == 1)
        #expect(WeekGrid.weeks(from: Day(20261011), through: Day(20261014), firstWeekday: 2) == 2)
        #expect(WeekGrid.weeks(from: Day(20251014), through: Day(20261014), firstWeekday: 1) == 53)
    }

    // MARK: Months

    @Test func monthBounds() {
        let october = Month(Day(20261014))
        #expect(october.first == Day(20261001))
        #expect(october.last == Day(20261031))
        #expect(Month(year: 2028, month: 2).length == 29)
        #expect(Month(year: 2027, month: 2).last == Day(20270228))
    }

    @Test func monthArithmeticCarriesIntoTheYear() {
        let october = Month(year: 2026, month: 10)
        #expect(october.adding(months: 3) == Month(year: 2027, month: 1))
        #expect(october.adding(months: -10) == Month(year: 2025, month: 12))
        #expect(october.adding(months: -22) == Month(year: 2024, month: 12))
        #expect(october.adding(months: 0) == october)
    }

    @Test func monthRange() {
        let months = Month.range(from: Month(year: 2025, month: 11), through: Month(year: 2026, month: 2))
        #expect(months.map(\.month) == [11, 12, 1, 2])
        #expect(Month.range(from: Month(year: 2026, month: 2), through: Month(year: 2025, month: 11)).isEmpty)
    }
}
