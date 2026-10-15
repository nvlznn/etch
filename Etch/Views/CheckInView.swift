import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// One day — today unless another is picked above — with every habit as a tile with a dot to tap.
/// Long-press a tile for its menu, or long-press and drag it to reorder.
struct CheckInView: View {
    @Query(sort: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)])
    private var habits: [Habit]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.today) private var today
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var editing: HabitEditorTarget?
    @State private var deleting: Habit?
    /// How many days before today the page is showing. Kept as an offset so "Today" stays
    /// selected when the date rolls over at midnight.
    @State private var daysAgo = 0
    /// The tile being dragged to a new place, if any.
    @State private var dragging: Habit?
    @State private var displayOrder: [PersistentIdentifier] = []
    /// Counts the places a dragged tile has moved through, for a tick of haptic feedback each time.
    @State private var moves = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                if habits.isEmpty {
                    EmptyHabitsCard { editing = .new }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                } else {
                    DaySwitcher(today: today, daysAgo: $daysAgo)
                        .padding(.top, 4)
                        .padding(.bottom, 8)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(orderedHabits) { habit in
                            HabitTile(
                                habit: habit,
                                day: today.adding(days: -daysAgo),
                                onEdit: { editing = .edit(habit) },
                                onDelete: { deleting = habit }
                            )
                            .onDrag {
                                dragging = habit
                                displayOrder = habits.map(\.persistentModelID)
                                return NSItemProvider(object: habit.name as NSString)
                            }
                            .onDrop(of: [.text], delegate: TileDropDelegate(
                                target: habit, habits: habits, order: $displayOrder,
                                dragging: $dragging, moves: $moves
                            ))
                        }
                    }
                    // Dropping in a gap between tiles ends the drag where the tile already is.
                    .onDrop(of: [.text], isTargeted: nil) { _ in
                        finishDrag()
                        return true
                    }
                    .sensoryFeedback(.selection, trigger: moves)
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

    private var orderedHabits: [Habit] {
        guard !displayOrder.isEmpty else { return habits }
        return habits.sorted {
            (displayOrder.firstIndex(of: $0.persistentModelID) ?? Int.max) <
            (displayOrder.firstIndex(of: $1.persistentModelID) ?? Int.max)
        }
    }

    private func finishDrag() {
        for (index, habit) in orderedHabits.enumerated() where habit.sortOrder != index {
            habit.sortOrder = index
        }
        dragging = nil
        displayOrder = []
    }
}

/// Reorders live while a tile is dragged: entering another tile's place moves the dragged one there.
private struct TileDropDelegate: DropDelegate {
    let target: Habit
    let habits: [Habit]
    @Binding var order: [PersistentIdentifier]
    @Binding var dragging: Habit?
    @Binding var moves: Int

    func dropEntered(info: DropInfo) {
        guard let dragging, dragging != target,
              let from = order.firstIndex(of: dragging.persistentModelID),
              let to = order.firstIndex(of: target.persistentModelID)
        else { return }
        withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.82)) {
            order.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
        moves += 1
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        for (index, id) in order.enumerated() {
            if let habit = habits.first(where: { $0.persistentModelID == id }) {
                habit.sortOrder = index
            }
        }
        dragging = nil
        order = []
        return true
    }
}

/// The day being checked in: its date between a back and a forward arrow. Forward stops at today.
private struct DaySwitcher: View {
    let today: Day
    @Binding var daysAgo: Int

    var body: some View {
        HStack {
            arrow("Previous Day", systemImage: "chevron.left") { daysAgo += 1 }

            Spacer()

            Text(today.adding(days: -daysAgo).date(), format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                .font(.title3.weight(.semibold))
                .foregroundStyle(Graphite.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer()

            arrow("Next Day", systemImage: "chevron.right") { daysAgo -= 1 }
                .disabled(daysAgo == 0)
        }
        .padding(.horizontal, 16)
        .sensoryFeedback(.selection, trigger: daysAgo)
    }

    private func arrow(_ title: LocalizedStringKey, systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true
            withTransaction(transaction, action)
        } label: {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.secondary)
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
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
        .padding(.horizontal, 24)
        .graphiteCard()
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
