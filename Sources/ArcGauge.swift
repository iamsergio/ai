import SwiftUI

/// Arc shape that draws the first `progress` (0...1) of `spec`, centred in its rect with radius `radius`.
/// `progress` is animatable, so value changes interpolate.
struct ArcGauge: Shape {
    var spec: ArcSpec
    var radius: CGFloat
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard progress > 0 else { return path }
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        // SwiftUI's y axis points down, so `clockwise: true` draws counter-clockwise on screen.
        path.addArc(center: centre, radius: radius,
                    startAngle: .degrees(spec.start), endAngle: .degrees(spec.angle(at: progress)),
                    clockwise: spec.sweep < 0)
        return path
    }
}
