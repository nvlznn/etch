import SwiftData
import SwiftUI

/// The last 16 weeks of every habit. Tap a card for its full history; long-press and drag to reorder.
struct LogView: View {
    @Query(sort: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)])
    private var habits: [Habit]

    @State private var path: [Habit] = []

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
            ForEach(habits) { habit in
                Button {
                    path.append(habit)
                } label: {
                    HabitLogCard(habit: habit)
                }
                .buttonStyle(.pressable)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onMove(perform: move)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = habits
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, habit) in reordered.enumerated() where habit.sortOrder != index {
            habit.sortOrder = index
        }
    }
}

#if DEBUG
#Preview {
    LogView()
        .modelContainer(PreviewStore.withHabits)
        .preferredColorScheme(.dark)
        .tint(.white)
}
#endif
