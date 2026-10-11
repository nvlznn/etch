import SwiftUI

/// One habit on the Check-In page: its name over a circle for `day`. Tap the circle to fill it with
/// white; tap again to clear it.
struct HabitTile: View {
    let habit: Habit
    let day: Day
    let onRename: () -> Void
    let onDelete: () -> Void

    @Environment(\.today) private var today
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title) private var dotDiameter: CGFloat = 56
    @State private var lastToggle = ToggleEvent()

    var body: some View {
        let done = habit.isDone(on: day)

        VStack(spacing: 10) {
            Text(habit.name)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Graphite.textPrimary)
                .lineLimit(2, reservesSpace: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: toggle) {
                CheckDot(diameter: min(dotDiameter, 112), isDone: done)
            }
            .buttonStyle(CheckDotButtonStyle())
        }
        .padding(12)
        .graphiteCard()
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: Graphite.Radius.card, style: .continuous))
        .contextMenu {
            Button("Rename", systemImage: "pencil", action: onRename)
            Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
        }
        // Keyed to taps on this tile only, so backfilling today from the detail page doesn't buzz twice.
        .sensoryFeedback(trigger: lastToggle) { _, event in
            event.filled ? .impact(weight: .medium) : .impact(weight: .light)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(done: done))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default, toggle)
        .accessibilityAction(named: Text("Rename"), onRename)
        .accessibilityAction(named: Text("Delete"), onDelete)
    }

    private func accessibilityLabel(done: Bool) -> Text {
        if day == today {
            return done ? Text("\(habit.name), done today") : Text("\(habit.name), not done today")
        }
        let date = day.date().formatted(.dateTime.weekday(.wide).month(.wide).day())
        return done ? Text("\(habit.name), done on \(date)") : Text("\(habit.name), not done on \(date)")
    }

    private func toggle() {
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
        lastToggle = ToggleEvent(count: lastToggle.count + 1, filled: filling)
    }
}

private struct ToggleEvent: Equatable {
    var count = 0
    var filled = false
}
