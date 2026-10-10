import SwiftData
import SwiftUI

/// One habit in full: streaks, and its whole history as a grid you can backfill.
struct HabitDetailView: View {
    let habit: Habit

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.today) private var today
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var renaming = false
    @State private var deleting: Habit?
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
            VStack(alignment: .leading, spacing: 32) {
                statistics(stats)
                HistoryGrid(done: done, today: today, firstDay: habit.firstDay) { day in
                    habit.toggle(on: day)
                    backfills += 1
                }
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
                    Button("Rename", systemImage: "pencil") { renaming = true }
                    Button("Delete", systemImage: "trash", role: .destructive) { deleting = habit }
                }
            }
        }
        .sheet(isPresented: $renaming) { HabitEditorSheet(target: .rename(habit)) }
        .confirmingDeletion(of: $deleting) { habit in
            dismiss()
            modelContext.delete(habit)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: backfills)
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

/// At least a year of weeks — more if the history goes back further — scrolling sideways,
/// opening on today.
///
/// Built from 13-week `DotGrid`s in a lazy stack, so a habit kept for years doesn't become one
/// enormous canvas.
private struct HistoryGrid: View {
    let done: Set<Day>
    let today: Day
    /// The start of the habit's history; the grid reaches back at least this far.
    let firstDay: Day
    let onTap: (Day) -> Void

    private let cell: CGFloat = 24
    private let chunkWeeks = 13
    private let labelSpacing: CGFloat = 6
    private var firstWeekday: Int { Calendar.current.firstWeekday }

    var body: some View {
        let weeks = max(52, WeekGrid.weeks(from: firstDay, through: today, firstWeekday: firstWeekday))
        let chunks = (weeks + chunkWeeks - 1) / chunkWeeks
        let all = WeekGrid.ending(at: today, weeks: chunks * chunkWeeks, firstWeekday: firstWeekday)

        HStack(alignment: .top, spacing: 8) {
            weekdayLabels

            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 0) {
                    ForEach(0..<chunks, id: \.self) { index in
                        let grid = WeekGrid(
                            start: all.start.adding(days: index * chunkWeeks * 7),
                            weeks: chunkWeeks,
                            firstWeekday: firstWeekday
                        )
                        VStack(alignment: .leading, spacing: labelSpacing) {
                            MonthLabels(grid: grid, today: today, cell: cell)
                            DotGrid(grid: grid, done: done, today: today, cellSize: cell, onTap: onTap)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .defaultScrollAnchor(.trailing)
        }
        .padding(16)
        .graphiteCard()
        // The grid has a fixed geometry; past this size its labels would overflow their rows.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    private var weekdayLabels: some View {
        let symbols = Calendar.current.veryShortStandaloneWeekdaySymbols
        return VStack(alignment: .leading, spacing: labelSpacing) {
            MonthLabels.placeholder
            VStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { row in
                    Text(symbols[(firstWeekday - 1 + row) % 7])
                        .font(.caption2)
                        .foregroundStyle(Graphite.textSecondary)
                        .frame(height: cell)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// Month names above the columns where each month begins.
private struct MonthLabels: View {
    let grid: WeekGrid
    let today: Day
    let cell: CGFloat

    /// Reserves exactly one label's height.
    static var placeholder: some View {
        Text(verbatim: " ").font(.caption2).hidden()
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Self.placeholder
                .frame(width: cell * CGFloat(grid.weeks), alignment: .leading)
            ForEach(labels, id: \.column) { label in
                Group {
                    if label.day.month == 1 {
                        Text(label.day.date(), format: .dateTime.month(.abbreviated).year())
                    } else {
                        Text(label.day.date(), format: .dateTime.month(.abbreviated))
                    }
                }
                .font(.caption2)
                .foregroundStyle(Graphite.textSecondary)
                .fixedSize()
                .offset(x: CGFloat(label.column) * cell + 2)
            }
        }
        .accessibilityHidden(true)
    }

    private var labels: [(column: Int, day: Day)] {
        var result: [(column: Int, day: Day)] = []
        for column in 0..<grid.weeks {
            for row in 0..<7 {
                let day = grid.day(column: column, row: row)
                if day.dayOfMonth == 1, day <= today {
                    result.append((column, day))
                }
            }
        }
        return result
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
