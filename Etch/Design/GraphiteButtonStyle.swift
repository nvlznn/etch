import SwiftUI

/// The one button style in Etch: raised at rest, sinks into the slab while pressed.
///
/// Works for capsule buttons and for whole cards (`.graphite(cornerRadius:)`). The label supplies
/// its own padding; the style only supplies the surface and the text color.
struct GraphiteButtonStyle: ButtonStyle {
    /// `nil` draws a capsule.
    var cornerRadius: CGFloat?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Graphite.textPrimary)
            .background { surface(pressed: configuration.isPressed) }
            .contentShape(.interaction, shape)
            .contentShape(.contextMenuPreview, shape)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    @ViewBuilder
    private func surface(pressed: Bool) -> some View {
        let elevation: Elevation = pressed ? .inset : .raised
        if let cornerRadius {
            GraphiteSurface(elevation: elevation, shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            GraphiteSurface(elevation: elevation, shape: Capsule())
        }
    }

    private var shape: AnyShape {
        if let cornerRadius {
            AnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            AnyShape(Capsule())
        }
    }
}

/// For buttons whose label draws its own surface, like a Log card's plate: no background, and the
/// pressed state handed to the label through `\.isGraphitePressed`.
struct PlateButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .environment(\.isGraphitePressed, configuration.isPressed)
            .contentShape(.rect)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension EnvironmentValues {
    /// Whether the enclosing `PlateButtonStyle` button is being held down.
    @Entry var isGraphitePressed = false
}

extension ButtonStyle where Self == PlateButtonStyle {
    static var plate: PlateButtonStyle { PlateButtonStyle() }
}

extension ButtonStyle where Self == GraphiteButtonStyle {
    /// A raised capsule button.
    static var graphite: GraphiteButtonStyle { GraphiteButtonStyle() }

    /// A raised rounded-rectangle button, e.g. a whole card.
    static func graphite(cornerRadius: CGFloat) -> GraphiteButtonStyle {
        GraphiteButtonStyle(cornerRadius: cornerRadius)
    }
}
