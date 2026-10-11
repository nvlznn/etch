import SwiftData
import SwiftUI

/// Every habit's last 7 days or 26 weeks. Tap a card for its full history, swipe it left to check in
/// today, long-press and drag to reorder.
struct LogView: View {
    @Query(sort: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)])
    private var habits: [Habit]

    @State private var path: [Habit] = []
    @AppStorage("logSpan") private var span = LogSpan.halfYear
    @Environment(\.today) private var today
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lastSwipe = SwipeCheck()

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if habits.isEmpty {
                    ScrollView {
                        EmptyHabitsCard()
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }
                } else {
                    list
                }
            }
            .background { GraphiteBackground() }
            .navigationTitle("Log")
            .navigationDestination(for: Habit.self) { HabitDetailView(habit: $0) }
        }
        #if DEBUG
        .task {
            if DebugLaunch.opensFirstHabit, path.isEmpty, let first = habits.first {
                path = [first]
            }
        }
        #endif
    }

    /// A system list, so long-press-and-drag reordering works without an Edit button.
    private var list: some View {
        List {
            Picker("Range", selection: $span) {
                ForEach(LogSpan.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            ForEach(habits) { habit in
                Button {
                    path.append(habit)
                } label: {
                    HabitLogCard(habit: habit, span: span)
                }
                .buttonStyle(.pressable)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    checkTodayButton(for: habit)
                }
                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onMove(perform: move)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .sensoryFeedback(trigger: lastSwipe) { _, swipe in
            swipe.filled ? .impact(weight: .medium) : .impact(weight: .light)
        }
    }

    /// Revealed by swiping a card left; a full swipe presses it. Checks in today, or undoes it.
    private func checkTodayButton(for habit: Habit) -> some View {
        let done = habit.isDone(on: today)
        return Button {
            let filling = !habit.isDone(on: today)
            withAnimation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.7)) {
                habit.setDone(filling, on: today)
            }
            lastSwipe = SwipeCheck(count: lastSwipe.count + 1, filled: filling)
        } label: {
            if done {
                Label("Uncheck", systemImage: "arrow.uturn.backward")
            } else {
                Label("Check In", systemImage: "checkmark")
            }
        }
        .tint(Graphite.swipeAction)
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = habits
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, habit) in reordered.enumerated() where habit.sortOrder != index {
            habit.sortOrder = index
        }
    }
}

private struct SwipeCheck: Equatable {
    var count = 0
    var filled = false
}

#if DEBUG
#Preview {
    LogView()
        .modelContainer(PreviewStore.withHabits)
        .preferredColorScheme(.dark)
        .tint(.white)
}
#endif
