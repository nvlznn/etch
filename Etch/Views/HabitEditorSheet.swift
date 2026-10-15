import SwiftData
import SwiftUI

enum HabitEditorTarget: Identifiable {
    case new
    case edit(Habit)

    var id: PersistentIdentifier? {
        if case .edit(let habit) = self { habit.persistentModelID } else { nil }
    }
}

/// Adds a habit or edits its name, note, and scheduled weekdays.
///
/// Opens at full height so the sheet rises once; a half-height sheet would stop halfway and then
/// jump again when the keyboard came up.
struct HabitEditorSheet: View {
    let target: HabitEditorTarget

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var notes: String
    @State private var weekdays: Int
    @FocusState private var focus: Field?

    private enum Field {
        case name, notes
    }

    init(target: HabitEditorTarget) {
        self.target = target
        if case .edit(let habit) = target {
            _name = State(initialValue: habit.name)
            _notes = State(initialValue: habit.notes)
            _weekdays = State(initialValue: habit.weekdays)
        } else {
            _name = State(initialValue: "")
            _notes = State(initialValue: "")
            _weekdays = State(initialValue: 127)
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedNotes: String {
        notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    TextField("Name", text: $name, prompt: Text("Name").foregroundStyle(Graphite.textSecondary))
                        .font(.title3)
                        .focused($focus, equals: .name)
                        .submitLabel(.done)
                        .onSubmit(save)
                        .fieldCard()

                    TextField(
                        "Note", text: $notes,
                        prompt: Text("Note").foregroundStyle(Graphite.textSecondary),
                        axis: .vertical
                    )
                    .font(.body)
                    .lineLimit(4...12)
                    .focused($focus, equals: .notes)
                    .fieldCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Frequency")
                            .font(.headline)
                        HStack(spacing: 6) {
                            ForEach(0..<7, id: \.self) { offset in
                                let index = (Calendar.current.firstWeekday - 1 + offset) % 7
                                let selected = weekdays & (1 << index) != 0
                                Button {
                                    let bit = 1 << index
                                    if selected && weekdays == bit { return }
                                    weekdays ^= bit
                                } label: {
                                    Text(Calendar.current.veryShortStandaloneWeekdaySymbols[index])
                                        .font(.footnote.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 36)
                                        .background(selected ? Graphite.done : Graphite.notDone, in: Circle())
                                        .foregroundStyle(selected ? Graphite.background : Graphite.textPrimary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(Text(Calendar.current.weekdaySymbols[index]))
                                .accessibilityAddTraits(selected ? .isSelected : [])
                            }
                        }
                    }
                    .padding(16)
                    .graphiteCard()
                }
                .foregroundStyle(Graphite.textPrimary)
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isNew ? "New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: save)
                        .disabled(trimmedName.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground { GraphiteBackground() }
        .onAppear { focus = .name }
    }

    private var isNew: Bool {
        if case .new = target { true } else { false }
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        switch target {
        case .new:
            let habit = Habit(name: trimmedName, sortOrder: Habit.nextSortOrder(in: modelContext))
            habit.notes = trimmedNotes
            habit.weekdays = weekdays
            modelContext.insert(habit)
        case .edit(let habit):
            habit.name = trimmedName
            if habit.notes != trimmedNotes { habit.notes = trimmedNotes }
            if habit.weekdays != weekdays { habit.weekdays = weekdays }
        }
        dismiss()
    }
}

private extension View {
    /// A text field's padding and card.
    func fieldCard() -> some View {
        padding(.horizontal, 18)
            .padding(.vertical, 16)
            .graphiteCard(cornerRadius: Graphite.Radius.field)
    }
}

/// "Delete" for a habit's menus, red icon and all. A destructive role colors only the title; the
/// app's white tint would otherwise leave the trash can white.
struct DeleteHabitButton: View {
    let action: () -> Void

    var body: some View {
        Button(role: .destructive, action: action) {
            Label {
                Text("Delete")
            } icon: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
        }
        .tint(.red)
    }
}

extension View {
    /// Asks before deleting the habit in `habit`, since that also deletes its whole history.
    func confirmingDeletion(of habit: Binding<Habit?>, perform delete: @escaping (Habit) -> Void) -> some View {
        alert(
            habit.wrappedValue.map { Text("Delete “\($0.name)”?") } ?? Text(verbatim: ""),
            isPresented: Binding(
                get: { habit.wrappedValue != nil },
                set: { if !$0 { habit.wrappedValue = nil } }
            ),
            presenting: habit.wrappedValue
        ) { target in
            Button("Delete Habit", role: .destructive) { delete(target) }
        } message: { _ in
            Text("Its check-ins will be deleted too. This can’t be undone.")
        }
    }
}
