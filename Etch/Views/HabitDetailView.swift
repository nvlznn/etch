import SwiftData
import SwiftUI

/// One habit in full: its note, streaks, and its whole history as a month calendar you can
/// backfill.
struct HabitDetailView: View {
    let habit: Habit

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.today) private var today
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var editing = false
    @State private var deleting: Habit?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var backfills = 0

    var body: some View {
        // Briefly true while the page slides away after the habit was deleted.
        if habit.isDeleted || habit.modelContext == nil {
            GraphiteBackground()
        } else {
            content
        }
    }

    private var content: some View {
        let done = habit.doneDays
        let stats = Stats(days: done, today: today)

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !habit.notes.isEmpty {
                    notes
                }
                statistics(stats)
                MonthCalendar(done: done, today: today, firstDay: habit.firstDay, onTap: toggle)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background { GraphiteBackground() }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu("More", systemImage: "ellipsis") {
                    Button("Edit", systemImage: "pencil") { editing = true }
                    DeleteHabitButton { deleting = habit }
                }
            }
        }
        .sheet(isPresented: $editing) { HabitEditorSheet(target: .edit(habit)) }
        .confirmingDeletion(of: $deleting) { habit in
            dismiss()
            modelContext.delete(habit)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: backfills)
    }

    private func toggle(_ day: Day) {
        let filling = !habit.isDone(on: day)
        let animation: Animation? = if reduceMotion {
            nil
        } else if filling {
            .spring(response: 0.42, dampingFraction: 0.55)
        } else {
            .easeOut(duration: 0.18)
        }
        withAnimation(animation) {
            habit.setDone(filling, on: day)
        }
        backfills += 1
    }

    /// The habit's note, as typed. Tap to edit it.
    private var notes: some View {
        Button { editing = true } label: {
            Text(habit.notes)
                .font(.subheadline)
                .foregroundStyle(Graphite.textSecondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
        }
        .buttonStyle(.card)
        .accessibilityLabel(Text("Note"))
        .accessibilityValue(Text(habit.notes))
        .accessibilityHint(Text("Edit"))
    }

    /// Three numbers on one card, separated by hairlines; stacked when the text is very large.
    private func statistics(_ stats: Stats) -> some View {
        let stacked = dynamicTypeSize.isAccessibilitySize
        let layout = stacked ? AnyLayout(VStackLayout(spacing: 16)) : AnyLayout(HStackLayout(spacing: 0))
        return layout {
            StatItem(value: stats.currentStreak, title: "Current Streak")
            if !stacked { StatDivider() }
            StatItem(value: stats.longestStreak, title: "Longest Streak")
            if !stacked { StatDivider() }
            StatItem(value: stats.total, title: "Total")
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 8)
        .fixedSize(horizontal: false, vertical: true)
        .graphiteCard()
    }
}

/// One number and its label.
private struct StatItem: View {
    let value: Int
    let title: LocalizedStringKey

    var body: some View {
        VStack(spacing: 4) {
            Text(value, format: .number)
                .font(.title.weight(.semibold))
                .fontWidth(.expanded)
                .monospacedDigit()
                .foregroundStyle(Graphite.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(title)
                .font(.caption)
                .foregroundStyle(Graphite.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(value, format: .number))
    }
}

private struct StatDivider: View {
    var body: some View {
        Rectangle()
            .fill(Graphite.divider)
            .frame(width: 1)
            .padding(.vertical, 6)
    }
}

/// The habit's history a month at a time, opening on this month. Swipe sideways or use the arrows
/// to change month; tap any day up to today to mark it done or not done.
private struct MonthCalendar: View {
    let done: Set<Day>
    let today: Day
    /// The start of the habit's history; the calendar reaches back at least this far.
    let firstDay: Day
    let onTap: (Day) -> Void

    /// The month on screen. `nil` until the user changes month, meaning this month.
    @State private var shown: Month?

    private let inset: CGFloat = 12
    private var firstWeekday: Int { Calendar.current.firstWeekday }

    var body: some View {
        let thisMonth = Month(today)
        // At least a year back, more if the history goes back further.
        let months = Month.range(from: min(Month(firstDay), thisMonth.adding(months: -11)), through: thisMonth)
        let current = shown ?? thisMonth

        VStack(spacing: 14) {
            header(current, earliest: months[0], latest: thisMonth)
                .padding(.horizontal, inset + 4)

            weekdayLabels
                .padding(.horizontal, inset)

            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(months, id: \.self) { month in
                        MonthPage(month: month, done: done, today: today, firstWeekday: firstWeekday, onTap: onTap)
                            .padding(.horizontal, inset)
                            .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $shown)
            .scrollIndicators(.hidden)
            .defaultScrollAnchor(.trailing)
        }
        .padding(.vertical, 16)
        .graphiteCard()
        // The day dots have a fixed size; past this the numbers would no longer fit inside them.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    private func header(_ month: Month, earliest: Month, latest: Month) -> some View {
        HStack {
            Text(month.first.date(), format: .dateTime.month(.wide).year())
                .font(.headline)
                .foregroundStyle(Graphite.textPrimary)
                .contentTransition(.numericText())
                .accessibilityAddTraits(.isHeader)

            Spacer()

            HStack(spacing: 20) {
                arrow("Previous Month", systemImage: "chevron.left", enabled: month > earliest) {
                    show(month.adding(months: -1))
                }
                arrow("Next Month", systemImage: "chevron.right", enabled: month < latest) {
                    show(month.adding(months: 1))
                }
            }
            .labelStyle(.iconOnly)
            .font(.body.weight(.semibold))
            .buttonStyle(.borderless)
        }
    }

    private func arrow(_ title: LocalizedStringKey, systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(title, systemImage: systemImage, action: action)
            .foregroundStyle(enabled ? Graphite.textPrimary : Graphite.textDisabled)
            .disabled(!enabled)
    }

    private func show(_ month: Month) {
        withAnimation(.smooth) { shown = month }
    }

    private var weekdayLabels: some View {
        let symbols = Calendar.current.veryShortStandaloneWeekdaySymbols
        return HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { column in
                Text(symbols[(firstWeekday - 1 + column) % 7])
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Graphite.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }
}

/// One month as six rows of seven days, so every month is the same height and paging never jumps.
private struct MonthPage: View {
    let month: Month
    let done: Set<Day>
    let today: Day
    let firstWeekday: Int
    let onTap: (Day) -> Void

    var body: some View {
        // The day in the top-left slot; slots outside the month stay empty.
        let start = month.first.startOfWeek(firstWeekday: firstWeekday)

        VStack(spacing: 6) {
            ForEach(0..<6, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { column in
                        let day = start.adding(days: row * 7 + column)
                        Group {
                            if Month(day) == month {
                                DayCell(day: day, isDone: done.contains(day), today: today, onTap: onTap)
                            } else {
                                Color.clear
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: DayCell.size)
                    }
                }
            }
        }
    }
}

/// A day of the month: a dot with the date in it, white when done and black when not, like the
/// Log. Today has a ring around it. Days after today are just a dim number and can't be tapped.
private struct DayCell: View {
    static let size: CGFloat = 44
    private static let diameter: CGFloat = 38

    let day: Day
    let isDone: Bool
    let today: Day
    let onTap: (Day) -> Void

    var body: some View {
        if day > today {
            number
                .foregroundStyle(Graphite.textSecondary.opacity(0.4))
                .accessibilityHidden(true)
        } else {
            Button { onTap(day) } label: {
                ZStack {
                    CheckDot(diameter: Self.diameter, isDone: isDone)
                    number
                        .foregroundStyle(isDone ? Graphite.background : Graphite.textPrimary)
                }
                .frame(width: Self.size, height: Self.size)
                .overlay {
                    if day == today {
                        Circle().strokeBorder(Graphite.done, lineWidth: 1.5)
                    }
                }
            }
            .buttonStyle(CheckDotButtonStyle())
            .accessibilityLabel(Text(day.date(), format: .dateTime.weekday(.wide).month(.wide).day().year()))
            .accessibilityValue(isDone ? Text("Completed") : Text("Not completed"))
        }
    }

    private var number: some View {
        Text(day.dayOfMonth, format: .number)
            .font(.subheadline.weight(day == today ? .bold : .medium))
            .monospacedDigit()
    }
}

#if DEBUG
#Preview {
    let habit = PreviewStore.firstHabit
    NavigationStack {
        HabitDetailView(habit: habit)
    }
    .modelContainer(habit.modelContext!.container)
    .preferredColorScheme(.dark)
    .tint(.white)
}
#endif
