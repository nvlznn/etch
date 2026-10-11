import SwiftUI

/// How far back the Log looks.
enum LogSpan: String, CaseIterable, Identifiable {
    /// The last seven days as a row of dots, today on the right.
    case week
    /// The last 26 weeks as a dot grid.
    case halfYear

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .week: "7 Days"
        case .halfYear: "26 Weeks"
        }
    }
}

/// A compact card: a habit's name over its recent days, small enough that four or more fit on one
/// screen. Sits in a `.pressable` button, which tells the card when it is held down.
struct HabitLogCard: View {
    static let weeks = 26

    let habit: Habit
    var span: LogSpan = .halfYear

    @Environment(\.today) private var today
    @Environment(\.isGraphitePressed) private var isPressed

    var body: some View {
        let done = habit.doneDays

        VStack(alignment: .leading, spacing: 8) {
            Text(habit.name)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Graphite.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 2)

            switch span {
            case .week: WeekRow(done: done, today: today)
            case .halfYear: DotGrid(grid: grid, done: done, today: today)
            }
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
        .accessibilityValue(accessibilityValue(done: done))
    }

    private var grid: WeekGrid {
        WeekGrid.ending(at: today, weeks: Self.weeks, firstWeekday: Calendar.current.firstWeekday)
    }

    private func accessibilityValue(done: Set<Day>) -> Text {
        switch span {
        case .week:
            let count = done.count { $0 > today.adding(days: -7) && $0 <= today }
            return Text("\(count) days completed in the last 7 days")
        case .halfYear:
            let count = done.count { $0 >= grid.start && $0 <= today }
            return Text("\(count) days completed in the last 26 weeks")
        }
    }
}

/// The last seven days as dots with their weekdays underneath. Today is always on the right.
private struct WeekRow: View {
    let done: Set<Day>
    let today: Day

    var body: some View {
        let symbols = Calendar.current.veryShortStandaloneWeekdaySymbols
        HStack(spacing: 0) {
            ForEach(-6...0, id: \.self) { offset in
                let day = today.adding(days: offset)
                VStack(spacing: 6) {
                    CheckDot(diameter: 32, isDone: done.contains(day))
                    Text(symbols[day.weekday - 1])
                        .font(.caption2.weight(offset == 0 ? .bold : .medium))
                        .foregroundStyle(offset == 0 ? Graphite.textPrimary : Graphite.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
