import SwiftData
import SwiftUI

/// Today: every habit as a tile with a dimple to tap.
struct CheckInView: View {
    @Query(sort: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)])
    private var habits: [Habit]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var editing: HabitEditorTarget?
    @State private var deleting: Habit?

    var body: some View {
        NavigationStack {
            ScrollView {
                if habits.isEmpty {
                    EmptyHabitsCard { editing = .new }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                } else {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(habits) { habit in
                            HabitTile(
                                habit: habit,
                                onRename: { editing = .rename(habit) },
                                onDelete: { deleting = habit }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
            .background { GraphiteBackground() }
            .navigationTitle("Check-In")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Habit", systemImage: "plus") { editing = .new }
                }
            }
            .sheet(item: $editing) { HabitEditorSheet(target: $0) }
            .confirmingDeletion(of: $deleting) { modelContext.delete($0) }
        }
    }

    private var columns: [GridItem] {
        // Three small tiles across; fewer as the text grows.
        let count = switch dynamicTypeSize {
        case ...DynamicTypeSize.large: 3
        case ...DynamicTypeSize.xxxLarge: 2
        default: 1
        }
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }
}

/// Shown instead of the habit list when there are no habits.
struct EmptyHabitsCard: View {
    /// When set, the card offers an "Add Habit" button.
    var onAdd: (() -> Void)?

    var body: some View {
        VStack(spacing: 28) {
            Text("No habits yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Graphite.textPrimary)
                .multilineTextAlignment(.center)

            if let onAdd {
                Button(action: onAdd) {
                    Label("Add Habit", systemImage: "plus")
                        .font(.headline)
                        .padding(.horizontal, 26)
                        .padding(.vertical, 15)
                }
                .buttonStyle(.graphite)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
        .padding(.horizontal, 24)
        .graphiteInset()
    }
}

#if DEBUG
#Preview("Habits") {
    CheckInView()
        .modelContainer(PreviewStore.withHabits)
        .preferredColorScheme(.dark)
        .tint(.white)
}

#Preview("Empty") {
    CheckInView()
        .modelContainer(PreviewStore.empty)
        .preferredColorScheme(.dark)
        .tint(.white)
}
#endif
