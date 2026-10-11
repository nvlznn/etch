import Foundation
import SwiftData
import SwiftUI

@Model
final class Habit {
    var name: String
    var createdAt: Date
    var sortOrder: Int
    /// Anything the user wants to remember about the habit: why, how, when. Empty when unused.
    var notes: String = ""
    @Relationship(deleteRule: .cascade, inverse: \CheckIn.habit) var checkIns: [CheckIn] = []

    init(name: String, sortOrder: Int, createdAt: Date = .now) {
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}

extension Habit {
    /// Every day this habit was done.
    var doneDays: Set<Day> {
        Set(checkIns.compactMap { Day(yyyyMMdd: $0.day) })
    }

    /// How far back this habit's history goes: the day it was created, or the earliest check-in
    /// if one was backfilled before that.
    var firstDay: Day {
        let created = Day(createdAt)
        let earliest = checkIns.lazy.compactMap { Day(yyyyMMdd: $0.day) }.min()
        return min(created, earliest ?? created)
    }

    func isDone(on day: Day) -> Bool {
        let key = day.yyyyMMdd
        return checkIns.contains { $0.day == key }
    }

    /// Records or clears `day`. A habit never has more than one check-in per day.
    func setDone(_ done: Bool, on day: Day) {
        let key = day.yyyyMMdd
        if done {
            guard !isDone(on: day) else { return }
            checkIns.append(CheckIn(day: day))
        } else {
            let removed = checkIns.filter { $0.day == key }
            checkIns.removeAll { $0.day == key }
            for checkIn in removed {
                modelContext?.delete(checkIn)
            }
        }
    }

    /// Flips `day` and returns the new state.
    @discardableResult
    func toggle(on day: Day) -> Bool {
        let done = !isDone(on: day)
        setDone(done, on: day)
        return done
    }

    /// Moves habits the way `Array.move(fromOffsets:toOffset:)` would, and keeps the new order in
    /// `sortOrder`. `habits` must be every habit, in their current order.
    static func reorder(_ habits: [Habit], fromOffsets source: IndexSet, toOffset destination: Int) {
        var reordered = habits
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, habit) in reordered.enumerated() where habit.sortOrder != index {
            habit.sortOrder = index
        }
    }

    /// The `sortOrder` for a habit added after every existing one.
    static func nextSortOrder(in context: ModelContext) -> Int {
        var last = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder, order: .reverse)])
        last.fetchLimit = 1
        return ((try? context.fetch(last).first?.sortOrder) ?? -1) + 1
    }
}
