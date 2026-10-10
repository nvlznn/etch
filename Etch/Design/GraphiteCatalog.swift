#if DEBUG
import SwiftUI

/// Every Design/ component side by side, to check that the light always comes from the top left.
/// Development only: open with the `-EtchCatalog` launch argument or the preview below.
struct GraphiteCatalog: View {
    private let today = Day.today()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                section("Raised · Inset") {
                    HStack(spacing: 16) {
                        sample("Raised").graphiteRaised()
                        sample("Inset").graphiteInset()
                    }
                }

                section("Button: rest · held") {
                    HStack(spacing: 16) {
                        Button {} label: { buttonLabel }
                            .buttonStyle(.graphite)
                        buttonLabel
                            .foregroundStyle(Graphite.textPrimary)
                            .background { GraphiteSurface(elevation: .inset, shape: Capsule()) }
                    }
                }

                section("Dimple · filled") {
                    HStack(spacing: 24) {
                        Dimple(diameter: 88)
                        Dimple(diameter: 88, isFilled: true)
                    }
                }

                section("Increase Contrast") {
                    HStack(spacing: 24) {
                        DimpleArt(diameter: 88, increasedContrast: true)
                        Dimple(diameter: 88, isFilled: true)
                    }
                }

                section("Dot grid · 16 weeks") {
                    DotGrid(
                        grid: .ending(at: today, weeks: 16, firstWeekday: Calendar.current.firstWeekday),
                        done: Set((0..<112).filter { $0 % 3 != 0 }.map { today.adding(days: -$0) }),
                        today: today
                    )
                    .padding(14)
                    .background { GraphitePlate() }
                }

                section("Text") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(verbatim: "Primary — Read 20 pages").foregroundStyle(Graphite.textPrimary)
                        Text(verbatim: "Secondary — Longest Streak").foregroundStyle(Graphite.textSecondary)
                    }
                    .font(.body)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .graphiteInset()
                }
            }
            .padding(20)
        }
        .background { GraphiteBackground() }
    }

    private var buttonLabel: some View {
        Label(String(localized: "Add Habit"), systemImage: "plus")
            .font(.headline)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
    }

    private func sample(_ title: String) -> some View {
        Text(verbatim: title)
            .font(.headline)
            .foregroundStyle(Graphite.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 110)
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
