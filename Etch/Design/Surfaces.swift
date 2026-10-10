import SwiftUI

/// The two shapes a graphite surface can take. (The third state, "filled", is a `Dimple` filled with white.)
enum Elevation {
    /// Stands proud of the slab. Means "you can press this".
    case raised
    /// Pressed into the slab. Containers, inputs, and buttons while they're held down.
    case inset
}

/// A graphite surface in either elevation. Changing `elevation` cross-fades between the two,
/// which is how a pressed button sinks into the slab.
struct GraphiteSurface<S: InsettableShape>: View {
    var elevation: Elevation
    var shape: S

    var body: some View {
        ZStack {
            switch elevation {
            case .raised: raised.transition(.opacity)
            case .inset: inset.transition(.opacity)
            }
        }
    }

    private var raised: some View {
        shape
            .fill(LinearGradient(
                colors: [Graphite.raisedTop, Graphite.raisedBottom],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            // Rim light along the top-left edge, fading out before the shadowed side. On a black
            // block this edge is what separates it from the slab.
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [Graphite.rimLight, Graphite.highlight.opacity(0.4), .clear],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            }
            .shadow(color: Graphite.highlight, radius: 8, x: -Graphite.shadowOffset(4).width, y: -Graphite.shadowOffset(4).height)
            .shadow(color: Graphite.shadowDark, radius: 10, x: Graphite.shadowOffset(6).width, y: Graphite.shadowOffset(6).height)
    }

    private var inset: some View {
        let dark = Graphite.shadowOffset(3)
        let light = Graphite.shadowOffset(-1.5)
        return shape
            .fill(
                Graphite.well
                    // The top-left wall is in shadow…
                    .shadow(.inner(color: Graphite.shadowDark, radius: 5, x: dark.width, y: dark.height))
                    // …and the bottom-right wall faces the light.
                    .shadow(.inner(color: Graphite.highlight, radius: 3, x: light.width, y: light.height))
            )
    }
}

/// The dark gray board a `DotGrid` sits on in the Log: a thick slab with a bevelled, lit top edge.
/// Lighter than the black blocks so black "not done" dots stay visible on it.
/// `pressed` sinks it a little, for when the whole card is a button.
struct GraphitePlate: View {
    var pressed = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Graphite.Radius.plate, style: .continuous)
        let shadow = Graphite.shadowOffset(pressed ? 2 : 7)
        shape
            .fill(LinearGradient(
                colors: [Graphite.plateTop, Graphite.plateBottom],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            // The bevel: a bright lip along the top-left edge, a darker one along the bottom-right.
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [Graphite.plateLip, Graphite.highlight.opacity(0.6), Graphite.plateUnderside],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
            }
            .shadow(color: Graphite.shadowDark, radius: pressed ? 3 : 12, x: shadow.width, y: shadow.height)
            .brightness(pressed ? -0.04 : 0)
    }
}

extension View {
    /// Sets a raised graphite surface behind this view. Use only for things that can be pressed.
    func graphiteRaised(cornerRadius: CGFloat = Graphite.Radius.card) -> some View {
        background {
            GraphiteSurface(elevation: .raised, shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }

    /// Sets an inset graphite surface behind this view: containers, inputs, empty wells.
    func graphiteInset(cornerRadius: CGFloat = Graphite.Radius.card) -> some View {
        background {
            GraphiteSurface(elevation: .inset, shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}
