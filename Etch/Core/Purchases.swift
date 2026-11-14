import StoreKit
import SwiftUI

/// Whether this Apple Account owns Etch Pro, and the purchase itself.
///
/// Etch Pro is a one-time, family-shareable purchase. The answer comes from StoreKit, not from
/// CloudKit, so it follows the Apple Account to every device. The last answer is kept on this device so
/// the app starts in the right plan even before StoreKit has replied, or offline.
@Observable
final class Purchases {
    static let productID = "dev.noky.etch.pro"
    private static let cacheKey = "isPro"

    private(set) var isPro: Bool
    /// The Etch Pro product, once the App Store has answered. Its `displayPrice` is local to the user.
    private(set) var product: Product?
    /// A purchase or restore is in progress.
    private(set) var isBusy = false
    /// The last purchase or restore failed.
    private(set) var failed = false

    /// Debug builds can pin the plan with `-EtchPlan`, so tests don't depend on the App Store.
    @ObservationIgnored private let isPinned: Bool
    @ObservationIgnored private var updates: Task<Void, Never>?

    init() {
        var pinned: Bool?
        #if DEBUG
        pinned = DebugLaunch.plan.map { $0 == "pro" }
        #endif
        isPinned = pinned != nil
        isPro = pinned ?? UserDefaults.standard.bool(forKey: Self.cacheKey)
        guard pinned == nil else { return }

        // Purchases made elsewhere, refunds and Family Sharing changes arrive here.
        updates = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                await self?.handle(result)
            }
        }
        Task { await refresh() }
    }

    /// Loads the product and checks what the Apple Account owns.
    func refresh() async {
        guard !isPinned else { return }
        if product == nil {
            product = try? await Product.products(for: [Self.productID]).first
        }
        var owns = false
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                owns = true
            }
        }
        setPro(owns)
    }

    func purchase() async {
        guard let product, !isPinned else { return }
        isBusy = true
        failed = false
        defer { isBusy = false }
        do {
            switch try await product.purchase() {
            case .success(let result):
                if case .unverified = result { failed = true } else { await handle(result) }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            failed = true
        }
    }

    /// Asks the App Store for the Apple Account's purchases again, for a new device or a reinstall.
    func restore() async {
        guard !isPinned else { return }
        isBusy = true
        failed = false
        defer { isBusy = false }
        do {
            try await AppStore.sync()
        } catch {
            failed = true
        }
        await refresh()
    }

    private func handle(_ result: VerificationResult<StoreKit.Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        await transaction.finish()
        await refresh()
    }

    private func setPro(_ value: Bool) {
        guard value != isPro else { return }
        isPro = value
        UserDefaults.standard.set(value, forKey: Self.cacheKey)
    }
}
