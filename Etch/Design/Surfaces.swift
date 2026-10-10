import SwiftUI

/// A card: the one container in Etch. A flat dark fill with a faint sheen on its edge.
///
/// With Increase Contrast on, the edge becomes a clearly visible line.
struct GraphiteCard<S: InsettableShape>: View {
    var shape: S
    /// Lightens the card while a button made of it is held down.
    var isPressed = false

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let increased = contrast == .increased
        shape
            .fill(Graphite.card)
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        colors: increased
                            ? [Graphite.textSecondary, Graphite.textSecondary]
                            : [Graphite.edgeTop, Graphite.edgeBottom],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            }
            .brightness(isPressed ? 0.04 : 0)
    }
}

extension View {
    /// Sets a card behind this view.
    func graphiteCard(cornerRadius: CGFloat = Graphite.Radius.card) -> some View {
        background {
            GraphiteCard(shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}
