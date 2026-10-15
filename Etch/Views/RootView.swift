import Combine
import SwiftUI
import UIKit

extension EnvironmentValues {
    /// The current local day. Kept up to date across midnight, time-zone and clock changes by `RootView`.
    @Entry var today: Day = .today()
}

struct RootView: View {
    private enum Section: Hashable {
        case checkIn, log, settings
    }

    @State private var section = RootView.initialSection
    @State private var today = Store.today
    @AppStorage("dayEndHour", store: UserDefaults(suiteName: Store.appGroup)) private var dayEndHour = 0
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        #if DEBUG
        if DebugLaunch.showsCatalog {
            GraphiteCatalog()
                .onAppear { if DebugLaunch.rendersIcon { AppIconArt.render() } }
        } else {
            tabs
        }
        #else
        tabs
        #endif
    }

    private var tabs: some View {
        TabView(selection: $section) {
            Tab("Log", systemImage: "circle.grid.3x3.fill", value: .log) {
                LogView()
            }
            Tab("Check-In", systemImage: "circle", value: .checkIn) {
                CheckInView()
            }
            Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsView()
            }
        }
        .environment(\.today, today)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshToday() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
            refreshToday()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            refreshToday()
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            refreshToday()
        }
        .onChange(of: dayEndHour) { _, _ in refreshToday() }
    }

    private func refreshToday() {
        // Pick up a new time zone after travel before working out which day it is.
        NSTimeZone.resetSystemTimeZone()
        let now = Store.today
        if now != today { today = now }
    }

    private static var initialSection: Section {
        #if DEBUG
        DebugLaunch.startsOnLog ? .log : .checkIn
        #else
        .checkIn
        #endif
    }
}
