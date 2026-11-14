import SwiftData
import SwiftUI

struct SettingsView: View {
    @AppStorage("dayEndHour", store: UserDefaults(suiteName: Store.appGroup)) private var dayEndHour = 0
    @AppStorage(StartPage.key) private var startPage = StartPage.checkIn
    @Query(Habit.archived)
    private var archived: [Habit]
    @Environment(Purchases.self) private var purchases
    @State private var paywall: PaywallReason?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if purchases.isPro {
                        LabeledContent("Plan") { Text("Etch Pro") }
                    } else {
                        Button { paywall = .settings } label: {
                            LabeledContent("Plan") {
                                HStack(spacing: 6) {
                                    Text("Etch Free")
                                    Image(systemName: "chevron.right")
                                        .font(.footnote.weight(.semibold))
                                        .accessibilityHidden(true)
                                }
                                .foregroundStyle(Graphite.textSecondary)
                            }
                        }
                        .foregroundStyle(Graphite.textPrimary)

                        Button("Restore Purchases") { Task { await purchases.restore() } }
                            .foregroundStyle(Graphite.textPrimary)
                            .disabled(purchases.isBusy)
                    }
                }

                Section {
                    Picker("Day ends", selection: $dayEndHour) {
                        ForEach(0...5, id: \.self) { hour in
                            Text(String(format: "%02d:00", hour)).tag(hour)
                        }
                    }

                    Picker("Start page", selection: $startPage) {
                        ForEach(StartPage.allCases) { page in
                            Text(page.title).tag(page)
                        }
                    }
                }

                Section {
                    NavigationLink {
                        ArchivedHabitsView()
                    } label: {
                        LabeledContent("Archived", value: archived.count, format: .number)
                    }
                }

                Section {
                    Link(destination: URL(string: "https://github.com/nvlznn/etch")!) {
                        Label {
                            Text("GitHub")
                        } icon: {
                            Image("GitHub")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 17, height: 17)
                        }
                    }
                }

                Section {
                    LabeledContent("Version") { Text(versionText) }
                }
            }
            .scrollContentBackground(.hidden)
            .background { GraphiteBackground() }
            .navigationTitle("Settings")
            .sheet(item: $paywall) { PaywallSheet(reason: $0) }
        }
    }

    /// The app's version and build, e.g. "8.0 (1)". A debug build says so.
    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        #if DEBUG
        return "\(version) (\(build)) · \(String(localized: "Debug"))"
        #else
        return "\(version) (\(build))"
        #endif
    }
}

/// Every archived habit, the latest first. Tap one for its history, to unarchive or delete it.
private struct ArchivedHabitsView: View {
    @Query(Habit.archived)
    private var habits: [Habit]

    var body: some View {
        Form {
            if habits.isEmpty {
                Text("No archived habits")
                    .foregroundStyle(Graphite.textSecondary)
            } else {
                ForEach(habits) { habit in
                    NavigationLink {
                        HabitDetailView(habit: habit)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(habit.name)
                            if let archivedAt = habit.archivedAt {
                                Text("Archived \(archivedAt, format: .dateTime.year().month().day())")
                                    .font(.footnote)
                                    .foregroundStyle(Graphite.textSecondary)
                            }
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background { GraphiteBackground() }
        .navigationTitle("Archived")
    }
}
