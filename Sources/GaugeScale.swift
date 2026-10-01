import Foundation

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
