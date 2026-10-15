import AppIntents
import SwiftUI
import WidgetKit

/// Etch on the Home Screen. Small: today as a checklist. Medium: today as Check-In tiles.
/// Large: the Log, with today's dot beside each name. Every dot for today can be tapped.
struct HabitsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Habits", provider: HabitsProvider()) { entry in
            HabitsWidgetView(entry: entry)
                .containerBackground(Graphite.card, for: .widget)
        }
        .configurationDisplayName("Habits")
        .description("Check in from the Home Screen and see your recent days.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct HabitsWidgetView: View {
    let entry: HabitsEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        if entry.habits.isEmpty {
            Text("No habits yet")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Graphite.textSecondary)
                .multilineTextAlignment(.center)
        } else {
            switch family {
            case .systemSmall: TodayList(entry: entry)
            case .systemMedium: TodayTiles(entry: entry)
            default: RecentLog(entry: entry)
            }
        }
    }
}

// MARK: - Small

/// Up to four habits as a checklist for today.
private struct TodayList: View {
    let entry: HabitsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TodayHeader(entry: entry)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(entry.habits.prefix(4)) { habit in
                    TodayButton(habit: habit, today: entry.today) { done in
                        HStack(spacing: 8) {
                            CheckDot(diameter: 20, isDone: done)
                                .opacity(done || habit.weekdays & (1 << (entry.today.weekday - 1)) != 0 ? 1 : 0.35)
                            Text(habit.name)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Graphite.textPrimary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Medium

/// Up to four habits side by side, each a name over a big dot, like the Check-In page.
private struct TodayTiles: View {
    let entry: HabitsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TodayHeader(entry: entry)
            HStack(alignment: .top, spacing: 10) {
                ForEach(entry.habits.prefix(4)) { habit in
                    TodayButton(habit: habit, today: entry.today) { done in
                        VStack(spacing: 8) {
                            CheckDot(diameter: 50, isDone: done)
                                .opacity(done || habit.weekdays & (1 << (entry.today.weekday - 1)) != 0 ? 1 : 0.35)
                            Text(habit.name)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Graphite.textPrimary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2, reservesSpace: true)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
    }
}

// MARK: - Large

/// Up to three habits as in the Log: the name, today's dot to tap, and the last 30 weeks.
private struct RecentLog: View {
    static let weeks = 30

    let entry: HabitsEntry

    var body: some View {
        let grid = WeekGrid.ending(at: entry.today, weeks: Self.weeks, firstWeekday: Calendar.current.firstWeekday)

        VStack(alignment: .leading, spacing: 14) {
            ForEach(entry.habits.prefix(3)) { habit in
                VStack(alignment: .leading, spacing: 6) {
                    TodayButton(habit: habit, today: entry.today) { done in
                        HStack(spacing: 8) {
                            Text(habit.name)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Graphite.textPrimary)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            CheckDot(diameter: 20, isDone: done)
                                .opacity(done || habit.weekdays & (1 << (entry.today.weekday - 1)) != 0 ? 1 : 0.35)
                        }
                    }
                    DotGrid(grid: grid, done: habit.done, today: entry.today, weekdays: habit.weekdays)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Parts

/// "Today", the date, and how many habits are done.
private struct TodayHeader: View {
    let entry: HabitsEntry

    var body: some View {
        let due = entry.habits.filter { $0.weekdays & (1 << (entry.today.weekday - 1)) != 0 }
        let done = due.count { $0.done.contains(entry.today) }
        HStack(alignment: .firstTextBaseline) {
            Text(entry.today.date(), format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                .foregroundStyle(Graphite.textSecondary)
                .lineLimit(1)
            Spacer(minLength: 4)
            Text(verbatim: "\(done)/\(due.count)")
                .foregroundStyle(Graphite.textPrimary)
                .monospacedDigit()
        }
        .font(.caption.weight(.semibold))
    }
}

/// Toggles `habit` for today from the Home Screen.
private struct TodayButton<Label: View>: View {
    let habit: HabitSnapshot
    let today: Day
    @ViewBuilder let label: (_ done: Bool) -> Label

    var body: some View {
        let done = habit.done.contains(today)
        Button(intent: ToggleHabitIntent(habitID: habit.id, day: today)) {
            label(done)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(done ? Text("\(habit.name), done today") : Text("\(habit.name), not done today"))
        .accessibilityHint(habit.weekdays & (1 << (today.weekday - 1)) != 0 ? Text("Scheduled day") : Text("Rest day"))
    }
}

#Preview(as: .systemSmall) {
    HabitsWidget()
} timeline: {
    HabitsEntry.sample
}

#Preview(as: .systemMedium) {
    HabitsWidget()
} timeline: {
    HabitsEntry.sample
}

#Preview(as: .systemLarge) {
    HabitsWidget()
} timeline: {
    HabitsEntry.sample
}
