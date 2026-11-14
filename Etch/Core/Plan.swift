/// What Etch Free allows. Etch Pro, a one-time purchase, has no limits.
///
/// Nothing here ever locks a habit that already exists: someone with more habits than the free
/// limit (from before the limit, or after a refund) keeps all of them, edits them and checks them in.
/// They just can't add more.
nonisolated enum Plan {
    /// How many habits Etch Free can have at once. Archived habits don't count.
    static let freeHabitLimit = 3

    /// Whether another habit may be added when `active` habits (not archived) exist.
    static func canAddHabit(active: Int, isPro: Bool) -> Bool {
        isPro || active < freeHabitLimit
    }

    /// Whether an archived habit may come back. Unarchiving is part of Etch Pro.
    static func canUnarchive(isPro: Bool) -> Bool {
        isPro
    }
}
