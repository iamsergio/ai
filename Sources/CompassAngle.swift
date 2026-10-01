import Foundation

/// Angle maths for the wind compass. Degrees, 0° = north, clockwise.
enum CompassAngle {
    /// Normalizes any angle to 0..<360. Non-finite input gives 0.
    static func normalized(_ degrees: Double) -> Double {
        guard degrees.isFinite else { return 0 }
        let r = degrees.truncatingRemainder(dividingBy: 360)
        let n = r < 0 ? r + 360 : r
        return n >= 360 ? 0 : n   // -1e-20 + 360 rounds to 360
    }

    /// The angle equivalent to `target` (mod 360) that lies within ±180° of `current`, so that
    /// animating `current` → result takes the shortest path (350° → 10° gives 370°, not 10°).
    /// `current` is the unbounded rotation already shown, which may be outside 0..<360.
    static func unwrapped(from current: Double, to target: Double) -> Double {
        guard current.isFinite else { return normalized(target) }
        guard target.isFinite else { return current }
        let delta = normalized(target - current)
        return current + (delta > 180 ? delta - 360 : delta)
    }
}
