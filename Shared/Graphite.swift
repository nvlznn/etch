import SwiftUI

// MARK: - Look
//
// Etch is flat. Cards float on a pure black background, a shade lighter than it, and each card has
// a faint sheen on its edge only: a hairline border that is brightest along the top and fades toward
// the bottom, as if light were grazing the rim. Nothing is bevelled, pressed in or raised up, and
// nothing casts a shadow.
//
// MARK: - Palette
//
// Every color is a pure gray built with `Color(white:)`; there is no hue anywhere in the app.
// Values are sRGB gray levels (0 = black, 1 = white). Contrast ratios are WCAG.
//
// background     0.0     Pure black. On OLED the screen disappears around the cards.
// card           0.10    A card's flat fill (#1A1A1A): just lifted off the black.
// edgeTop        white @ 14%  The sheen: a hairline around each card, brightest at the top
// edgeBottom     white @ 4%   and fading toward the bottom.
// notDone        0.0     Not done is pure black everywhere: a hole in the card, the same black
//                        as the background.
// done           0.97    Done is plain near-white everywhere, ≈ 20:1 against `notDone`, so done and
//                        not done differ by brightness alone.
// divider        white @ 10%  Hairlines between items inside a card.
// textPrimary    0.95    ≈ 15:1 on a card.
// textSecondary  0.65    ≈ 7:1 on a card. Labels and captions; never dimmer.
// textDisabled   0.38    A control that can't be used right now, e.g. "next day" on today.
// swipeAction    0.30    Behind a swipe action's white icon, e.g. checking in from the Log.

enum Graphite {
    static let background = Color(white: 0)
    static let card = Color(white: 26 / 255)
    static let edgeTop = Color(white: 1, opacity: 0.14)
    static let edgeBottom = Color(white: 1, opacity: 0.04)
    static let notDone = Color(white: 0)
    static let done = Color(white: 0.97)
    static let divider = Color(white: 1, opacity: 0.10)
    static let textPrimary = Color(white: 0.95)
    static let textSecondary = Color(white: 0.65)
    static let textDisabled = Color(white: 0.38)
    static let swipeAction = Color(white: 0.30)

    /// Corner radii, so every card in the app has the same curvature.
    enum Radius {
        static let card: CGFloat = 22
        static let field: CGFloat = 16
    }
}

// MARK: - Background

/// The black behind every screen.
struct GraphiteBackground: View {
    var body: some View {
        Graphite.background.ignoresSafeArea()
    }
}
