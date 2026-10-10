import SwiftUI

/// A round hole pressed into the graphite — the core of Etch. Empty, it means "not done yet";
/// with `isFilled`, it is filled to the brim with plain white.
///
/// A dimple is the one inset thing in the app that can be tapped.
struct Dimple: View {
    let diameter: CGFloat
    var isFilled = false

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let increasedContrast = contrast == .increased
        DimpleArt(diameter: diameter, increasedContrast: increasedContrast)
            .overlay {
                if isFilled {
                    Circle()
                        .fill(Graphite.done)
                        .frame(width: diameter, height: diameter)
                        .transition(.fillDrop)
                }
            }
    }
}

/// The drawing behind `Dimple`, independent of the environment so it can be rendered for the icon.
struct DimpleArt: View {
    let diameter: CGFloat
    let increasedContrast: Bool

    var body: some View {
        let d = diameter
        let dark = Graphite.shadowOffset(d * 0.045)
        let light = Graphite.shadowOffset(-d * 0.03)
        Circle()
            .fill(
                Graphite.dimpleFloor
                    .shadow(.inner(color: Graphite.shadowDark, radius: d * 0.07, x: dark.width, y: dark.height))
                    .shadow(.inner(color: Graphite.rimLight, radius: d * 0.035, x: light.width, y: light.height))
            )
            .overlay {
                if increasedContrast {
                    Circle().strokeBorder(Color(white: 1, opacity: 0.3), lineWidth: 1)
                }
            }
            .frame(width: d, height: d)
    }
}

extension AnyTransition {
    /// The white arrives large — closer to you, still falling — and settles into the dimple.
    /// Pair it with a spring. Without animation (Reduce Motion) it simply appears.
    static var fillDrop: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 1.3).combined(with: .opacity),
            removal: .scale(scale: 0.7).combined(with: .opacity)
        )
    }
}

/// The press feedback for a dimple. Dimples are the one inset thing you can tap, so they don't
/// become raised; the hole just gives a little under your finger.
struct DimpleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .contentShape(.interaction, Circle())
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
