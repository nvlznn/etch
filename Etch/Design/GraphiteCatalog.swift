#if DEBUG
import SwiftUI

/// Every Design/ component side by side, for checking the look in one place.
/// Development only: open with the `-EtchCatalog` launch argument or the preview below.
struct GraphiteCatalog: View {
    private let today = Day.today()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                section("Card") {
                    Text(verbatim: "Card")
                        .font(.headline)
                        .foregroundStyle(Graphite.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: 110)
                        .graphiteCard()
                }

                section("Buttons: primary · secondary") {
                    VStack(spacing: 12) {
                        Button {} label: { buttonLabel }.buttonStyle(.primary)
                        Button {} label: { buttonLabel }.buttonStyle(.secondary)
                    }
                }

                section("Check dot: not done · rest · done") {
                    HStack(spacing: 24) {
                        CheckDot(diameter: 64)
                        CheckDot(diameter: 64, isRest: true)
                        CheckDot(diameter: 64, isDone: true)
                    }
                }

                section("Dot grid · 16 weeks") {
                    DotGrid(
                        grid: .ending(at: today, weeks: 16, firstWeekday: Calendar.current.firstWeekday),
                        done: Set((0..<112).filter { $0 % 3 != 0 }.map { today.adding(days: -$0) }),
                        today: today
                    )
                    .padding(16)
                    .graphiteCard()
                }

                section("Text") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(verbatim: "Primary — Read 20 pages").foregroundStyle(Graphite.textPrimary)
                        Text(verbatim: "Secondary — Best").foregroundStyle(Graphite.textSecondary)
                    }
                    .font(.body)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .graphiteCard()
                }
            }
            .padding(20)
        }
        .background { GraphiteBackground() }
    }

    private var buttonLabel: some View {
        Label(String(localized: "Add Habit"), systemImage: "plus")
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Graphite.textSecondary)
            content()
        }
    }
}

/// The app icon: a plain white circle on a black tile that lifts slightly toward the top,
/// the way a finished dimple looks in the app.
/// Regenerate with the `-EtchRenderIcon` launch argument; see README.
struct AppIconArt: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.17), Color(white: 0.02)],
                startPoint: .top, endPoint: .bottom
            )
            Circle()
                .fill(Graphite.done)
                .frame(width: 614, height: 614)
        }
        .frame(width: 1024, height: 1024)
    }

    /// Writes a 1024 × 1024 opaque PNG to the app's Documents folder.
    static func render() {
        let renderer = ImageRenderer(content: AppIconArt())
        renderer.scale = 1
        renderer.isOpaque = true
        guard let data = renderer.uiImage?.pngData() else { return }
        let url = URL.documentsDirectory.appending(path: "AppIcon.png")
        try? data.write(to: url)
        print("Wrote \(url.path)")
    }
}

#Preview("App icon") {
    AppIconArt().scaleEffect(0.3)
}

#Preview {
    GraphiteCatalog()
        .preferredColorScheme(.dark)
}
#endif
