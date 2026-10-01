import CoreGraphics

/// Where a gauge arc sits on the dial. Angles are screen degrees: 0° = right, increasing clockwise.
/// `sweep` is signed: positive runs clockwise from `start`, negative counter-clockwise.
struct ArcSpec: Equatable {
    let start: Double
    let sweep: Double

    var end: Double { start + sweep }

    /// Arc radius as a fraction of the dial radius R (PLAN.md "Geometry reference").
    static let radiusFraction: CGFloat = 0.54
    /// Stroke width as a fraction of the dial diameter D.
    static let lineWidthFraction: CGFloat = 0.016

    /// Temperature: 136° → 256°, filling from the bottom up the left side.
    static let left = ArcSpec(start: 136, sweep: 120)
    /// Wind: mirror image, 44° → −76°, filling from the bottom up the right side.
    static let right = ArcSpec(start: 44, sweep: -120)

    /// Angle reached at `progress` (clamped to 0...1).
    func angle(at progress: Double) -> Double {
        start + sweep * min(1, max(0, progress))
    }

    /// Angular range for the gradient fixed to the full arc. `AngularGradient` runs clockwise, so a
    /// counter-clockwise arc covers `end ... start`.
    var gradientRange: ClosedRange<Double> { min(start, end)...max(start, end) }
    /// True when the colour list (listed start → end) must be reversed to fit `gradientRange`.
    var reversesColors: Bool { sweep < 0 }
}
