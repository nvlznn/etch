import SwiftUI

/// The circle you tap on the Check-In page: black until the habit is done today, then white.
struct CheckDot: View {
    let diameter: CGFloat
    var isDone = false

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        ZStack {
            Circle()
                .fill(Graphite.notDone)
                .overlay {
                    if contrast == .increased {
                        Circle().strokeBorder(Graphite.textSecondary, lineWidth: 1)
                    }
                }
            if isDone {
                Circle()
                    .fill(Graphite.done)
                    .transition(.fillIn)
            }
        }
        .frame(width: diameter, height: diameter)
    }
}

extension AnyTransition {
    /// White grows out from the center until it fills the circle. Pair it with a spring.
    /// Without animation (Reduce Motion) it simply appears.
    static var fillIn: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.2).combined(with: .opacity),
            removal: .scale(scale: 0.6).combined(with: .opacity)
        )
    }
}

/// Press feedback for a `CheckDot`: it gives a little under your finger.
struct CheckDotButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .contentShape(.interaction, Circle())
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
