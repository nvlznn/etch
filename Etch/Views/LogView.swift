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
            SpanSwitch(span: $span)
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
        Habit.reorder(habits, fromOffsets: source, toOffset: destination)
    }
}

/// Picks the Log's span, styled like Etch's other controls: a small card-colored capsule whose
/// picked side is a white pill with black text. The pill slides across when the pick changes.
private struct SpanSwitch: View {
    @Binding var span: LogSpan

    @Namespace private var pill

    var body: some View {
        HStack(spacing: 0) {
            ForEach(LogSpan.allCases) { option in
                let selected = option == span
                Button {
                    span = option
                } label: {
                    Text(option.title)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(selected ? Graphite.background : Graphite.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .frame(minWidth: 72)
                        .background {
                            if selected {
                                Capsule()
                                    .fill(Graphite.done)
                                    .matchedGeometryEffect(id: "pill", in: pill)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(3)
        .background { GraphiteCard(shape: Capsule()) }
        .fixedSize()
        .frame(maxWidth: .infinity, alignment: .leading)
        // Keyed to the value rather than wrapped around the tap: `span` lives in `@AppStorage`,
        // whose updates don't carry a `withAnimation` transaction.
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: span)
        .sensoryFeedback(.selection, trigger: span)
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
