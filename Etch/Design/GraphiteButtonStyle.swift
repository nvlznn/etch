import SwiftUI

/// The button styles in Etch. Each label supplies its own padding; the style supplies the surface.
struct GraphiteButtonStyle: ButtonStyle {
    enum Kind {
        /// White capsule, black text: the one main action on a screen.
        case primary
        /// Card-colored capsule, white text.
        case secondary
        /// A whole card that can be tapped, e.g. a habit in the Log.
        case card(cornerRadius: CGFloat)
    }

    var kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return Group {
            switch kind {
            case .primary:
                configuration.label
                    .foregroundStyle(Graphite.background)
                    .background(Capsule().fill(Graphite.done))
                    .opacity(pressed ? 0.8 : 1)
                    .contentShape(Capsule())
            case .secondary:
                configuration.label
                    .foregroundStyle(Graphite.textPrimary)
                    .background { GraphiteCard(shape: Capsule(), isPressed: pressed) }
                    .contentShape(Capsule())
            case .card(let cornerRadius):
                let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                configuration.label
                    .foregroundStyle(Graphite.textPrimary)
                    .background { GraphiteCard(shape: shape, isPressed: pressed) }
                    .contentShape(.interaction, shape)
                    .contentShape(.contextMenuPreview, shape)
            }
        }
        .scaleEffect(pressed ? 0.98 : 1)
        .animation(.easeOut(duration: 0.12), value: pressed)
    }
}

/// For buttons whose label draws its own card, e.g. a Log entry with its name above the card.
/// Adds no background; hands the pressed state to the label through `\.isGraphitePressed`.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .environment(\.isGraphitePressed, configuration.isPressed)
            .contentShape(.rect)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension EnvironmentValues {
    /// Whether the enclosing `PressableButtonStyle` button is held down.
    @Entry var isGraphitePressed = false
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}

extension ButtonStyle where Self == GraphiteButtonStyle {
    static var primary: GraphiteButtonStyle { GraphiteButtonStyle(kind: .primary) }
    static var secondary: GraphiteButtonStyle { GraphiteButtonStyle(kind: .secondary) }
    static var card: GraphiteButtonStyle { GraphiteButtonStyle(kind: .card(cornerRadius: Graphite.Radius.card)) }
}
