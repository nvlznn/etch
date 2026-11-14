import Testing
@testable import Etch

struct PlanTests {
    @Test func freePlanHoldsThreeHabits() {
        #expect(Plan.freeHabitLimit == 3)
        #expect(Plan.canAddHabit(active: 0, isPro: false))
        #expect(Plan.canAddHabit(active: 2, isPro: false))
        #expect(!Plan.canAddHabit(active: 3, isPro: false))
    }

    /// Someone who already has more than the limit keeps every habit but can't add another.
    @Test func overTheLimitCannotAdd() {
        #expect(!Plan.canAddHabit(active: 4, isPro: false))
        #expect(!Plan.canAddHabit(active: 20, isPro: false))
    }

    @Test func proHasNoLimit() {
        #expect(Plan.canAddHabit(active: 3, isPro: true))
        #expect(Plan.canAddHabit(active: 500, isPro: true))
    }

    @Test func onlyProCanUnarchive() {
        #expect(!Plan.canUnarchive(isPro: false))
        #expect(Plan.canUnarchive(isPro: true))
    }
}
