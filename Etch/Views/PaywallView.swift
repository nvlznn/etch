import StoreKit
import SwiftUI

/// Offers Etch Pro on a page of its own: a big white circle, what Pro adds in two short lines, and the
/// buy button. It never blocks anything the user already has; it only opens when they try to add a
/// habit past the free limit or unarchive one, or from Settings.
struct PaywallView: View {
    @Environment(Purchases.self) private var purchases
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 24)
                        hero
                        Spacer(minLength: 36)

                        VStack(spacing: 12) {
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
                        .multilineTextAlignment(.center)

                        Spacer(minLength: 36)
                        actions
                    }
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                    .padding(.horizontal, 24)
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
            withAnimation(reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.6)) {
                shown = true
            }
        }
    }

    /// A white circle inside a faint ring. It grows out of the center like a filled check dot.
    private var hero: some View {
        ZStack {
            Circle()
                .strokeBorder(Graphite.divider, lineWidth: 1)
                .frame(width: 264, height: 264)
            Circle()
                .fill(Graphite.done)
                .frame(width: 176, height: 176)
        }
        .scaleEffect(shown ? 1 : 0.2)
        .opacity(shown ? 1 : 0)
        .accessibilityHidden(true)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                Task { await purchases.purchase() }
            } label: {
                Group {
                    if let price = purchases.product?.displayPrice {
                        Text("Get Etch Pro · \(price)")
                    } else {
                        Text("Get Etch Pro")
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
                    Text("One-time purchase. Family Sharing included.")
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Graphite.textSecondary)
            .multilineTextAlignment(.center)
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
