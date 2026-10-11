import SwiftUI

/// Days as a grid of flat dots, one column per week and one row per weekday, laid out like a
/// physical dot-grid board: white for done, black for not done. Every past day is drawn, even from
/// before the habit existed; future days are left empty.
///
/// Everything is drawn into a single `Canvas`, which stays cheap in a scrolling list.
struct DotGrid: View {
    let grid: WeekGrid
    let done: Set<Day>
    let today: Day
    /// Fixed cell size in points. `nil` fits the available width.
    var cellSize: CGFloat?
    /// Makes visible days tappable, and reachable with VoiceOver. Requires `cellSize`.
    var onTap: ((Day) -> Void)?

    /// Dot diameter as a fraction of its cell.
    static let dotRatio: CGFloat = 0.82

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let increasedContrast = contrast == .increased
        let canvas = Canvas { context, size in
            draw(in: &context, size: size, increasedContrast: increasedContrast)
        }

        if let cellSize, let onTap {
            canvas
                .frame(width: cellSize * CGFloat(grid.weeks), height: cellSize * 7)
                .contentShape(.rect)
                .onTapGesture(coordinateSpace: .local) { location in
                    let column = Int(location.x / cellSize)
                    let row = Int(location.y / cellSize)
                    guard (0..<grid.weeks).contains(column), (0..<7).contains(row) else { return }
                    let day = grid.day(column: column, row: row)
                    if isVisible(day) { onTap(day) }
                }
                .accessibilityElement(children: .contain)
                .accessibilityChildren { accessibleDays(cellSize: cellSize, onTap: onTap) }
        } else if let cellSize {
            canvas
                .frame(width: cellSize * CGFloat(grid.weeks), height: cellSize * 7)
                .accessibilityHidden(true)
        } else {
            canvas
                .aspectRatio(CGFloat(grid.weeks) / 7, contentMode: .fit)
                .accessibilityHidden(true)
        }
    }

    private func isVisible(_ day: Day) -> Bool {
        day <= today
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, increasedContrast: Bool) {
        let cell = size.width / CGFloat(grid.weeks)
        let dot = cell * Self.dotRatio
        var done = Path()
        var open = Path()

        for column in 0..<grid.weeks {
            for row in 0..<7 {
                let day = grid.day(column: column, row: row)
                guard isVisible(day) else { continue }
                let center = CGPoint(x: (CGFloat(column) + 0.5) * cell, y: (CGFloat(row) + 0.5) * cell)
                let frame = CGRect(x: center.x - dot / 2, y: center.y - dot / 2, width: dot, height: dot)
                if self.done.contains(day) {
                    done.addEllipse(in: frame)
                } else {
                    open.addEllipse(in: frame)
                }
            }
        }

        context.fill(open, with: .color(Graphite.notDone))
        context.fill(done, with: .color(Graphite.done))
        if increasedContrast {
            context.stroke(open, with: .color(Graphite.textSecondary), lineWidth: 1)
        }
    }

    /// One invisible element per drawn day, laid over the canvas in the same positions, so
    /// VoiceOver can read and toggle each day. Ordered week by week, i.e. chronologically.
    private func accessibleDays(cellSize: CGFloat, onTap: @escaping (Day) -> Void) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<grid.weeks, id: \.self) { column in
                VStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { row in
                        let day = grid.day(column: column, row: row)
                        if isVisible(day) {
                            Color.clear
                                .frame(width: cellSize, height: cellSize)
                                .accessibilityElement()
                                .accessibilityLabel(Text(day.date(), format: .dateTime.weekday(.wide).month(.wide).day().year()))
                                .accessibilityValue(done.contains(day) ? Text("Completed") : Text("Not completed"))
                                .accessibilityAddTraits(.isButton)
                                .accessibilityAction { onTap(day) }
                        } else {
                            Color.clear.frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }
}
