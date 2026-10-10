import SwiftUI

/// A habit's name over its last 16 weeks on a dot-grid plate. Sits in a `PlateButtonStyle` button,
/// which tells the plate when it is pressed.
struct HabitLogCard: View {
    static let weeks = 16

    let habit: Habit

    @Environment(\.today) private var today
    @Environment(\.isGraphitePressed) private var isPressed

    var body: some View {
        let done = habit.doneDays
        let grid = WeekGrid.ending(at: today, weeks: Self.weeks, firstWeekday: Calendar.current.firstWeekday)
        let doneInGrid = done.count { $0 >= grid.start && $0 <= today }

        VStack(alignment: .leading, spacing: 6) {
            Text(habit.name)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Graphite.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)

            DotGrid(grid: grid, done: done, today: today)
                .padding(10)
                .background { GraphitePlate(pressed: isPressed) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(habit.name))
        .accessibilityValue(Text("\(doneInGrid) days completed in the last 16 weeks"))
    }
}
