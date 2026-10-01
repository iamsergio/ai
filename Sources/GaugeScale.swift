import CoreGraphics

/// Maps a measured value to gauge progress (0...1) over a fixed range. Out-of-range values clamp.
struct GaugeScale: Equatable {
    let lowerBound: Double
    let upperBound: Double

    /// Temperature in °C. PLAN.md "Defaults chosen".
    static let temperature = GaugeScale(lowerBound: -10, upperBound: 40)
    /// Wind speed in km/h.
    static let wind = GaugeScale(lowerBound: 0, upperBound: 40)

    func progress(for value: Double) -> Double {
        guard value.isFinite, upperBound > lowerBound else { return value == .infinity ? 1 : 0 }
        return min(1, max(0, (value - lowerBound) / (upperBound - lowerBound)))
    }
}

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
}
