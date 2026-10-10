import SwiftUI
import UIKit

// MARK: - Light
//
// Etch has exactly one light, above and to the left of the screen. Everything follows from it:
//
//   • Raised surfaces catch the light on their top-left edge and cast a shadow down and to the right.
//   • Inset surfaces are holes: their top-left inner wall falls into shadow, and the bottom-right
//     inner wall — which faces the light — is lit.
//
// `Graphite.awayFromLight` is the only place that direction is written down. Every shadow in
// Design/ multiplies it, so no component can quietly disagree.
//
// MARK: - Palette
//
// Every color is a pure gray built with `Color(white:)`; there is no hue anywhere in the app.
// Values are sRGB gray levels (0 = black, 1 = white). Contrast ratios are WCAG.
//
// base           0.155   The graphite slab behind everything. Not black, so black raised blocks
//                        and their shadows can still be seen against it.
// raisedTop      0.075   Raised blocks are black: a near-black slab with the faintest slope toward
// raisedBottom   0.035   the light, separated from the background by its rim light and shadow.
// well           0.118   The floor of anything inset into the slab. Darker than base because less
//                        light reaches it.
// dimpleFloor    0.0     The floor of a dimple. Dimples are cut into black tiles, so the floor has
//                        to be darker still: pure black, read by its lit lower-right wall.
// highlight      white @ 9%   Glow on the lit side of raised things. Translucent so it works on any gray.
// rimLight       white @ 16%  An edge that faces the light head-on: the top-left rim of a raised block,
//                        the lower-right inner wall of a dimple.
// shadowDark     black @ 62%  Cast shadows and inner shadows.
//
// plateTop       0.27    The Log plate (modelled on a physical dot-grid board): a dark gray slab,
// plateBottom    0.20    lighter than the black blocks so black "not done" dots stay visible on it.
// plateLip       white @ 30%  The plate's bevelled top-left edge, and
// plateUnderside black @ 35%  its bottom-right edge.
// done           0.97    Done is plain near-white everywhere: a dot on the plate, or a dimple filled
// notDone        0.02    to the brim. Not done is black. The two differ by brightness alone, ≈ 18:1.
//
// textPrimary    0.94    ≈ 13:1 on base, ≈ 17:1 on a black block. Names, numbers, titles.
// textSecondary  0.68    ≈ 7.5:1 on base. Labels and captions; never dimmer.
//
// Text color never depends on the surface under it. Shape says "can I press this"; contrast is the
// job of the text colors alone.

enum Graphite {
    static let base = Color(white: 0.155)
    static let raisedTop = Color(white: 0.075)
    static let raisedBottom = Color(white: 0.035)
    static let well = Color(white: 0.118)
    static let dimpleFloor = Color(white: 0.0)
    static let highlight = Color(white: 1, opacity: 0.09)
    static let rimLight = Color(white: 1, opacity: 0.16)
    static let shadowDark = Color(white: 0, opacity: 0.62)
    static let plateTop = Color(white: 0.27)
    static let plateBottom = Color(white: 0.20)
    static let plateLip = Color(white: 1, opacity: 0.30)
    static let plateUnderside = Color(white: 0, opacity: 0.35)
    static let done = Color(white: 0.97)
    static let notDone = Color(white: 0.02)
    static let textPrimary = Color(white: 0.94)
    static let textSecondary = Color(white: 0.68)

    /// Unit offset pointing away from the light (down and to the right). Multiply by a distance.
    static let awayFromLight = CGSize(width: 1, height: 1)

    /// A shadow offset of `distance` points, away from the light.
    static func shadowOffset(_ distance: CGFloat) -> CGSize {
        CGSize(width: awayFromLight.width * distance, height: awayFromLight.height * distance)
    }

    /// Corner radii, so every card in the app has the same curvature.
    enum Radius {
        static let card: CGFloat = 20
        static let field: CGFloat = 16
        static let stat: CGFloat = 18
        static let plate: CGFloat = 18
    }
}

// MARK: - Background

/// The graphite slab everything sits on. Use behind every screen.
struct GraphiteBackground: View {
    var body: some View {
        Graphite.base
            .overlay { GraphiteGrain() }
            .ignoresSafeArea()
    }
}

// MARK: - Grain

/// A barely-there noise texture on the background slab, so it reads as a material instead of a fill.
/// Only the background has it; blocks on top are smooth.
/// It is a single 128-pixel tile drawn once and repeated, which costs next to nothing.
struct GraphiteGrain: View {
    var body: some View {
        Image(uiImage: Self.tile)
            .resizable(resizingMode: .tile)
            .blendMode(.overlay)
            .opacity(0.12)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private static let tile: UIImage = {
        let side = 128
        var generator = SplitMix64(seed: 0x4574_6368) // "Etch": the same grain on every launch.
        let pixels = (0..<side * side).map { _ in UInt8(truncatingIfNeeded: generator.next() >> 56) }
        let image = CGImage(
            width: side, height: side,
            bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: side,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: CGDataProvider(data: Data(pixels) as CFData)!,
            decode: nil, shouldInterpolate: false, intent: .defaultIntent
        )!
        // One grain per physical pixel on a 3x screen.
        return UIImage(cgImage: image, scale: 3, orientation: .up)
    }()
}

private struct SplitMix64 {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
