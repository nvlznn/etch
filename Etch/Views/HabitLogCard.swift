import SwiftUI

/// A compact card: a habit's name over its last 26 weeks, small enough that four fit on one screen.
/// Sits in a `.pressable` button, which tells the card when it is held down.
struct HabitLogCard: View {
    static let weeks = 26

    let habit: Habit

    @Environment(\.today) private var today
    @Environment(\.isGraphitePressed) private var isPressed

    var body: some View {
        let done = habit.doneDays
        let grid = WeekGrid.ending(at: today, weeks: Self.weeks, firstWeekday: Calendar.current.firstWeekday)
        let doneInGrid = done.count { $0 >= grid.start && $0 <= today }

        VStack(alignment: .leading, spacing: 8) {
            Text(habit.name)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Graphite.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 2)

            DotGrid(grid: grid, done: done, today: today)
        }
        .padding(12)
        .background {
            GraphiteCard(
                shape: RoundedRectangle(cornerRadius: Graphite.Radius.card, style: .continuous),
                isPressed: isPressed
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(habit.name))
        .accessibilityValue(Text("\(doneInGrid) days completed in the last 26 weeks"))
    }
}
