import Foundation
import SwiftData
import SwiftUI

@Model
final class Habit {
    var name: String = ""
    var createdAt: Date = Date.now
    var sortOrder: Int = 0
    /// Bits 0...6 are Sunday...Saturday. All days is the default for existing habits.
    var weekdays: Int = 127
    /// Anything the user wants to remember about the habit: why, how, when. Empty when unused.
    var notes: String = ""
    /// When the habit was archived: off Check-In, the Log and the widgets, its history kept and
    /// listed in Settings. `nil` while it's tracked.
    var archivedAt: Date?
    @Relationship(deleteRule: .cascade, inverse: \CheckIn.habit) var checkIns: [CheckIn]?

    init(name: String, sortOrder: Int, createdAt: Date = .now) {
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}

extension Habit {
    /// Every day this habit was done.
    var doneDays: Set<Day> {
        Set((checkIns ?? []).lazy.filter { !$0.isSkipped }.compactMap { Day(yyyyMMdd: $0.day) })
    }

    /// Every day the user skipped on purpose.
    var skippedDays: Set<Day> {
        Set((checkIns ?? []).lazy.filter(\.isSkipped).compactMap { Day(yyyyMMdd: $0.day) })
    }

    /// The earliest recorded check-in, if any. Skipped days aren't check-ins.
    var firstCheckInDay: Day? {
        (checkIns ?? []).lazy.filter { !$0.isSkipped }.compactMap { Day(yyyyMMdd: $0.day) }.min()
    }

    /// How far back this habit's history goes: the day it was created, or the earliest check-in
    /// or skipped day if one was backfilled before that.
    var firstDay: Day {
        let created = Day(createdAt)
        let earliest = (checkIns ?? []).lazy.compactMap { Day(yyyyMMdd: $0.day) }.min()
        return min(created, earliest ?? created)
    }

    func isDone(on day: Day) -> Bool {
        let key = day.yyyyMMdd
        return (checkIns ?? []).contains { $0.day == key && !$0.isSkipped }
    }

    func isSkipped(on day: Day) -> Bool {
        let key = day.yyyyMMdd
        return (checkIns ?? []).contains { $0.day == key && $0.isSkipped }
    }

    /// Records or clears `day`. A habit never has more than one record per day, so checking in on
    /// a skipped day turns the skip into a check-in. Clearing leaves a skipped day alone.
    func setDone(_ done: Bool, on day: Day) {
        if done {
            guard !isDone(on: day) else { return }
            if let skip = record(on: day) {
                skip.isSkipped = false
            } else {
                addRecord(CheckIn(day: day))
            }
        } else {
            removeRecords(on: day) { !$0.isSkipped }
        }
    }

    /// Skips or unskips `day`. Skipping a day that was done replaces the check-in; unskipping
    /// leaves a done day alone.
    func setSkipped(_ skipped: Bool, on day: Day) {
        if skipped {
            guard !isSkipped(on: day) else { return }
            if let done = record(on: day) {
                done.isSkipped = true
            } else {
                addRecord(CheckIn(day: day, isSkipped: true))
            }
        } else {
            removeRecords(on: day) { $0.isSkipped }
        }
    }

    private func record(on day: Day) -> CheckIn? {
        let key = day.yyyyMMdd
        return (checkIns ?? []).first { $0.day == key }
    }

    private func addRecord(_ record: CheckIn) {
        var records = checkIns ?? []
        records.append(record)
        checkIns = records
    }

    private func removeRecords(on day: Day, where matches: (CheckIn) -> Bool) {
        let key = day.yyyyMMdd
        let removed = (checkIns ?? []).filter { $0.day == key && matches($0) }
        checkIns = (checkIns ?? []).filter { $0.day != key || !matches($0) }
        for checkIn in removed {
            modelContext?.delete(checkIn)
        }
    }

    var isArchived: Bool { archivedAt != nil }

    func archive() {
        archivedAt = .now
    }

    /// Tracks an archived habit again, after every other habit.
    func unarchive() {
        if let modelContext {
            sortOrder = Habit.nextSortOrder(in: modelContext)
        }
        archivedAt = nil
    }

    func isScheduled(on day: Day) -> Bool {
        weekdays & (1 << (day.weekday - 1)) != 0
    }

    /// Flips `day` and returns the new state.
    @discardableResult
    func toggle(on day: Day) -> Bool {
        let done = !isDone(on: day)
        setDone(done, on: day)
        return done
    }

    /// Moves habits the way `Array.move(fromOffsets:toOffset:)` would, and keeps the new order in
    /// `sortOrder`. `habits` must be every tracked habit, in their current order.
    static func reorder(_ habits: [Habit], fromOffsets source: IndexSet, toOffset destination: Int) {
        var reordered = habits
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, habit) in reordered.enumerated() where habit.sortOrder != index {
            habit.sortOrder = index
        }
    }

    /// What Check-In, the Log and the widgets show: every habit not archived, in the user's order.
    static var tracked: FetchDescriptor<Habit> {
        FetchDescriptor(
            predicate: #Predicate { $0.archivedAt == nil },
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
        )
    }

    /// Every archived habit, the latest first.
    static var archived: FetchDescriptor<Habit> {
        FetchDescriptor(
            predicate: #Predicate { $0.archivedAt != nil },
            sortBy: [SortDescriptor(\.archivedAt, order: .reverse)]
        )
    }

    /// The `sortOrder` for a habit added after every existing one.
    static func nextSortOrder(in context: ModelContext) -> Int {
        var last = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder, order: .reverse)])
        last.fetchLimit = 1
        return ((try? context.fetch(last).first?.sortOrder) ?? -1) + 1
    }
}
