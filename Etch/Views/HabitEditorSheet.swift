import SwiftData
import SwiftUI

enum HabitEditorTarget: Identifiable {
    case new
    case rename(Habit)

    var id: PersistentIdentifier? {
        if case .rename(let habit) = self { habit.persistentModelID } else { nil }
    }
}

/// Adds a habit or renames one. A habit is only a name: no icon, color or schedule.
struct HabitEditorSheet: View {
    let target: HabitEditorTarget

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @FocusState private var isFocused: Bool

    init(target: HabitEditorTarget) {
        self.target = target
        if case .rename(let habit) = target {
            _name = State(initialValue: habit.name)
        } else {
            _name = State(initialValue: "")
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Name", text: $name, prompt: Text("Name").foregroundStyle(Graphite.textSecondary))
                    .font(.title3)
                    .foregroundStyle(Graphite.textPrimary)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit(save)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .graphiteInset(cornerRadius: Graphite.Radius.field)
                Spacer(minLength: 0)
            }
            .padding(20)
            .navigationTitle(isNew ? "New Habit" : "Rename Habit")
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
        .presentationDetents([.medium])
        .presentationBackground { GraphiteBackground() }
        .onAppear { isFocused = true }
    }

    private var isNew: Bool {
        if case .new = target { true } else { false }
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        switch target {
        case .new:
            modelContext.insert(Habit(name: trimmedName, sortOrder: Habit.nextSortOrder(in: modelContext)))
        case .rename(let habit):
            habit.name = trimmedName
        }
        dismiss()
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
