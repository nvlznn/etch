import SwiftUI

struct SettingsView: View {
    @AppStorage("dayEndHour", store: UserDefaults(suiteName: Store.appGroup)) private var dayEndHour = 0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Day ends", selection: $dayEndHour) {
                        ForEach(0...5, id: \.self) { hour in
                            Text(String(format: "%02d:00", hour)).tag(hour)
                        }
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
            }
            .scrollContentBackground(.hidden)
            .background { GraphiteBackground() }
            .navigationTitle("Settings")
        }
    }
}
