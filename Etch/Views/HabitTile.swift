import SwiftUI

/// One habit on the Check-In page: its name over a circle for `day`. Tap the circle to fill it with
/// white; tap again to clear it.
struct HabitTile: View {
    let habit: Habit
    let day: Day
    let onEdit: () -> Void
    let onDelete: () -> Void

    @Environment(\.today) private var today
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title) private var dotDiameter: CGFloat = 56
    @State private var lastToggle = ToggleEvent()
    @State private var showsNote = false

    var body: some View {
        let done = habit.isDone(on: day)
        let scheduled = habit.isScheduled(on: day)

        VStack(spacing: 10) {
            Button { showsNote = true } label: {
                Text(habit.name)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Graphite.textPrimary)
                    .lineLimit(2, reservesSpace: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("Show note"))

            Button(action: toggle) {
                ZStack {
                    if scheduled || done {
                        CheckDot(diameter: min(dotDiameter, 112), isDone: done)
                    } else {
                        Circle()
                            .fill(Graphite.textSecondary)
                            .frame(width: 20, height: 20)
                    }
                }
                .frame(width: min(dotDiameter, 112), height: min(dotDiameter, 112))
            }
            .buttonStyle(CheckDotButtonStyle())
            .accessibilityLabel(accessibilityLabel(done: done))
            .accessibilityValue(scheduled ? Text("Scheduled day") : Text("Rest day"))
        }
        .padding(12)
        .graphiteCard()
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: Graphite.Radius.card, style: .continuous))
        .contextMenu {
            if !habit.notes.isEmpty { Button("Note", systemImage: "text.alignleft") { showsNote = true } }
            Button("Edit", systemImage: "pencil", action: onEdit)
            DeleteHabitButton(action: onDelete)
        }
        .sheet(isPresented: $showsNote) {
            NavigationStack {
                ScrollView {
                    Text(habit.notes.isEmpty ? String(localized: "No note yet") : habit.notes)
                        .font(.body)
                        .foregroundStyle(habit.notes.isEmpty ? Graphite.textSecondary : Graphite.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                }
                .background { GraphiteBackground() }
                .navigationTitle(habit.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close", systemImage: "xmark") { showsNote = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationBackground { GraphiteBackground() }
        }
        // Keyed to taps on this tile only, so backfilling today from the detail page doesn't buzz twice.
        .sensoryFeedback(trigger: lastToggle) { _, event in
            event.filled ? .impact(weight: .medium) : .impact(weight: .light)
        }
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
