import CoreGraphics

/// Pager proportions as fractions of the dial diameter `D`.
enum PagerLayout {
    /// Diameter of the circular pager area (about the inner arc region).
    static let diameter: CGFloat = 0.56
    /// Pager centre below the dial centre.
    static let centreOffset: CGFloat = 0.02
    /// Distance between day-card centres (146 px of 840 px on forecast-page.png).
    static let cardSpacing: CGFloat = 0.174
    /// Radius fraction where the vignette starts to fade.
    static let vignetteStart: CGFloat = 0.8
}
