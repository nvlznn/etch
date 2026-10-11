import SwiftData
import SwiftUI

enum HabitEditorTarget: Identifiable {
    case new
    case edit(Habit)

    var id: PersistentIdentifier? {
        if case .edit(let habit) = self { habit.persistentModelID } else { nil }
    }
}

/// Adds a habit or edits one. A habit is a name and an optional note: no icon, color or
/// schedule.
///
/// Opens at full height so the sheet rises once; a half-height sheet would stop halfway and then
/// jump again when the keyboard came up.
struct HabitEditorSheet: View {
    let target: HabitEditorTarget

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var notes: String
    @FocusState private var focus: Field?

    private enum Field {
        case name, notes
    }

    init(target: HabitEditorTarget) {
        self.target = target
        if case .edit(let habit) = target {
            _name = State(initialValue: habit.name)
            _notes = State(initialValue: habit.notes)
        } else {
            _name = State(initialValue: "")
            _notes = State(initialValue: "")
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
                        prompt: Text("Note (optional)").foregroundStyle(Graphite.textSecondary),
                        axis: .vertical
                    )
                    .font(.body)
                    .lineLimit(4...12)
                    .focused($focus, equals: .notes)
                    .fieldCard()
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
            modelContext.insert(habit)
        case .edit(let habit):
            habit.name = trimmedName
            if habit.notes != trimmedNotes { habit.notes = trimmedNotes }
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
        confirmationDialog(
            habit.wrappedValue.map { Text("Delete “\($0.name)”?") } ?? Text(verbatim: ""),
            isPresented: Binding(
                get: { habit.wrappedValue != nil },
                set: { if !$0 { habit.wrappedValue = nil } }
            ),
            titleVisibility: .visible,
            presenting: habit.wrappedValue
        ) { target in
            Button("Delete Habit", role: .destructive) { delete(target) }
        } message: { _ in
            Text("Its check-ins will be deleted too. This can’t be undone.")
        }
    }
}
