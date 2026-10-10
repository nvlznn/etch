import SwiftData
import SwiftUI

/// The last 16 weeks of every habit. Tap a card for its full history.
struct LogView: View {
    @Query(sort: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)])
    private var habits: [Habit]

    @State private var path: [Habit] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                if habits.isEmpty {
                    EmptyHabitsCard()
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                } else {
                    LazyVStack(spacing: 20) {
                        ForEach(habits) { habit in
                            Button {
                                path.append(habit)
                            } label: {
                                HabitLogCard(habit: habit)
                            }
                            .buttonStyle(.plate)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 8)
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
}

#if DEBUG
#Preview {
    LogView()
        .modelContainer(PreviewStore.withHabits)
        .preferredColorScheme(.dark)
        .tint(.white)
}
#endif
