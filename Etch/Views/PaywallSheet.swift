import StoreKit
import SwiftUI

/// What the user was doing when the paywall came up.
enum PaywallReason: Identifiable {
    case addHabit
    case unarchive
    case settings

    var id: Self { self }

    var message: LocalizedStringKey {
        switch self {
        case .addHabit: "Etch Free keeps up to 3 habits. Archive or delete one to add another, or get Etch Pro for no limit."
        case .unarchive: "Bringing an archived habit back is part of Etch Pro."
        case .settings: "Etch Free keeps up to 3 habits and can't bring archived habits back."
        }
    }
}

/// Offers Etch Pro. Never blocks anything the user already has: it only opens when they try to add
/// a habit past the free limit or unarchive one.
struct PaywallSheet: View {
    let reason: PaywallReason

    @Environment(Purchases.self) private var purchases
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Etch Pro")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Graphite.textPrimary)
                        Text(reason.message)
                            .font(.body)
                            .foregroundStyle(Graphite.textSecondary)
                    }

                    VStack(spacing: 0) {
                        benefit("Unlimited habits")
                        Rectangle().fill(Graphite.divider).frame(height: 1)
                        benefit("Bring archived habits back")
                    }
                    .graphiteCard()

                    Text("One purchase, yours for good, shared with your family.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Graphite.textSecondary)

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

                        Button {
                            Task { await purchases.restore() }
                        } label: {
                            Text("Restore Purchases")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.secondary)
                        .disabled(purchases.isBusy)

                        if purchases.failed {
                            Text("Something went wrong. Try again.")
                                .font(.footnote)
                                .foregroundStyle(Graphite.textSecondary)
                        }
                    }
                }
                .padding(20)
            }
            .background { GraphiteBackground() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground { GraphiteBackground() }
        .onChange(of: purchases.isPro) { _, isPro in
            if isPro { dismiss() }
        }
    }

    private func benefit(_ title: LocalizedStringKey) -> some View {
        HStack(spacing: 12) {
            CheckDot(diameter: 16, isDone: true)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Graphite.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(14)
    }
}

#if DEBUG
#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            PaywallSheet(reason: .addHabit)
        }
        .environment(Purchases())
        .preferredColorScheme(.dark)
        .tint(.white)
}
#endif
