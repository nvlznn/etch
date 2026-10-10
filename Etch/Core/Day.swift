import Foundation

/// A calendar day as the user saw it on their own clock, with no time of day attached.
///
/// Check-ins are stored as `yyyyMMdd` integers (e.g. `20261011`), never as `Date`s: a `Date` is an
/// instant, and the same instant is a different day in Taipei and in Tokyo. Recording the local
/// day once, at the moment of the check-in, means travel and daylight-saving changes can never
/// split one day into two.
///
/// Internally a `Day` is a serial number (days since 1970-01-01 in the proleptic Gregorian
/// calendar). Serial numbers have no time zones and no DST, so "yesterday" is always `serial - 1`.
nonisolated struct Day: Hashable, Comparable, Sendable {
    /// Days since 1970-01-01.
    let serial: Int

    init(serial: Int) {
        self.serial = serial
    }

    init?(year: Int, month: Int, day: Int) {
        guard (1...12).contains(month),
              (1...Day.length(ofMonth: month, year: year)).contains(day)
        else { return nil }
        serial = Day.serial(year: year, month: month, day: day)
    }

    /// Parses the stored form, e.g. `20261011`. Returns `nil` for impossible dates like `20260230`.
    init?(yyyyMMdd value: Int) {
        self.init(year: value / 10000, month: value / 100 % 100, day: value % 100)
    }

    /// The day `date` falls on for someone whose clock is set to `timeZone`.
    init(_ date: Date, timeZone: TimeZone = .current) {
        let parts = Calendar(identifier: .gregorian).dateComponents(in: timeZone, from: date)
        serial = Day.serial(year: parts.year!, month: parts.month!, day: parts.day!)
    }

    static func today(timeZone: TimeZone = .current, now: Date = .now) -> Day {
        Day(now, timeZone: timeZone)
    }

    /// The stored form, e.g. `20261011`.
    var yyyyMMdd: Int {
        let (y, m, d) = civil
        return y * 10000 + m * 100 + d
    }

    var year: Int { civil.year }
    var month: Int { civil.month }
    var dayOfMonth: Int { civil.day }

    /// 1 = Sunday … 7 = Saturday, the same numbering as `Calendar.weekday`.
    var weekday: Int {
        // 1970-01-01 was a Thursday (5).
        (serial + 4).modulo(7) + 1
    }

    func adding(days: Int) -> Day {
        Day(serial: serial + days)
    }

    /// Local midnight of this day, for formatting. Never use the result for comparisons.
    func date(timeZone: TimeZone = .current) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let (y, m, d) = civil
        return calendar.date(from: DateComponents(year: y, month: m, day: d))!
    }

    static func < (lhs: Day, rhs: Day) -> Bool {
        lhs.serial < rhs.serial
    }
}

// MARK: - Weeks

nonisolated extension Day {
    /// The first day of the week containing this day. `firstWeekday` uses `Calendar` numbering
    /// (1 = Sunday, 2 = Monday, …), normally `Calendar.current.firstWeekday`.
    func startOfWeek(firstWeekday: Int) -> Day {
        adding(days: -row(firstWeekday: firstWeekday))
    }

    /// This day's position within its week, 0…6, counted from `firstWeekday`.
    func row(firstWeekday: Int) -> Int {
        (weekday - firstWeekday).modulo(7)
    }
}

/// A run of whole weeks laid out the way Etch draws them: one column per week, one row per
/// weekday, each column starting on the locale's first day of the week.
nonisolated struct WeekGrid: Hashable, Sendable {
    /// The top-left day. Always falls on `firstWeekday`.
    let start: Day
    let weeks: Int
    let firstWeekday: Int

    init(start: Day, weeks: Int, firstWeekday: Int) {
        self.start = start.startOfWeek(firstWeekday: firstWeekday)
        self.weeks = weeks
        self.firstWeekday = firstWeekday
    }

    /// `weeks` columns whose last column is the week containing `day`.
    static func ending(at day: Day, weeks: Int, firstWeekday: Int) -> WeekGrid {
        let lastColumn = day.startOfWeek(firstWeekday: firstWeekday)
        return WeekGrid(start: lastColumn.adding(days: -7 * (weeks - 1)), weeks: weeks, firstWeekday: firstWeekday)
    }

    /// Number of week columns needed to show every day from `first` through `last`.
    static func weeks(from first: Day, through last: Day, firstWeekday: Int) -> Int {
        let a = first.startOfWeek(firstWeekday: firstWeekday)
        let b = last.startOfWeek(firstWeekday: firstWeekday)
        return max(0, (b.serial - a.serial) / 7) + 1
    }

    var end: Day { start.adding(days: weeks * 7 - 1) }

    func day(column: Int, row: Int) -> Day {
        start.adding(days: column * 7 + row)
    }

    func position(of day: Day) -> (column: Int, row: Int)? {
        let offset = day.serial - start.serial
        guard offset >= 0, offset < weeks * 7 else { return nil }
        return (offset / 7, offset % 7)
    }
}

// MARK: - Gregorian arithmetic

nonisolated private extension Day {
    // Howard Hinnant's `days_from_civil` / `civil_from_days`:
    // https://howardhinnant.github.io/date_algorithms.html

    static func serial(year: Int, month: Int, day: Int) -> Int {
        let y = month <= 2 ? year - 1 : year
        let era = (y >= 0 ? y : y - 399) / 400
        let yearOfEra = y - era * 400
        let shiftedMonth = (month + 9) % 12 // March = 0
        let dayOfYear = (153 * shiftedMonth + 2) / 5 + day - 1
        let dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
        return era * 146_097 + dayOfEra - 719_468
    }

    var civil: (year: Int, month: Int, day: Int) {
        let z = serial + 719_468
        let era = (z >= 0 ? z : z - 146_096) / 146_097
        let dayOfEra = z - era * 146_097
        let yearOfEra = (dayOfEra - dayOfEra / 1460 + dayOfEra / 36524 - dayOfEra / 146_096) / 365
        let dayOfYear = dayOfEra - (365 * yearOfEra + yearOfEra / 4 - yearOfEra / 100)
        let shiftedMonth = (5 * dayOfYear + 2) / 153
        let day = dayOfYear - (153 * shiftedMonth + 2) / 5 + 1
        let month = shiftedMonth < 10 ? shiftedMonth + 3 : shiftedMonth - 9
        return (yearOfEra + era * 400 + (month <= 2 ? 1 : 0), month, day)
    }

    static func length(ofMonth month: Int, year: Int) -> Int {
        switch month {
        case 2: (year % 4 == 0 && year % 100 != 0) || year % 400 == 0 ? 29 : 28
        case 4, 6, 9, 11: 30
        default: 31
        }
    }
}

nonisolated private extension Int {
    /// Mathematical modulo: always in `0..<n`, even for negative `self`.
    func modulo(_ n: Int) -> Int {
        let r = self % n
        return r < 0 ? r + n : r
    }
}
