import Foundation
import SwiftData
@testable import Etch

/// Runs `body` with a habit living in a throwaway in-memory store, so tests exercise the real
/// model code. The store stays alive for the whole of `body`.
@MainActor
func withHabit(_ body: (Habit) throws -> Void) throws {
    let container = try ModelContainer(
        for: Habit.self, CheckIn.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let habit = Habit(name: "Read", sortOrder: 0)
    container.mainContext.insert(habit)
    try withExtendedLifetime(container) { try body(habit) }
}

extension Day {
    /// Test shorthand: `Day(20261011)`.
    init(_ yyyyMMdd: Int) {
        self.init(yyyyMMdd: yyyyMMdd)!
    }
}

extension Date {
    /// Test shorthand for an ISO 8601 instant, e.g. `Date("2026-10-11T01:00:00Z")`.
    init(_ iso: String) {
        self = try! Date(iso, strategy: .iso8601)
    }
}

extension TimeZone {
    static let taipei = TimeZone(identifier: "Asia/Taipei")!
    static let tokyo = TimeZone(identifier: "Asia/Tokyo")!
    static let newYork = TimeZone(identifier: "America/New_York")!
}
