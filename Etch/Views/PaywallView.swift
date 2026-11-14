import StoreKit
import SwiftUI

/// Offers Etch Pro on a page of its own: a glowing orb over a field of dots that ripple outward, a
/// "Lifetime" tag, what Pro adds in two short lines, and the buy button. It never blocks anything the
/// user already has; it only opens when they try to add a habit past the free limit or unarchive
/// one, or from Settings.
///
/// This page is the one place Etch isn't flat: the orb is shaded like a sphere and glows. It stays
/// strictly black, white and gray, and every effect stops with Reduce Motion.
struct PaywallView: View {
    private static let orbSize: CGFloat = 176
    private static let heroHeight: CGFloat = 360

    @Environment(Purchases.self) private var purchases
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        hero

                        VStack(spacing: 16) {
                            Text("Lifetime")
                                .font(.caption.weight(.bold))
                                .textCase(.uppercase)
                                .tracking(1.5)
                                .foregroundStyle(Graphite.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background { GraphiteCard(shape: Capsule()) }

                            VStack(spacing: 10) {
                                Text("Etch Pro")
                                    .font(.largeTitle.weight(.bold))
                                    .foregroundStyle(Graphite.textPrimary)
                                VStack(spacing: 2) {
                                    Text("Unlimited habits")
                                    Text("Unarchive anytime")
                                }
                                .font(.title3)
                                .foregroundStyle(Graphite.textSecondary)
                            }
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                        Spacer(minLength: 28)
                        actions
                            .padding(.horizontal, 24)
                    }
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                    .padding(.bottom, 16)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .background { GraphiteBackground() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .presentationBackground { GraphiteBackground() }
        .onChange(of: purchases.isPro) { _, isPro in
            if isPro { dismiss() }
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.8, dampingFraction: 0.65)) {
                shown = true
            }
        }
    }

    /// The orb with the dot field rippling out from behind it.
    private var hero: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: reduceMotion)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                DotField(time: time, clearRadius: Self.orbSize / 2 + 18, reach: Self.heroHeight / 2)
                    .opacity(shown ? 1 : 0)
                Orb(size: Self.orbSize, time: time)
                    .scaleEffect(shown ? 1 : 0.2)
                    .opacity(shown ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.heroHeight)
        .accessibilityHidden(true)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                Task { await purchases.purchase() }
            } label: {
                Group {
                    if let price = purchases.product?.displayPrice {
                        Text("Get Lifetime Access · \(price)")
                    } else {
                        Text("Get Lifetime Access")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.primary)
            .disabled(purchases.product == nil || purchases.isBusy)

            Button("Restore Purchases") { Task { await purchases.restore() } }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Graphite.textSecondary)
                .buttonStyle(.plain)
                .padding(.vertical, 8)
                .disabled(purchases.isBusy)

            Group {
                if purchases.failed {
                    Text("Something went wrong. Try again.")
                } else {
                    Text("Pay once, yours for life. Family Sharing included.")
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Graphite.textSecondary)
            .multilineTextAlignment(.center)
        }
    }
}

/// A sphere: lit from the upper left, darker toward the lower right, with a soft glow behind it that
/// breathes and a slow drift up and down. Grays only.
private struct Orb: View {
    let size: CGFloat
    let time: TimeInterval

    var body: some View {
        let breath = 0.5 + 0.5 * sin(time * 1.4)
        ZStack {
            Circle()
                .fill(Graphite.done.opacity(0.3))
                .frame(width: size * 1.2, height: size * 1.2)
                .blur(radius: 38)
                .scaleEffect(1 + 0.08 * breath)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(white: 1), Color(white: 0.92), Color(white: 0.55), Color(white: 0.18)],
                        center: UnitPoint(x: 0.36, y: 0.3),
                        startRadius: 0,
                        endRadius: size * 0.95
                    )
                )
                .overlay {
                    // The highlight.
                    Circle().fill(
                        RadialGradient(
                            colors: [Color(white: 1, opacity: 0.9), Color(white: 1, opacity: 0)],
                            center: UnitPoint(x: 0.3, y: 0.24),
                            startRadius: 0,
                            endRadius: size * 0.34
                        )
                    )
                }
                .overlay {
                    // A rim of light along the top.
                    Circle().strokeBorder(
                        LinearGradient(
                            colors: [Color(white: 1, opacity: 0.55), Color(white: 1, opacity: 0)],
                            startPoint: .top,
                            endPoint: .center
                        ),
                        lineWidth: 1.5
                    )
                }
                .frame(width: size, height: size)
        }
        .offset(y: sin(time * 0.9) * 5)
    }
}

/// A round field of small dots. A wave of light runs outward from the middle: dots on the crest are
/// bigger and brighter, and the field fades to nothing at its edge. Dots under the orb are skipped.
private struct DotField: View {
    let time: TimeInterval
    /// Nothing is drawn this close to the middle, where the orb is.
    let clearRadius: CGFloat
    /// How far from the middle the field reaches.
    let reach: CGFloat

    private let spacing: CGFloat = 22

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let steps = Int(reach / spacing) + 1
            for column in -steps...steps {
                for row in -steps...steps {
                    let dx = CGFloat(column) * spacing
                    let dy = CGFloat(row) * spacing
                    let distance = hypot(dx, dy)
                    guard distance > clearRadius, distance < reach else { continue }

                    // 0...1, a crest travelling outward about every three seconds.
                    let wave = 0.5 + 0.5 * sin(Double(distance) / 24 - time * 2.0)
                    let crest = wave * wave * wave
                    let fade = pow(1 - Double(distance / reach), 1.3)
                    let opacity = 0.05 + 0.85 * crest * fade
                    let radius = 1.2 + 1.9 * wave * fade

                    let dot = CGRect(x: center.x + dx - radius, y: center.y + dy - radius,
                                     width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: dot), with: .color(Graphite.done.opacity(opacity)))
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    PaywallView()
        .environment(Purchases())
        .preferredColorScheme(.dark)
        .tint(.white)
}
#endif
